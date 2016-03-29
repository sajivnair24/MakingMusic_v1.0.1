//
//  RecordingListData.h
//  FlamencoRhythm
//
//  Created by Ashish Gore on 19/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RhythmClass.h"
@interface RecordingListData : NSObject

@property (strong,nonatomic) NSNumber *isDeleted;
@property (nonatomic, strong) NSNumber *recordID;
@property (nonatomic, strong) NSNumber *instOne;
@property (nonatomic, strong) NSNumber *instTwo;
@property (nonatomic, strong) NSNumber *instThree;
@property (nonatomic, strong) NSNumber *instFour;
@property (nonatomic, strong) NSNumber *instFive;
@property (nonatomic, strong) NSNumber *volOne;
@property (nonatomic, strong) NSNumber *volTwo;
@property (nonatomic, strong) NSNumber *volThree;
@property (nonatomic, strong) NSNumber *volFour;
@property (nonatomic, strong) NSNumber *panOne;
@property (nonatomic, strong) NSNumber *panTwo;
@property (nonatomic, strong) NSNumber *panThree;
@property (nonatomic, strong) NSNumber *panFour;
@property (nonatomic, strong) NSNumber *BPM;
@property (nonatomic, strong) NSNumber *volTrackOne;
@property (nonatomic, strong) NSNumber *volTrackTwo;
@property (nonatomic, strong) NSNumber *volTrackThree;
@property (nonatomic, strong) NSNumber *volTrackFour;
@property (nonatomic, strong) NSNumber *panTrackOne;
@property (nonatomic, strong) NSNumber *panTrackTwo;
@property (nonatomic, strong) NSNumber *panTrackThree;
@property (nonatomic, strong) NSNumber *panTrackFour;
@property (nonatomic, strong) NSNumber *t1Flag;
@property (nonatomic, strong) NSNumber *t2Flag;
@property (nonatomic, strong) NSNumber *t3Flag;
@property (nonatomic, strong) NSNumber *t4Flag;
@property (nonatomic, strong) NSNumber *lag1;
@property (nonatomic, strong) NSNumber *lag2;

@property (nonatomic, strong) NSString *recordingName;
@property (nonatomic, strong) NSString *rhythmID;
@property (nonatomic, strong) NSString *trackOne;
@property (nonatomic, strong) NSString *trackTwo;
@property (nonatomic, strong) NSString *trackThree;
@property (nonatomic, strong) NSString *trackFour;
@property (nonatomic, strong) NSString *mergeFile;
@property (nonatomic, strong) NSString *dateString;
@property (nonatomic, strong) NSString *timeString;
@property (nonatomic, strong) NSString *durationString;
@property (nonatomic, strong) NSString *beat1;
@property (nonatomic, strong) NSString *beat2;
@property (nonatomic, strong) NSString *droneType;
@property (nonatomic, strong) NSString *t1DurationString;
@property (nonatomic, strong) NSString *t2DurationString;
@property (nonatomic, strong) NSString *t3DurationString;
@property (nonatomic, strong) NSString *t4DurationString;

@property (nonatomic ,assign) BOOL isSoundPlaying;

@property (nonatomic ,strong) RhythmClass *rhythmRecord;

@end
