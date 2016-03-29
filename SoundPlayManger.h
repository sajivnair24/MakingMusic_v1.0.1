//
//  SoundPlayManger.h
//  FlamencoRhythm
//
//  Created by Nirma on 09/03/16.
//  Copyright © 2016 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "DBManager.h"
#import "RecordingListData.h"
#import "RhythmClass.h"

#include <AVFoundation/AVFoundation.h>

#define MAX_VOL 100.0f
@interface SoundPlayManger : NSObject{
    
    DBManager *sqlManager;
    
    NSString *beatOneMusicFile, *beatTwoMusicFile, *rythmName;
    BOOL clapFlag1, clapFlag2, clapFlag3, clapFlag4;
    BOOL recFlag1, recFlag2, recFlag3, recFlag4;
    int instrV1, instrV2, instrV3, instrV4, tV1, tV2, tV3, tV4;
    int instrP1, instrP2, instrP3, instrP4, tP1, tP2, tP3, tP4;
    
    NSNumber *recordID,*originalBPM;
    NSString *currentRythmName;
    float songDuration;
    
    RhythmClass *rhythmRecord;
    NSMutableArray *audioPlayerArray;
    NSTimer *stopSoundTimer;
}

- (void) playSelectedRecording:(RecordingListData *)data;

- (NSString *)loadFilesForMixingAndSharing:(RecordingListData *)data;


-(void)stopAllSound;
@property (strong, nonatomic) NSNumber *startBPM;
@property (strong, nonatomic) NSString *droneType;
@property (strong, nonatomic) NSString *recTrackOne,*recTrackTwo,*recTrackThree,*recTrackFour;
@end
