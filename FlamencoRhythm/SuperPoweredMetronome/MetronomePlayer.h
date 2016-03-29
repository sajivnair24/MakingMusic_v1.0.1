//
//  SuperPoweredPlayer.h
//  FlamencoRhythm
//
//  Created by Sajiv Nair on 07/09/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#ifndef FlamencoRhythm_SuperPoweredPlayer_h
#define FlamencoRhythm_SuperPoweredPlayer_h


#endif

@interface MetronomePlayer : NSObject {
}

-(id)init;

-(void)initializeAudioOutputForMetronome;

//  Initialize
-(void)open:(NSString *)filePath;

-(void)releaseObjects;

// Play the opened file
-(void)play:(double)bpmValue;

// Stop playback
-(void)stop;

// reset playback on bpm change
-(void)reset:(double)bpmValue;

// Set volume of metronome
-(void)setVolume:(float)vol;
// set volume tempo for metronome
-(void)setTempo:(float)bpmValue;

@end
