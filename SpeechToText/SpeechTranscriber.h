//
//  SpeechTranscriber.h
//  SpeechToTextDemo
//
//  Created by admin on 4/18/14.
//  Copyright (c) 2014 Muhammad Zeeshan. All rights reserved.
//

static const NSInteger kNumVolumeSamples = 10;
static const CGFloat kSilenceThresholdDB = - 30.0;

static const CGFloat kVolumeSamplingInterval = 0.05;
static const CGFloat kSilenceTimeThreshold = 0.9;
static const CGFloat kSilenceThresholdNumSamples = (kSilenceTimeThreshold / kVolumeSamplingInterval);

static const CGFloat kMinVolumeSampleValue = 0.01;
static const CGFloat kMaxVolumeSampleValue = 1.0;


@import AudioToolbox;
#import <Speex/speex.h>
#import "AQRecorderState.h"
@class SineWaveViewController;

@protocol SpeechTranscriberDelegate <NSObject>

// Delegate will need to parse JSON and dismiss loading view if presented
// returns true on success, false on failure
- (BOOL)didReceiveVoiceResponse:(NSData *)data;

@optional
- (void)showSineWaveView:(SineWaveViewController *)view;
- (void)dismissSineWaveView:(SineWaveViewController *)view cancelled:(BOOL)wasCancelled;
- (void)showLoadingView;
- (void)requestFailedWithError:(NSError *)error;
@end


@import Foundation;

@interface SpeechTranscriber : NSObject
@property (nonatomic, strong) AQRecorderState *aqData;
@property (nonatomic, weak)id<SpeechTranscriberDelegate> delegate;

-(void)beginRecording;



@end
