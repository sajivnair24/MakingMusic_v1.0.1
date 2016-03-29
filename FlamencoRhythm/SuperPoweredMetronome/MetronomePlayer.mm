//
//  SuperPoweredPlayer.m
//  FlamencoRhythm
//
//  Created by Sajiv Nair on 07/09/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "MetronomePlayer.h"

// Superpowered C++ Library header inclusions
#import "SuperpoweredAdvancedAudioPlayer.h"
#import "SuperpoweredIOSAudioOutput.h"
#import "SuperpoweredSimple.h"
#import <stdlib.h>
#import <pthread.h>

#define DEFAULT_BPM 60

float *stereoBuffers = nullptr;
unsigned int lastSampleRate;
pthread_mutex_t mutex;
bool silence = true;

SuperpoweredIOSAudioOutput *audioOutput = nullptr;
SuperpoweredAdvancedAudioPlayer *audioPlayer = nullptr;
float mVolume;

void playerCallback(void *clientData,
                    SuperpoweredAdvancedAudioPlayerEvent event,
                    void *value) {}

@implementation MetronomePlayer {
    
}

- (void)interruptionEnded { // If a player plays Apple Lossless audio files, then we need this. Otherwise unnecessary.
    //audioPlayer->onMediaserverInterrupt();
}

// This is where the Superpowered magic happens.
- (bool)audioProcessingCallback:(float **)buffers
                  inputChannels:(unsigned int)inputChannels
                 outputChannels:(unsigned int)outputChannels
                numberOfSamples:(unsigned int)numberOfSamples
                     samplerate:(unsigned int)samplerate
                       hostTime:(UInt64)hostTime {
    
    // Has samplerate changed?
    if (samplerate != lastSampleRate) {
        lastSampleRate = samplerate;
        if(audioPlayer != nullptr)
            audioPlayer->setSamplerate(samplerate);
    };
    
    pthread_mutex_lock(&mutex);
    
    if(audioPlayer != nullptr) {
        if (audioPlayer->process(stereoBuffers,
                                 false,
                                 numberOfSamples,
                                 mVolume,
                                 audioPlayer->currentBpm,
                                 audioPlayer->msElapsedSinceLastBeat)) {
            silence = false;
        }
    }
    
    pthread_mutex_unlock(&mutex);
    
    // The stereoBuffer is ready now, let's put the finished audio into the requested buffers.
    if (!silence) SuperpoweredDeInterleave(stereoBuffers,
                                           buffers[0],
                                           buffers[1],
                                           numberOfSamples);
    return !silence;
}

-(id)init {
    mVolume = 0.0f;
    return self;
}

-(void)initializeAudioOutputForMetronome {
    // Allocating memory, aligned to 16.
    if(stereoBuffers == nullptr) {
        if (posix_memalign((void **)&stereoBuffers,
                           16,
                           4096 + 128) != 0) abort();
    }
    
    if(audioOutput == nullptr) {
        audioOutput = [[SuperpoweredIOSAudioOutput alloc] initWithDelegate:(id<SuperpoweredIOSAudioIODelegate>)self
                                                       preferredBufferSize:12
                                                preferredMinimumSamplerate:44100
                                                      audioSessionCategory:AVAudioSessionCategoryPlayAndRecord
                                                             multiChannels:2
                                                               fixReceiver:true];
        [audioOutput start];
    }
}

-(void)open:(NSString *)filePath {
    
    audioPlayer = new SuperpoweredAdvancedAudioPlayer((__bridge void *)self,
                                                      playerCallback,
                                                      44100,
                                                      0);
    
    audioPlayer->open([[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], filePath] UTF8String]);
    
    audioPlayer->syncMode = SuperpoweredAdvancedAudioPlayerSyncMode_TempoAndBeat;
    
}

-(void)releaseObjects {
    if(audioPlayer != nullptr) {
        delete audioPlayer;
        audioPlayer = nullptr;
    }
    
    //dealloc audioOutput;
}

//-(void)play:(double)bpmValue {
//    if(audioPlayer != nullptr) {
//        [self setTempo:bpmValue];
//        audioPlayer->play(true);
//    }
//}

-(void)play:(double)tempo {
    if(audioPlayer != nullptr) {
        audioPlayer->loopBetween(0.0,
                                 (audioPlayer->durationMs/(tempo/DEFAULT_BPM)),
                                 true,
                                 255,
                                 true);
        audioPlayer->play(true);
    }
}

-(void)stop {
    if(audioPlayer != nullptr) {
        silence = true;
        audioPlayer->pause();
        delete audioPlayer;
        audioPlayer = nullptr;
    }
}

//-(void)reset:(double)bpmValue{
//    [self setTempo:bpmValue];
//}

-(void)reset:(double)tempo{
    if(audioPlayer != nullptr && !audioPlayer->playing) {
        audioPlayer->pause();
        audioPlayer->loopBetween(0.0,
                                 (audioPlayer->durationMs/tempo),
                                 true,
                                 255,
                                 true);
        audioPlayer->play(true);
    }
}

-(void)setTempo:(float)bpmValue {
    if(audioPlayer != nullptr) {
        double tempoValue = bpmValue/DEFAULT_BPM;
        audioPlayer->setTempo(tempoValue, true);
    }
}

-(void)setVolume:(float)vol {
    mVolume = vol;
}


@end