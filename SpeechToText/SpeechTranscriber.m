//
//  SpeechTranscriber.m
//  SpeechToTextDemo
//
//  Created by admin on 4/18/14.
//  Copyright (c) 2014 Muhammad Zeeshan. All rights reserved.
//

#import "SpeechTranscriber.h"

// Controllers
#import "SineWaveViewController.h"

static const NSInteger FRAME_SIZE = 110;

@interface SpeechTranscriber () <SineWaveViewDelegate>
@property (nonatomic, strong) NSTimer *meterTimer;
@property (nonatomic, assign) NSInteger samplesBelowSilence;
@property (nonatomic, assign) BOOL detectedSpeech;
@property (nonatomic, assign) BOOL processing;

@property (nonatomic, strong) NSMutableArray *volumeDataPoints;
@property (nonatomic, strong) SineWaveViewController *sineWave;
@property (nonatomic, strong) NSThread *processingThread;

@end

@implementation SpeechTranscriber

#pragma mark - Accessors
- (BOOL)recording {
    return self.aqData->mIsRunning;
}

#pragma mark - Lifecycle
-(instancetype)init {
    
    if ( !(self = [super init]) ) {
        return nil;
    }
    self.aqData = [AQRecorderState new];
    self.aqData->mDataFormat.mFormatID = kAudioFormatLinearPCM;
    self.aqData->mDataFormat.mSampleRate = 16000.0;
    self.aqData->mDataFormat.mChannelsPerFrame = 1;
    self.aqData->mDataFormat.mBitsPerChannel = 16;
    self.aqData->mDataFormat.mBytesPerPacket =
    self.aqData->mDataFormat.mBytesPerFrame =
    self.aqData->mDataFormat.mChannelsPerFrame * sizeof (SInt16);
    self.aqData->mDataFormat.mFramesPerPacket  = 1;
    self.aqData->mDataFormat.mFormatFlags =
    kLinearPCMFormatFlagIsSignedInteger
    | kLinearPCMFormatFlagIsPacked;
    
    memset(&(self.aqData->speex_bits), 0, sizeof(SpeexBits));
    speex_bits_init(&(self.aqData->speex_bits));
    self.aqData->speex_enc_state = speex_encoder_init(&speex_wb_mode);
    
    int quality = 8;
    speex_encoder_ctl(self.aqData->speex_enc_state, SPEEX_SET_QUALITY, &quality);
    int vbr = 1;
    speex_encoder_ctl(self.aqData->speex_enc_state, SPEEX_SET_VBR, &vbr);
    speex_encoder_ctl(self.aqData->speex_enc_state, SPEEX_GET_FRAME_SIZE, &(self.aqData->speex_samples_per_frame));
    self.aqData->mQueue = NULL;
    
    self.sineWave = [[SineWaveViewController alloc] initWithNibName:@"SineWaveViewController" bundle:nil];
    self.sineWave.delegate = self;
    
    [self reset];
    
    return self;
}

- (void)dealloc {
    [self.processingThread cancel];
    if (self.processing) {
        [self cleanUpProcessingThread];
    }
    
    self.delegate = nil;
    self.sineWave.delegate = nil;

    speex_bits_destroy(&(self.aqData->speex_bits));
    speex_encoder_destroy(self.aqData->speex_enc_state);

    AudioQueueDispose(self.aqData->mQueue, true);
}

