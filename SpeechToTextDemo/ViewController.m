//
//  ViewController.m
//  SpeechToTextDemo
//
//  Created by Muhammad Zeeshan on 12/15/13.
//  Copyright (c) 2013 Muhammad Zeeshan. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    UITextField *fakeTextField;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    fakeTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    [fakeTextField setHidden:YES];
    [self.view addSubview:fakeTextField];
    
    self.speechToTextObj = [[SpeechToTextModule alloc] initWithCustomDisplay:@"SineWaveViewController"];
    [self.speechToTextObj setDelegate:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - My IBActions -
- (IBAction)recordSpeechButtonTapped:(UIButton *)sender
{
    [self.speechToTextObj beginRecording];
}
#pragma mark - SpeechToTextModule Delegate -
- (BOOL)didReceiveVoiceResponse:(NSData *)data
{
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"responseString: %@",responseString);
    return YES;
}
- (void)showSineWaveView:(SineWaveViewController *)view
{
    [view.view setFrame:self.view.bounds];
    [fakeTextField setInputView:view.view];
    [fakeTextField becomeFirstResponder];
}
- (void)dismissSineWaveView:(SineWaveViewController *)view cancelled:(BOOL)wasCancelled
{
     [fakeTextField resignFirstResponder];
}
- (void)showLoadingView
{
    NSLog(@"show loadingView");
}
- (void)requestFailedWithError:(NSError *)error
{
    NSLog(@"error: %@",error);
}
@end
