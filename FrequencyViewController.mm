//
//  FrequencyViewController.m
//  FlamencoRhythm
//
//  Created by Mayank Mathur on 05/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import "FrequencyViewController.h"
#include <iostream>
using namespace std;

const float freq[12] = {16.35, 17.32, 18.35, 19.45, 20.60, 21.83, 23.12, 24.50, 25.96, 27.50, 29.14, 30.87};

const int freqStart[9] = {16, 32, 65, 130, 261, 523, 1047, 2093, 4186};
const int freqEnd[9]   = {30, 61, 123, 246, 493, 987, 1976, 3951, 7902};

const string notes[12] = {"C.png", "C1.png", "D.png", "Eb.png", "E.png", "F.png", "F1.png", "G.png", "G1.png", "A.png", "Bb.png", "B.png"};
//const string notes[12] = {"C", "C#", "D", "Eb", "E", "F", "F#", "G", "G#", "A", "Bb", "B"};

const float xPercCircles[15] = {7.96, 9.84, 13.43, 18.59, 25.15, 32.81, 41.25, 50, 58.75, 67.18, 74.84, 81.40, 86.56, 90.15, 92.03};
const float yPercCircles[15] = {73.23, 68.39, 63.90, 59.85, 56.51, 54.04, 52.55, 52.02, 52.55, 54.04, 56.51, 59.85, 63.90, 68.39, 73.23};

@interface FrequencyViewController() {
    CTPitchTracker *pitchTracker;
    int mult;
    float fRange;
    float sRange;
    int fLen;
    int ind;
    int otherInd;
    int smallestIndex;
    NSString *prevNote;
    int counter;
    int prevNoteNumber;
    
    int num;
    int power;
    bool bRet;
    int cLen;
    
    int intFrequency;
    float floatFrequency;
    float prevInputFrequency;
    float diff;
    float quotient;
    int index;
    float callibration1;
    float callibration2;
    float diffArray[12];
    float callibrationArray[14];
    float callibrationDiffArray[14];
    NSArray *droneArray;
    NSTimer *timer;
    NSTimer *delayTimer;
}

@end

@implementation FrequencyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;    //sn
    
