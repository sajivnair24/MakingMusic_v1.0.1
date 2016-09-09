//
//  SoundParameters.h
//  Making Music
//
//  Created by Nirma on 07/09/16.
//  Copyright © 2016 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
enum SoundType{
       kSoundTypeRecording,
       kSoundTypeLoopTrack,
       kSoundTypeMetrome
};

@interface SoundParameters : NSObject
@property(nonatomic ,strong) NSString *soundUrl;
@property(nonatomic ,assign) int soundPan;
@property(nonatomic ,assign) int soundVolume;
@property(nonatomic ,assign) enum SoundType soundType;
@property(nonatomic ,assign) float soundLeftChannelVolume;
@property(nonatomic ,assign) float soundRightChannelVolume;
@end