#pragma mark -
-(void)reset {
    if (self.aqData->mQueue != NULL)
        AudioQueueDispose(self.aqData->mQueue, true);
    
    AudioSessionInitialize(NULL, NULL, nil, (__bridge void *)(self));
    UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    AudioSessionSetActive(true);
    
    UInt32 enableLevelMetering = 1;
    AudioQueueNewInput(&(self.aqData->mDataFormat), HandleInputBuffer, (__bridge void *)(self.aqData), NULL, kCFRunLoopCommonModes, 0, &(self.aqData->mQueue));
    AudioQueueSetProperty(self.aqData->mQueue, kAudioQueueProperty_EnableLevelMetering, &enableLevelMetering, sizeof(UInt32));
    DeriveBufferSize(self.aqData->mQueue, &(self.aqData->mDataFormat), 0.5, &(self.aqData->bufferByteSize));
    
    for (int i = 0; i < kNumberBuffers; i++) {
        AudioQueueAllocateBuffer(self.aqData->mQueue, self.aqData->bufferByteSize, &(self.aqData->mBuffers[i]));
        AudioQueueEnqueueBuffer(self.aqData->mQueue, self.aqData->mBuffers[i], 0, NULL);
    }
    
    self.aqData->encodedSpeexData = [[NSMutableData alloc] init];
    
    [self.meterTimer invalidate];
    self.samplesBelowSilence = 0;
    self.detectedSpeech = NO;
    
    self.volumeDataPoints = [[NSMutableArray alloc] initWithCapacity:kNumVolumeSamples];
    
    for (int i = 0; i < kNumVolumeSamples; i++) {
        [self.volumeDataPoints addObject:[NSNumber numberWithFloat:kMinVolumeSampleValue]];
    }
    self.sineWave.dataPoints = self.volumeDataPoints;
}

- (void)beginRecording {
    @synchronized(self) {
        if (!self.recording && !self.processing) {
            self.aqData->mCurrentPacket = 0;
            self.aqData->mIsRunning = true;
            [self reset];
            AudioQueueStart(self.aqData->mQueue, NULL);
            
            
            if (self.sineWave && [self.delegate respondsToSelector:@selector(showSineWaveView:)]) {
                [self.delegate showSineWaveView:self.sineWave];
            } /*else {
                status = [[UIAlertView alloc] initWithTitle:@"Speak now!" message:@"" delegate:self cancelButtonTitle:@"Done" otherButtonTitles:nil];
                [status show];
            }*/
            self.meterTimer = [NSTimer scheduledTimerWithTimeInterval:kVolumeSamplingInterval
                                                                target:self
                                                              selector:@selector(checkMeter) userInfo:nil repeats:YES];
        }
    }
}

- (void)sineWaveDoneAction {
    if (self.recording)
        [self stopRecording:YES];
    else if ([self.delegate respondsToSelector:@selector(dismissSineWaveView:cancelled:)]) {
        [self.delegate dismissSineWaveView:self.sineWave cancelled:NO];
    }
}

- (void)cleanUpProcessingThread {
    @synchronized(self) {
        self.processingThread = nil;
        self.processing = NO;
    }
}

- (void)sineWaveCancelAction {
    if (self.recording) {
        [self stopRecording:NO];
    } else {
        if (self.processing) {
            [self.processingThread cancel];
            self.processing = NO;
        }
        if ([self.delegate respondsToSelector:@selector(dismissSineWaveView:cancelled:)]) {
            [self.delegate dismissSineWaveView:self.sineWave cancelled:YES];
        }
    }
}

- (void)stopRecording:(BOOL)startProcessing {
    
    @synchronized(self) {
        
        if (self.recording) {
            //[status dismissWithClickedButtonIndex:-1 animated:YES];
            //status = nil;
            
            if ([self.delegate respondsToSelector:@selector(dismissSineWaveView:cancelled:)])
                [self.delegate dismissSineWaveView:self.sineWave cancelled:!startProcessing];
            
            AudioQueueStop(self.aqData->mQueue, true);
            self.aqData->mIsRunning = false;
            [self.meterTimer invalidate];;
            self.meterTimer = nil;
            
            if (startProcessing) {
                [self cleanUpProcessingThread];
                self.processing = YES;
                self.processingThread = [[NSThread alloc] initWithTarget:self selector:@selector(postByteData:) object:self.aqData->encodedSpeexData];
                [self.processingThread start];
                
                if ([self.delegate respondsToSelector:@selector(showLoadingView)])
                    [self.delegate showLoadingView];
            }
        }
    }
}