//    if ([[AVAudioSession sharedInstance] isInputGainSettable]) {
//        BOOL success = [[AVAudioSession sharedInstance] setInputGain:2
//                                                 error:nil];
//        if(success) {
//            int x = 0;
//        }
//    }
    
    otherInd = 0;
    pitchTracker = [[CTPitchTracker alloc] init];
    fLen = (sizeof(freq)/sizeof(*freq));
    cLen = 14;
    timer = [NSTimer timerWithTimeInterval:0.3f target:self selector:@selector(startTuner) userInfo:nil repeats:YES];
    [timer fire];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];

    droneArray = [[NSArray alloc]initWithObjects:@"C", @"D", @"D", @"E", @"E", @"F", @"G", @"G", @"A", @"A", @"B", @"B", nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    for (int i = 1; i <14; i++) {
        UIImageView *img = (UIImageView*)[self.droneBeatMeter viewWithTag:i];
        [img setHidden:YES];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    CGRect visibleSize = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = visibleSize.size.width;
    CGFloat screenHeight = visibleSize.size.height;
    
    for (int i = 1; i < 14; i++) {
        UIImageView *img = (UIImageView*)[self.droneBeatMeter viewWithTag:i];
        img.frame = CGRectMake((screenWidth * xPercCircles[i]/100)-10, ((screenHeight * yPercCircles[i]/100)-11), 21, 21);
        [img setHidden:NO];
    }
}

-(void)startTuner {
    intFrequency = [pitchTracker.currentPitch intValue];
    floatFrequency = [pitchTracker.currentPitch floatValue];
        
    UIImageView *centerImage;
    UIImageView *centerImage1;
    smallestIndex = -1;
    
    if((intFrequency > 25) && (intFrequency <= 4250))
    {
        fRange = floatFrequency/freq[0];
        sRange = floatFrequency/freq[fLen - 1];
        
        mult = [self getMultipleOfTwoInRange];
        
        NSLog(@"IntFrequency : %d\n", intFrequency);
        
        for(int i = 0; i < 9; i++) {
            if((freqEnd[i] < intFrequency) && (freqStart[i + 1] > intFrequency)) {
                if((intFrequency - freqEnd[i]) > (freqStart[i + 1] - intFrequency)) {
                    smallestIndex = 0;
                } else if ((intFrequency - freqEnd[i]) < (freqStart[i + 1] - intFrequency)){
                    smallestIndex = fLen - 1;
                }
            }
        }

        if((mult != 0) || (smallestIndex > -1))
        {
            if(smallestIndex < 0) {
                [self getDiffArray];
                smallestIndex = [self getIndexOfSmallestDiff];
            }
            
            centerImage = (UIImageView*)[self.droneBeatMeter viewWithTag:ind];
            [centerImage setImage:[UIImage imageNamed:@"Claps4_Gray.png"]];
            
            centerImage1 = (UIImageView*)[self.droneBeatMeter viewWithTag:otherInd];
            [centerImage1 setImage:[UIImage imageNamed:@"Claps4_Gray.png"]];
            
            
            if ((smallestIndex == 1) || (smallestIndex == 3) || (smallestIndex == 6) || (smallestIndex == 8) || (smallestIndex == 10)) {
                secondLbl.text = @"♭";
                
                [secondLbl setHidden:NO];
                // Show Both Labels
                firstLbl.frame = CGRectMake(2, 35, 85, 110);
                secondLbl.frame = CGRectMake(82, 5, 60, 110);
                
            } else {
                [secondLbl setHidden:YES];
                // Show only First Label
                firstLbl.frame = CGRectMake(29, 35, 85, 110);
            }
            firstLbl.text = [droneArray objectAtIndex:smallestIndex];
            
            [self getCallibrationArray];
            
            prevNote = [droneArray objectAtIndex:smallestIndex];
            prevNoteNumber = log2(mult);
            prevInputFrequency = floatFrequency;
        }
    } else {
        firstLbl.text = @"";
        secondLbl.text = @"";
        centerImage = (UIImageView*)[self.droneBeatMeter viewWithTag:ind];
        [centerImage setImage:[UIImage imageNamed:@"Claps4_Gray.png"]];
        
        centerImage1 = (UIImageView*)[self.droneBeatMeter viewWithTag:otherInd];
        [centerImage1 setImage:[UIImage imageNamed:@"Claps4_Gray.png"]];
    }
}

-(void)getCallibrationArray {
    bool endRange = false;
    for(int i = 0; i < 9; i++) {
        if((freqEnd[i] < intFrequency) && (freqStart[i + 1] > intFrequency)) {
            endRange = true;
            if((intFrequency - freqEnd[i]) > (freqStart[i + 1] - intFrequency)) {
                fRange = (freqStart[i + 1] + freqEnd[i]) / 2;
                sRange = freqStart[i + 1];
                
                callibration1 = (sRange - fRange)/7;
                
                for (int i = 0; i < 7; i++) {
                    callibrationArray[i] = fRange + callibration1 * i;
                }
                
                fRange = freqStart[i + 1];
                sRange = (freqStart[i + 1] + freq[1] * pow(2, (i + 1))) / 2;
                
                callibration2 = (sRange - fRange)/7;
                
                for (int i = 0; i < 7; i++) {
                    callibrationArray[i + 7] = fRange + callibration2 * i;
                }
                
                [self getCallibrationDiffArray];
            } else if ((intFrequency - freqEnd[i]) < (freqStart[i + 1] - intFrequency)){
                fRange = (freqEnd[i] + freq[11] * pow(2, i)) / 2;
                sRange = freqEnd[i];
                
                callibration1 = (sRange - fRange)/7;
                
                for (int i = 0; i < 7; i++) {
                    callibrationArray[i] = fRange + callibration1 * i;
                }
                
                fRange = freqEnd[i];
                sRange = (freqEnd[i] + freqStart[i + 1]) / 2;
                
                callibration2 = (sRange - fRange)/7;
                
                for (int i = 0; i < 7; i++) {
                    callibrationArray[i + 7] = fRange + callibration2 * i;
                }
                
                [self getCallibrationDiffArray];
            }
        }
    }
    
    if(!endRange) {
        
        fRange = ((freq[smallestIndex] + freq[smallestIndex - 1] ) / 2 ) * mult;
        //  fRange = freq[smallestIndex - 1] * mult;
        sRange = freq[smallestIndex] * mult;
        
        callibration1 = (sRange - fRange)/7;
        
        for (int i = 0; i < 7; i++) {
            callibrationArray[i] = fRange + callibration1 * i;
        }
        
        fRange = freq[smallestIndex] * mult;
        // sRange = freq[smallestIndex + 1] * mult;
        sRange = ((freq[smallestIndex] + freq[smallestIndex + 1] ) / 2 ) * mult;
        
        callibration2 = (sRange - fRange)/7;
        
        for (int i = 0; i < 7; i++) {
            callibrationArray[i + 7] = fRange + callibration2 * i;
        }
        
        // Difference from floatFrequency to callibrationArray note Frequency
        [self getCallibrationDiffArray];
    }
    
    // Returns the closest index from input Frequency
    ind = [self getIndexOfSmallestCallDiff];
    // as there is no Circle image with ZERO tag
    if (ind == 0) {
        ind++;
    }
    
    UIImageView *newImage;
    UIImageView *newImage1;
    
    if (ind == 7) {
        newImage = (UIImageView*)[self.droneBeatMeter viewWithTag:7];
        [newImage setImage:[UIImage imageNamed:@"beat_ball_green.png"]];
    } else {
        
        float freqDiff = 0.0;
        
        if (callibrationArray[ind] > floatFrequency) {
            otherInd = ind - 1;
            if (otherInd == 0) {
                otherInd++;
            }
            freqDiff = ((callibrationArray[ind] - callibrationArray[otherInd]) /3);
            
            if ((callibrationArray[otherInd] <= floatFrequency) && (floatFrequency < (callibrationArray[otherInd] + freqDiff))) {
                // first ball red
                newImage = (UIImageView*)[self.droneBeatMeter viewWithTag:otherInd];
                [newImage setImage:[UIImage imageNamed:@"beat_ball_red.png"]];
                
            } else if (((callibrationArray[otherInd] + freqDiff) <= floatFrequency) && (floatFrequency <(callibrationArray[otherInd] + (freqDiff * 2)))) {
                // both balls red
                newImage = (UIImageView*)[self.droneBeatMeter viewWithTag:otherInd];
                
                if (otherInd == 7) {
                    [newImage setImage:[UIImage imageNamed:@"beat_ball_green.png"]];
                } else {
                    [newImage setImage:[UIImage imageNamed:@"beat_ball_red.png"]];
                }
                
                newImage1 = (UIImageView*)[self.droneBeatMeter viewWithTag:ind];
                [newImage1 setImage:[UIImage imageNamed:@"beat_ball_red.png"]];
                
            } else {
                // last ball red
                newImage = (UIImageView*)[self.droneBeatMeter viewWithTag:ind];
                [newImage setImage:[UIImage imageNamed:@"beat_ball_red.png"]];
            }
        } else {
            otherInd = ind + 1;
            // as there is no Circle image with 14 tag
            if (otherInd == 14) {
                otherInd--;
            }
            
            freqDiff = ((callibrationArray[otherInd] - callibrationArray[ind])/3);
            
            if ((callibrationArray[ind] <= floatFrequency) && (floatFrequency < (callibrationArray[ind] + freqDiff))) {
                // first ball red
                newImage = (UIImageView*)[self.droneBeatMeter viewWithTag:ind];
                [newImage setImage:[UIImage imageNamed:@"beat_ball_red.png"]];
                
            } else if (((callibrationArray[ind] + freqDiff) <= floatFrequency) && (floatFrequency <(callibrationArray[ind] + (freqDiff * 2)))) {
                // both balls red
                newImage = (UIImageView*)[self.droneBeatMeter viewWithTag:ind];
                [newImage setImage:[UIImage imageNamed:@"beat_ball_red.png"]];
                
                newImage1 = (UIImageView*)[self.droneBeatMeter viewWithTag:otherInd];
                if (otherInd == 7) {
                    [newImage1 setImage:[UIImage imageNamed:@"beat_ball_green.png"]];
                } else {
                    [newImage1 setImage:[UIImage imageNamed:@"beat_ball_red.png"]];
                }
            } else {
                // last ball red
                newImage1 = (UIImageView*)[self.droneBeatMeter viewWithTag:otherInd];
                [newImage1 setImage:[UIImage imageNamed:@"beat_ball_red.png"]];
            }
        }
    }
}

-(int)getMultipleOfTwoInRange {
    num = 1;
    power = 1;
    bRet = false;
    
    while(!bRet) {
        num = pow(2, power);
        
        if((sRange < num) && (num < fRange)) {
            bRet = true;
        }
        
        if(num == 1024) {
            num = 0;
            bRet = true;
        }
        
        power++;
    }
    
    return num;
}

-(void)getDiffArray {
    for(int i = 0; i < fLen; i++) {
        quotient = floatFrequency/freq[i];
        
        if(quotient > mult) {
            diff = quotient - mult;
        }
        else {
            diff = mult - quotient;
        }
        
        diffArray[i] = diff;
    }
}

-(int)getIndexOfSmallestDiff {
    index = fLen - 1;
    
    for (int i = 0; i < fLen; i++) {
        if (diffArray[i] < diffArray[index]) {
            index = i;
        }
    }
    
    return index;
}

-(int)getIndexOfSmallestCallDiff
{
    index = cLen - 1;
    
    for (int i = 0; i < cLen; i++) {
        if (callibrationDiffArray[i] < callibrationDiffArray[index]) {
            index = i;
        }
    }
    
    return index;
}

-(void)getCallibrationDiffArray
{
    for(int i = 0; i < cLen; i++) {
        if(callibrationArray[i] > floatFrequency) {
            diff = callibrationArray[i] - floatFrequency;
        }
        else {
            diff = floatFrequency - callibrationArray[i];
        }
        
        callibrationDiffArray[i] = diff;
    }
    
}

-(void)delayCall {
    
    NSTimer *myTimer = [NSTimer timerWithTimeInterval:0.05f target:self selector:@selector(startTuner) userInfo:nil repeats:NO];
    [myTimer fire];
    [[NSRunLoop mainRunLoop] addTimer:myTimer forMode:NSDefaultRunLoopMode];
    [delayTimer invalidate];
}

-(void)viewDidLayoutSubviews {
    CGRect visibleSize = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = visibleSize.size.width;
    CGFloat screenHeight = visibleSize.size.height;
    
    for (int i = 1; i <14; i++) {
        UIImageView *img = (UIImageView*)[self.droneBeatMeter viewWithTag:i];
        img.frame = CGRectMake((screenWidth * xPercCircles[i]/100)-10, ((screenHeight * yPercCircles[i]/100)-11), 21, 21);
    }
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onTapBack:(id)sender {
    [UIApplication sharedApplication].idleTimerDisabled = NO;   //sn
    [self dismissViewControllerAnimated:YES completion:nil];
    [timer invalidate];
}

@end
