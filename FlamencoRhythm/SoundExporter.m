//
//  SoundExporter.m
//  Making Music
//
//  Created by Nirma on 08/09/16.
//  Copyright © 2016 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import "SoundExporter.h"
#define ROUNDF(f, c) (((float)((int)((f) * (c))) / (c)))
@implementation SoundExporter


- (void)mixAudioFilesWithParams:(NSMutableArray*)soundParams
                    withTotalDuration:(float)totalAudioDuration
                  withRecordingString:(NSString *)recordingString
                             andTempo:(float)tempo{
    
    NSError* error = nil;
    NSString *outputFile;
    
    AVURLAsset* fileAsset;
    NSArray *fileAssetDetails;
    AVAssetExportSession* exportSession;
    AVMutableCompositionTrack* audioTrack;
    
    int length = (int)[soundParams count];
    
    AVMutableComposition* composition = [AVMutableComposition composition];
    
    // Get the maximum duration of files to be mixed.
    CMTime maxDuration = [self getMaxAudioAssetDuration:soundParams withTotalAudioDuration:totalAudioDuration];
    NSMutableArray *audioParam = [NSMutableArray array];
    for(int i = 0; i < length; i++) {
        SoundParameters *soundParam = [soundParams objectAtIndex:i];
        audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                              preferredTrackID:kCMPersistentTrackID_Invalid];
        
        // fileAssetDetails = [[soundParams objectAtIndex:i] componentsSeparatedByString: @":"];
        
        fileAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:soundParam.soundUrl]
                                            options:nil];
        
        // If not recordings.
        if(soundParam.soundType != kSoundTypeRecording) {
            if(CMTimeCompare(maxDuration, fileAsset.duration) == 1 || CMTimeCompare(maxDuration, fileAsset.duration) == 0 ){
                CMTime currTime = kCMTimeZero;
                CMTime audioDuration = fileAsset.duration;
                
                if(soundParam.soundType != kSoundTypeMetrome) {
                    if(tempo == 1.0f) {
                        float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
                        
                        audioDuration = CMTimeMakeWithSeconds(audioDurationSeconds, 10);
                    }
                }
                
                while(YES) {
                    CMTime totalDuration = CMTimeAdd(currTime, audioDuration);
                    
                    if(CMTimeCompare(totalDuration, maxDuration)==1){
                        // Audio duration for last loop.
                        // Loop files only till maximum duration.
                        audioDuration = CMTimeSubtract(maxDuration, currTime);
                    }
                    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioDuration)
                                        ofTrack:[[fileAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                         atTime:currTime
                                          error:nil];
                    currTime = CMTimeAdd(currTime, audioDuration);
                    // If loop reaches its last round.
                    if(CMTimeCompare(currTime, maxDuration) == 1 || CMTimeCompare(currTime, maxDuration) == 0){
                        break;
                    }
                }
            }
        } else { // For recordings.
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, fileAsset.duration)
                                ofTrack:[[fileAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                 atTime:kCMTimeZero
                                  error:&error];
        }
        
        
        float leftChannelVolume = (float)(100-soundParam.soundPan)/100.0;
        float rightChannelVolume = (float)soundParam.soundPan/100.0;
        MTAudioProcessingTapCallbacks callbacks = [self getTapCallBacksleftChannelVolume:leftChannelVolume rightChannelVolume:rightChannelVolume];
        
        // Create a processing tap for the input parameters
        MTAudioProcessingTapRef tap;
        OSStatus err = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks,
                                                  kMTAudioProcessingTapCreationFlag_PostEffects, &tap);
        if (err || !tap) {
            NSLog(@"Unable to create the Audio Processing Tap");
           
        }
        


        AVMutableAudioMixInputParameters *audioInputParams = [AVMutableAudioMixInputParameters audioMixInputParameters];
        [audioInputParams setVolume:1.0 atTime:kCMTimeZero];
        [audioInputParams setTrackID:[audioTrack trackID]];
        //if(soundParam.soundType == kSoundTypeLoopTrack || soundParam.soundType == kSoundTypeRecording){
            audioInputParams.audioTapProcessor = tap;
       // }
    
        [audioParam addObject:audioInputParams];
        CFRelease(tap);
    }
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    [audioMix setInputParameters:audioParam];
   [self exportComposition:composition outPutFileName:recordingString audioSetting:audioMix];
   // return outputFile;
}
- (CMTime)getMaxAudioAssetDuration:(NSMutableArray*)soundParams  withTotalAudioDuration:(float)totalAudioDuration {
    AVURLAsset* fileAsset;
    NSArray *fileAssetDetails;
    CMTime maxDuration  = kCMTimeZero;
    CMTime lastDuration = kCMTimeZero;
    
    int length = (int)[soundParams count];
    
    for(int i = 0; i < length; i++) {
        SoundParameters *soundparam = [soundParams objectAtIndex:i];
        
        
        fileAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:soundparam.soundUrl]
                                            options:nil];
        
        if(CMTimeCompare(fileAsset.duration, lastDuration) == 1 || CMTimeCompare(fileAsset.duration, lastDuration) == 0) {
            maxDuration = fileAsset.duration;
        }
        
        lastDuration = fileAsset.duration;
    }
    
    CMTime totalDuration = CMTimeMakeWithSeconds(totalAudioDuration, 1000);
    if(CMTimeCompare(totalDuration, maxDuration) == 1)
        maxDuration = totalDuration;
    
    return maxDuration;
}

