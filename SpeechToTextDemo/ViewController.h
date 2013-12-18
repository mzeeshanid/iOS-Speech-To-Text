//
//  ViewController.h
//  SpeechToTextDemo
//
//  Created by Muhammad Zeeshan on 12/15/13.
//  Copyright (c) 2013 Muhammad Zeeshan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SpeechToTextModule.h"

@interface ViewController : UIViewController <SpeechToTextModuleDelegate>
{
    
}
@property(nonatomic, strong)SpeechToTextModule *speechToTextObj;
@end
