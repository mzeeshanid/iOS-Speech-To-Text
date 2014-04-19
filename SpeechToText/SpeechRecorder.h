//
//  AQRecorderState.h
//  SpeechToTextDemo
//
//  Created by admin on 4/18/14.
//  Copyright (c) 2014 Muhammad Zeeshan. All rights reserved.
//

@import Foundation;
@import AudioToolbox;
#import <Speex/speex.h>

static const NSInteger kNumberBuffers = 3;

@interface SpeechRecorder : NSObject {
@public
    AudioStreamBasicDescription mDataFormat;
    AudioQueueBufferRef mBuffers[kNumberBuffers];
    AudioQueueRef mQueue;
    UInt32 bufferByteSize;
    SInt64 mCurrentPacket;
    BOOL mIsRunning;
    
    SpeexBits speex_bits;
    void *speex_enc_state;
    int speex_samples_per_frame;
    NSMutableData *encodedSpeexData;
}
@end