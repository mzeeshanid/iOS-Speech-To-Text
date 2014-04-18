//
//  ViewController.h
//  SpeechToTextDemo
//
//  Created by Muhammad Zeeshan on 12/15/13.
//  Copyright (c) 2013 Muhammad Zeeshan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SpeechTranscriber.h"

@interface ViewController : UIViewController <SpeechTranscriberDelegate>
{
    
}
@property(nonatomic, strong)SpeechTranscriber *speechToTextObj;
@end
