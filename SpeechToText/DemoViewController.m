//
//  DemoViewController.m
//  SpeechToTextDemo
//
//  Created by admin on 4/18/14.
//  Copyright (c) 2014 James Smith. All rights reserved.
//

// Controllers
#import "DemoViewController.h"

// Models
#import "SpeechTranscriber.h"

@interface DemoViewController () <SpeechTranscriberDelegate>
@property (nonatomic, weak) IBOutlet UIButton *transcribeButton;
@property (nonatomic, weak) IBOutlet UILabel *textLabel;
@property (nonatomic, strong) SpeechTranscriber *transcriber;

@property (nonatomic, assign) BOOL isRecording;
@end

@implementation DemoViewController

-(id)initWithCoder:(NSCoder *)aDecoder {
    
    if ( !(self = [super initWithCoder:aDecoder]) ) {
        return nil;
    }
    
    self.transcriber = [SpeechTranscriber new];
    self.transcriber.delegate = self;
    
    return self;
}

-(IBAction)transcribeButtonPressed:(id)sender {
    
    if (self.isRecording) {
        [self.transcribeButton setTitle:@"Transcribe" forState:UIControlStateNormal];
        [self.transcriber stopRecording];
        self.isRecording = NO;
    }
    else {
        [self.transcribeButton setTitle:@"Stop" forState:UIControlStateNormal];
        [self.transcriber beginRecording];
        self.isRecording = YES;
    }
}

#pragma mark - Speech Transcriber Delegate
-(BOOL)speechTranscriberDidReceiveVoiceResponse:(NSData *)data {
    NSError *jsonError;
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
    NSString *transcribedText = [response[@"hypotheses"] firstObject][@"utterance"];
    self.textLabel.text = transcribedText;
    
    return response != nil;
}

@end
