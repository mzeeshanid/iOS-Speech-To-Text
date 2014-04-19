//
//  SpeechTranscriber.h
//  SpeechToTextDemo
//
//  Created by admin on 4/18/14.
//  Copyright (c) 2014 James Smith. All rights reserved.
//

static const NSInteger kNumVolumeSamples = 10;
static const CGFloat kSilenceThresholdDB = - 30.0;

static const CGFloat kVolumeSamplingInterval = 0.05;
static const CGFloat kSilenceTimeThreshold = 0.9;
static const CGFloat kSilenceThresholdNumSamples = (kSilenceTimeThreshold / kVolumeSamplingInterval);

static const CGFloat kMinVolumeSampleValue = 0.01;
static const CGFloat kMaxVolumeSampleValue = 1.0;

@class SineWaveViewController;
@class SpeechTranscriber;
@class SpeechData;

@import Foundation;
@import AudioToolbox;
#import <Speex/speex.h>
#import "AQRecorderState.h"

//
// Speech Transcriber Delegate
// Delegates must implement SpeechTranscriberDidReceiveVoiceResponse:
//
@protocol SpeechTranscriberDelegate <NSObject>

- (BOOL)speechTranscriberDidReceiveVoiceResponse:(NSData *)data;

@optional
-(void)speechTranscriberShowSineWaveView:(SineWaveViewController *)view;
-(void)speechTranscriberDismissSineWaveView:(SineWaveViewController *)view cancelled:(BOOL)wasCancelled;
-(void)speechTranscriberShowLoadingView;
-(void)speechTranscriberRquestFailedWithError:(NSError *)error;

@end

//
// Speech Transcriber Data Points Delegate
// Delegate can subscribe to additional data concerning speech input (loudness, etc)
//
@protocol SpeechTranscriberDataPointsDelegate <NSObject>
- (void)speechTranscriber:(SpeechTranscriber *)transcriber receivedSpeechData:(SpeechData *)data;
@end


//
// Speech Transcriber
//
@interface SpeechTranscriber : NSObject
@property (nonatomic, strong) AQRecorderState *aqData;
@property (nonatomic, weak)id<SpeechTranscriberDelegate> delegate;
@property (nonatomic, weak)id<SpeechTranscriberDataPointsDelegate> dataPointsDelegate;
-(void)beginRecording;
-(void)stopRecording;

@end
