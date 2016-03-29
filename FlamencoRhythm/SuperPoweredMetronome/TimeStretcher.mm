//
//  TimeStretching.m
//  FlamencoRhythm
//
//  Created by Sajiv Nair on 24/11/15.
//  Copyright © 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimeStretcher.h"

// SuperPowered header inclusions
#include "SuperpoweredDecoder.h"
#include "SuperpoweredSimple.h"
#include "SuperpoweredRecorder.h"
#include "SuperpoweredTimeStretching.h"
#include "SuperpoweredAudioBuffers.h"

@implementation TimeStretcher {
    TPAACAudioConverter *audioConverter;
}

-(id)init {
    return self;
}

-(void)timeStretchAndConvert:(NSString *)inputFile
              withOutputFile:(NSString *)outputFile
                   withTempo:(float)tempo {
    
    SuperpoweredDecoder *decoder = new SuperpoweredDecoder();
    //NSURL *url = [NSURL URLWithString:inputFile];
    //const char *openError = decoder->open([[url absoluteString] UTF8String], false, 0, 0);
    const char *openError = decoder->open([inputFile UTF8String], false, 0, 0);
    if (openError) {
        NSLog(@"open error: %s", openError);
        delete decoder;
        return;
    };
    
    SuperpoweredAudiobufferPool *bufferPool = new SuperpoweredAudiobufferPool(4, 1024 * 1024); // Allow 1 MB max. memory for the buffer pool.
    SuperpoweredTimeStretching *timeStretch = new SuperpoweredTimeStretching(bufferPool, decoder->samplerate);
    
    // Set tempo and pitch.
    timeStretch->setRateAndPitchShift(tempo, 0);
    
    // This buffer list will receive the time-stretched samples.
    SuperpoweredAudiopointerList *outputBuffers = new SuperpoweredAudiopointerList(bufferPool);
    
    // Delete file extension of path.
    NSString* destinationPath = [outputFile stringByDeletingPathExtension];
    destinationPath = [destinationPath stringByAppendingPathExtension:@"wav"];

    // Create the output WAVE file. The destination is accessible in iTunes File Sharing.
    FILE *fd = createWAV([destinationPath fileSystemRepresentation], decoder->samplerate, 2);
    if (!fd) {
        NSLog(@"File creation error.");
        delete decoder;
        return;
    };
    
    // Create a buffer for the 16-bit integer samples.
    short int *intBuffer = (short int *)malloc(decoder->samplesPerFrame * 2 * sizeof(short int) + 16384);
    
    // Processing.
    while (true) {
        // Decode one frame. samplesDecoded will be overwritten with the actual decoded number of samples.
        unsigned int samplesDecoded = decoder->samplesPerFrame;
        if (decoder->decode(intBuffer, &samplesDecoded) == SUPERPOWEREDDECODER_ERROR) break;
        if (samplesDecoded < 1) break;
        
        // Create an input buffer for the time stretcher.
        SuperpoweredAudiobufferlistElement inputBuffer;
        bufferPool->createSuperpoweredAudiobufferlistElement(&inputBuffer, decoder->samplePosition, samplesDecoded + 8);
        
        // Convert the decoded PCM samples from 16-bit integer to 32-bit floating point.
        SuperpoweredShortIntToFloat(intBuffer, bufferPool->floatAudio(&inputBuffer), samplesDecoded);
        inputBuffer.endSample = samplesDecoded; // <-- Important!
        
        // Time stretching.
        timeStretch->process(&inputBuffer, outputBuffers);
        
        // Do we have some output?
        if (outputBuffers->makeSlice(0, outputBuffers->sampleLength)) {
            
            while (true) { // Iterate on every output slice.
                float *timeStretchedAudio = NULL;
                int samples = 0;
                
                // Get pointer to the output samples.
                if (!outputBuffers->nextSliceItem(&timeStretchedAudio, &samples)) break;
                
                // Convert the time stretched PCM samples from 32-bit floating point to 16-bit integer.
                SuperpoweredFloatToShortInt(timeStretchedAudio, intBuffer, samples);
                
                // Write the audio to disk.
                fwrite(intBuffer, 1, samples * 4, fd);
            };
            
            // Clear the output buffer list.
            outputBuffers->clear();
        };
    };
    
    // Cleanup.
    closeWAV(fd);
    delete decoder;
    delete timeStretch;
    delete outputBuffers;
    delete bufferPool;
    free(intBuffer);
    
    // Convert from WAV back to M4A.
    //[self audioConvertFileFormat:destinationPath withOutputFile:outputFile];

}

-(void)audioConvertFileFormat:(NSString *)inputFile
               withOutputFile:(NSString *)outputFile {
    
    audioConverter = [[TPAACAudioConverter alloc] initWithDelegate:self
                                                            source:inputFile
                                                       destination:outputFile];
    [audioConverter start];
}

- (void)AACAudioConverterDidFinishConversion:(TPAACAudioConverter*)converter {
    [[NSFileManager defaultManager] removeItemAtPath:[converter source] error:nil];
}

- (void)AACAudioConverter:(TPAACAudioConverter*)converter didFailWithError:(NSError*)error {
    
}



@end