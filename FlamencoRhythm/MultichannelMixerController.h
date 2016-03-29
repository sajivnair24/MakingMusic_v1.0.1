///*
// Copyright (C) 2015 Apple Inc. All Rights Reserved.
// See LICENSE.txt for this sample’s licensing information
// 
// Abstract:
// The Controller Class for the AUGraph.
// */
//
//#import <AudioToolbox/AudioToolbox.h>
//#import <AudioUnit/AudioUnit.h>
//#import <AVFoundation/AVAudioFormat.h>
//#import "CAComponentDescription.h"
//#import "InMemoryAudioFile.h"
//#include "MetronomePlayer.h"
//
//#define MAXBUFS  100
//#define NUMFILES 100
//
//typedef struct {
//    AudioStreamBasicDescription asbd;
//    Float32 *data;
//    UInt32 numFrames;
//    UInt32 sampleNum;
//} SoundBuffer, *SoundBufferPtr;
//
//typedef struct {
//    AudioStreamBasicDescription asbd;
//    Float32 *data;
//    UInt32 numFrames;
//    UInt32 sampleNum;
//} SoundBufferRec, *SoundBufferRecPtr;
//
//@interface MultichannelMixerController : NSObject
//{
//    CFURLRef sourceURL[100];
//    CFURLRef recordedURL[100];
//    
//    Float64 bpmValue[100];
//    
//    AVAudioFormat *mAudioFormat;
//    
//    AUGraph   mTGraph;
//    AudioUnit mTMixer;
//    AudioUnit mTOutput;
//    AudioUnit mTInput;
//    AudioUnit mTimePitchAU;
//    
//    AUGraph   mRGraph;
//    AudioUnit mRMixer;
//    AudioUnit mROutput;
//    
//    SoundBuffer mSoundBuffer[MAXBUFS];
//    SoundBuffer mSoundRecBuffer[MAXBUFS];
//    
//    Boolean isPlaying;
//    Float64 KAUGraphSampleRate;
//    float currentBpm;
//    
//    bool hasRecordedFiles;
//    
//    MetronomePlayer *metronomePlayer;
//}
//
//@property (readonly, nonatomic) Boolean isPlaying;
//@property (nonatomic,assign) UInt32 numbuses;
//@property (nonatomic,assign) UInt32 numRecbuses;
//
//
//- (void)fillBuffers:(id)options andNumberOfBus:(UInt32)numBuses;
//- (void)initializeAUGraph;
//
//- (void)enableInput:(UInt32)inputNum isOn:(AudioUnitParameterValue)isONValue;
//- (void)setInputVolume:(UInt32)inputNum value:(AudioUnitParameterValue)value;
//- (void)setOutputVolume:(AudioUnitParameterValue)value;
//- (void) loadFilesForMixerInput:(SoundBuffer*)soundBuffer fromFilesArray:(CFURLRef*) filesArray withAudioFormat:(AVAudioFormat*) audioFormat;
//
//- (void)startAUGraph;
//- (void)stopAUGraph;
//
//- (void)changePlaybackRate:(AudioUnitParameterValue)inputNum;
//- (void)setCurrentBpm:(float)currBpm;
//- (void)setMetronomeVolume:(float)volume;
//
//@end

/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The Controller Class for the AUGraph.
 */

#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVAudioFormat.h>
#import "CAComponentDescription.h"
#import "InMemoryAudioFile.h"
#include "MetronomePlayer.h"

#define MAXBUFS  8
#define NUMFILES 8

typedef struct {
    AudioStreamBasicDescription asbd;
    Float32 *data;
    UInt32 numFrames;
    UInt32 sampleNum;
} SoundBuffer, *SoundBufferPtr;

@interface MultichannelMixerController : NSObject
{
    CFURLRef sourceURL[100];
    Float64 bpmValue[100];
    
    AVAudioFormat *mAudioFormat;
    
    AUGraph   mGraph;
    AudioUnit mMixer;
    AudioUnit mOutput;
    AudioUnit mInput;
    AudioUnit mTimeAU;
    
    SoundBuffer mSoundBuffer[MAXBUFS];
    
    Boolean isPlaying;
    Float64 KAUGraphSampleRate;
    int metronomeBusIndex;
    float currentBpm;
    
    MetronomePlayer *metronomePlayer;
    Float64 bpmMultiplier;
}

@property (readonly, nonatomic) Boolean isPlaying;
@property (nonatomic,assign) UInt32 numbuses;


- (void)fillBuffers:(id)options andNumberOfBus:(UInt32)numBuses;
- (void)initializeAUGraph;

- (void)enableInput:(UInt32)inputNum isOn:(AudioUnitParameterValue)isONValue;
- (void)setInputVolume:(UInt32)inputNum value:(AudioUnitParameterValue)inputVolume;
- (void)setPanPosition:(UInt32)inputNum value:(AudioUnitParameterValue)pannedPosition;
- (void)setOutputVolume:(AudioUnitParameterValue)value;

- (void)startAUGraph;
- (void)stopAUGraph:(BOOL)release;

- (void)seekToFrame:(int)seconds;

- (void)changePlaybackRate:(AudioUnitParameterValue)inputNum;
- (void)initializeAudioForMetronome;
- (void)setCurrentBpm:(float)currBpm;
- (void)setMetronomeVolume:(float)volume;
- (BOOL)isMixerOutputPlaying;

@end