- (void)checkMeter {
    AudioQueueLevelMeterState meterState;
    AudioQueueLevelMeterState meterStateDB;
    UInt32 ioDataSize = sizeof(AudioQueueLevelMeterState);
    AudioQueueGetProperty(self.aqData->mQueue, kAudioQueueProperty_CurrentLevelMeter, &meterState, &ioDataSize);
    AudioQueueGetProperty(self.aqData->mQueue, kAudioQueueProperty_CurrentLevelMeterDB, &meterStateDB, &ioDataSize);
    
    [self.volumeDataPoints removeObjectAtIndex:0];
    float dataPoint;
    
    if (meterStateDB.mAveragePower > kSilenceThresholdDB) {
        self.detectedSpeech = YES;
        dataPoint = MIN(kMaxVolumeSampleValue, meterState.mPeakPower);
    } else {
        dataPoint = MAX(kMinVolumeSampleValue, meterState.mPeakPower);
    }
    [self.volumeDataPoints addObject:[NSNumber numberWithFloat:dataPoint]];
    
    [self.sineWave updateWaveDisplay];
    
    if (self.detectedSpeech) {
        
        if (meterStateDB.mAveragePower < kSilenceThresholdDB) {
            self.samplesBelowSilence++;
            
            if (self.samplesBelowSilence > kSilenceThresholdNumSamples)
                [self stopRecording:YES];
        } else {
            self.samplesBelowSilence = 0;
        }
    }
}

- (void)postByteData:(NSData *)byteData {
#warning TODO: update networking to use NSURLSession
    NSURL *url = [NSURL URLWithString:@"https://www.google.com/speech-api/v1/recognize?xjerr=1&client=chromium&lang=en-US"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:byteData];
    [request addValue:@"audio/x-speex-with-header-byte; rate=16000" forHTTPHeaderField:@"Content-Type"];
    [request setURL:url];
    [request setTimeoutInterval:15];
    NSURLResponse *response;
    NSError *error = nil;
    
    if ([self.processingThread isCancelled]) {
        [self cleanUpProcessingThread];
        return;
    }
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if(error)
        [self requestFailed:error];
    
    if ([self.processingThread isCancelled]) {
        [self cleanUpProcessingThread];
        return;
    }
    
    [self performSelectorOnMainThread:@selector(gotResponse:) withObject:data waitUntilDone:NO];
}

- (void)gotResponse:(NSData *)jsonData {
    [self cleanUpProcessingThread];
    [self.delegate didReceiveVoiceResponse:jsonData];
}

- (void)requestFailed:(NSError *)error
{
    if([self.delegate respondsToSelector:@selector(requestFailedWithError:)])
        [self.delegate requestFailedWithError:error];
}


#pragma mark - C Helpers
static void HandleInputBuffer (void *aqData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer,
                               const AudioTimeStamp *inStartTime, UInt32 inNumPackets,
                               const AudioStreamPacketDescription *inPacketDesc) {
    
    AQRecorderState *pAqData = (__bridge AQRecorderState *) aqData;
    
    if (inNumPackets == 0 && pAqData->mDataFormat.mBytesPerPacket != 0)
        inNumPackets = inBuffer->mAudioDataByteSize / pAqData->mDataFormat.mBytesPerPacket;
    
    // process speex
    int packets_per_frame = pAqData->speex_samples_per_frame;
    
    char cbits[FRAME_SIZE + 1];
    for (int i = 0; i < inNumPackets; i+= packets_per_frame) {
        speex_bits_reset(&(pAqData->speex_bits));
        
        speex_encode_int(pAqData->speex_enc_state, ((spx_int16_t*)inBuffer->mAudioData) + i, &(pAqData->speex_bits));
        int nbBytes = speex_bits_write(&(pAqData->speex_bits), cbits + 1, FRAME_SIZE);
        cbits[0] = nbBytes;
        
        [pAqData->encodedSpeexData appendBytes:cbits length:nbBytes + 1];
    }
    pAqData->mCurrentPacket += inNumPackets;
    
    if (!pAqData->mIsRunning)
        return;
    
    AudioQueueEnqueueBuffer(pAqData->mQueue, inBuffer, 0, NULL);
}

static void DeriveBufferSize (AudioQueueRef audioQueue, AudioStreamBasicDescription *ASBDescription, Float64 seconds, UInt32 *outBufferSize) {
    static const int maxBufferSize = 0x50000;
    
    int maxPacketSize = ASBDescription->mBytesPerPacket;
    if (maxPacketSize == 0) {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty (audioQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize, &maxVBRPacketSize);
    }
    
    Float64 numBytesForTime = ASBDescription->mSampleRate * maxPacketSize * seconds;
    *outBufferSize = (UInt32)(numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize);
}


@end
