//
//  RhythmClass.h
//  FlamencoRhythm
//
//  Created by Mayank Mathur on 18/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RhythmClass : NSObject{
    
}

@property (nonatomic, strong) NSNumber *rhythmId;
@property (nonatomic, strong) NSNumber *rhythmGenreId;
@property (nonatomic, strong) NSString *rhythmName;
@property (nonatomic, strong) NSString *rhythmBeatOne;
@property (nonatomic, strong) NSString *rhythmBeatTwo;
@property (nonatomic, strong) NSNumber *rhythmBPM;
@property (nonatomic, strong) NSNumber *rhythmStartBPM;
@property (nonatomic, strong) NSString *rhythmInstOneImage;
@property (nonatomic, strong) NSString *rhythmInstTwoImage;
@property (nonatomic, strong) NSNumber *rhythmBeatsCount;
@property (nonatomic, strong) NSNumber *rhythmPosition;
@property (nonatomic, strong) NSNumber *rhythmIsDeleted;
@property (nonatomic, strong) NSNumber *lag1;

@end
