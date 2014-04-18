//
//  VoiceAddModule.h
//  AstridiPhone
//
//  Created by Sam Bosley on 10/7/11.
//  Copyright (c) 2011 Todoroo. All rights reserved.
//
//  Modified by James Smith
//

// Frameworks
@import Foundation;
@import UIKit;
@import AudioToolbox;
#import <speex/speex.h>

// View Controllers
#import "SineWaveViewController.h"

static const NSInteger kNumberBuffers = 3;
static const NSInteger kNumVolumeSamples = 10;
static const CGFloat kSilenceThresholdDB = - 30.0;

static const CGFloat kVolumeSamplingInterval = 0.05;
static const CGFloat kSilenceTimeThreshold = 0.9;
static const CGFloat kSilenceThresholdNumSamples = (kSilenceTimeThreshold / kVolumeSamplingInterval);

static const CGFloat kMinVolumeSampleValue = 0.01;
static const CGFloat kMaxVolumeSampleValue = 1.0;

typedef struct AQRecorderState {
    AudioStreamBasicDescription  mDataFormat;
    AudioQueueRef                mQueue;                        
    AudioQueueBufferRef          mBuffers[kNumberBuffers];                    
    UInt32                       bufferByteSize;                
    SInt64                       mCurrentPacket;                
    bool                         mIsRunning;
    
    SpeexBits                    speex_bits; 
    void *                       speex_enc_state;
    int                          speex_samples_per_frame;
    __unsafe_unretained NSMutableData *              encodedSpeexData;
    
    __unsafe_unretained id selfRef;
} AQRecorderState;

@protocol SpeechToTextModuleDelegate <NSObject>

// Delegate will need to parse JSON and dismiss loading view if presented
// returns true on success, false on failure
- (BOOL)didReceiveVoiceResponse:(NSData *)data;

@optional
- (void)showSineWaveView:(SineWaveViewController *)view;
- (void)dismissSineWaveView:(SineWaveViewController *)view cancelled:(BOOL)wasCancelled;
- (void)showLoadingView;
- (void)requestFailedWithError:(NSError *)error;
@end

@interface SpeechToTextModule : NSObject <UIAlertViewDelegate, SineWaveViewDelegate> {
    UIAlertView *status;
    
    AQRecorderState aqData;
    
    BOOL detectedSpeech;
    int samplesBelowSilence;
    
    NSTimer *meterTimer;
    BOOL processing;
    
    NSMutableArray *volumeDataPoints;
    SineWaveViewController *sineWave;
    
    NSThread *processingThread;
}

@property (readonly) BOOL recording;
@property (assign) id<SpeechToTextModuleDelegate> delegate;

/* Caller can pass a non-nil nib name to specify the nib with which to create
 a SineWaveViewController (nib should conform to the spec in the SineWaveViewController
 interface). A nil argument will cause the module to display an alert view instead
 of the custom view controller. */
- (id)initWithCustomDisplay:(NSString *)nibName;

// Begins a voice recording
- (void)beginRecording;

// Stops a voice recording. The startProcessing parameter is intended for internal use,
// so don't pass NO unless you really mean it.
- (void)stopRecording:(BOOL)startProcessing;

@end