-(void)exportComposition:(AVComposition*)composition
               outPutFileName:(NSString*)recordingString
               audioSetting:(AVMutableAudioMix*) audioMix{
    NSError* error = nil;
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:composition
                                                                            presetName:AVAssetExportPresetAppleM4A];
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/Shared"];
    
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath])
        [[NSFileManager defaultManager] removeItemAtPath:dataPath error:nil];
    
    //Create folder
    [[NSFileManager defaultManager] createDirectoryAtPath:dataPath
                              withIntermediateDirectories:NO
                                               attributes:nil
                                                    error:&error];
    
    NSString *outputFile = [dataPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.m4a", recordingString]];
    
    exportSession.outputURL = [NSURL fileURLWithPath:outputFile];
    exportSession.outputFileType = AVFileTypeAppleM4A;
    if (audioMix != nil) {
        exportSession.audioMix = audioMix;
    }
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        
        // export status changed, check to see if it's done, errored, waiting, etc
        switch (exportSession.status)
        {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"#### Failed\n");
                [self.delegate exportFileFailed];
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"### Success\n");
                [self.delegate exportedFileUrl:outputFile];
                break;
            case AVAssetExportSessionStatusWaiting:
                break;
            default:
                break;
        }
    }];
   // return outputFile;
    
}

-(MTAudioProcessingTapCallbacks)getTapCallBacksleftChannelVolume:(float)leftChannel
                                              rightChannelVolume:(float)rightChannel{
    AVAudioTapProcessorContext *context = calloc(1, sizeof(AVAudioTapProcessorContext));
    NSLog(@"Initialising the Audio Tap Processor");
    context->leftChannelVolume = leftChannel;
    context->rightChannelVolume = rightChannel;
    
    // Create a processing tap for the input parameters
    MTAudioProcessingTapCallbacks callbacks;
    callbacks.version = kMTAudioProcessingTapCallbacksVersion_0;
    callbacks.clientInfo = context;//(__bridge void *)(self);
    callbacks.init = init;
    callbacks.prepare = prepare;
    callbacks.process = process1;
    callbacks.unprepare = unprepare;
    callbacks.finalize = finalize;
    return callbacks;
}

void init(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut)
{
    
    *tapStorageOut = clientInfo;
}

void finalize(MTAudioProcessingTapRef tap)
{
    NSLog(@"Finalizing the Audio Tap Processor");
    AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
    
    // Clear MTAudioProcessingTap context.
    // context->self = NULL;
    
    free(context);
    
}

void prepare(MTAudioProcessingTapRef tap, CMItemCount maxFrames, const AudioStreamBasicDescription *processingFormat)
{
    NSLog(@"Preparing the Audio Tap Processor");
}

void unprepare(MTAudioProcessingTapRef tap)
{
    NSLog(@"Unpreparing the Audio Tap Processor");
}
#define LAKE_LEFT_CHANNEL (0)
#define LAKE_RIGHT_CHANNEL (1)
void process1(MTAudioProcessingTapRef tap, CMItemCount numberFrames,
              MTAudioProcessingTapFlags flags, AudioBufferList *bufferListInOut,
              CMItemCount *numberFramesOut, MTAudioProcessingTapFlags *flagsOut)
{
    //NSLog(@"Processing the Audio Tap Processor");
    AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
    // NSLog(@"CMItemCount = %ld", *numberFramesOut);
    // NSLog(@"CMItemCount numberFrames = %ld",numberFrames);
    // NSLog(@"context left channelVolume id = %f",context->leftChannelVolume );
    OSStatus err = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut,
                                                      flagsOut, NULL, numberFramesOut);
    if (err) NSLog(@"Error from GetSourceAudio: %d", (int)err);
    
    float scalarLeft = context->leftChannelVolume;
    float scalarRight = context->rightChannelVolume;
    vDSP_vsmul(bufferListInOut->mBuffers[LAKE_RIGHT_CHANNEL].mData, 1, &scalarRight, bufferListInOut->mBuffers[LAKE_RIGHT_CHANNEL].mData, 1, bufferListInOut->mBuffers[LAKE_RIGHT_CHANNEL].mDataByteSize / sizeof(float));
    vDSP_vsmul(bufferListInOut->mBuffers[LAKE_LEFT_CHANNEL].mData, 1, &scalarLeft, bufferListInOut->mBuffers[LAKE_LEFT_CHANNEL].mData, 1, bufferListInOut->mBuffers[LAKE_LEFT_CHANNEL].mDataByteSize / sizeof(float));
    
}

@end
