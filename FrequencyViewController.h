//
//  FrequencyViewController.h
//  FlamencoRhythm
//
//  Created by Mayank Mathur on 05/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CTPitchTracker.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>



@interface FrequencyViewController : UIViewController{
    
    IBOutlet UILabel *droneLbl;
    IBOutlet UILabel *firstLbl;
    IBOutlet UILabel *secondLbl;
    
    IBOutlet UIImageView *c1,*c2,*c3,*c4,*c5,*c6,*c7,*c8,*c9,*c10,*c11,*c12,*c13;
}
@property (nonatomic, strong) IBOutlet UIView *droneBeatMeter;
- (IBAction)onTapBack:(id)sender;
@end
