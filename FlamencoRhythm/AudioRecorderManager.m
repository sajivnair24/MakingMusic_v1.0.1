//
//  AudioRecorderManager.m
//  FlamencoRhythm
//
//  Created by intelliswift on 20/08/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import "AudioRecorderManager.h"
#import <AVFoundation/AVFoundation.h>
#import  "AudioUnitRecorder.h"
#import "Constants.h"

#define MIC_GAIN_ENABLED 1

@interface AudioRecorderManager () {
    double peakPowerForChannel;
    int  micGain;
}

@property (nonatomic, retain) NSString *destinationFilePath;
@end
@implementation AudioRecorderManager

static AudioRecorderManager *audioRecorder = nil;
static dispatch_once_t onceToken;
static  AudioUnitRecorder *auRecorder;

AVAudioRecorder *avRecorder;

#if MIC_GAIN_ENABLED
dispatch_source_t micGageTimer;

dispatch_source_t createDispatchTimer(double interval, dispatch_queue_t queue, dispatch_block_t block)
{
    dispatch_source_t dispatchTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (dispatchTimer)
    {
        dispatch_source_set_timer(dispatchTimer,
                                  dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC),
                                  interval * NSEC_PER_SEC,
                                  (1ull * NSEC_PER_SEC) / 10);
        dispatch_source_set_event_handler(dispatchTimer, block);
        dispatch_resume(dispatchTimer);
    }
    return dispatchTimer;
}
#endif

+(id)SharedManager {
    dispatch_once(&onceToken, ^{
        audioRecorder = [[self alloc] init];
        auRecorder = [[AudioUnitRecorder alloc] init];
        //[auRecorder initializeAudioSession];
        
        //avRecorder = [[AVAudioRecorder alloc] init];
        //        [self createAudioReocrder];
    });
    return audioRecorder;
}
- (void)createAudioReocrder {
    //auRecorder = [[AudioUnitRecorder alloc] init];
}
- (void) startAudioRecording:(NSString*)fileName {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *destinationFilePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",fileName]];
    
    [auRecorder setFilePath:destinationFilePath];
    
#if MIC_GAIN_ENABLED
    // Create temporary file for AVAudioRecorder.
    destinationFilePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/temp.m4a"]];
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    avRecorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:destinationFilePath]
                                             settings:recordSetting
                                                error:NULL];
    avRecorder.meteringEnabled = YES;
    [avRecorder prepareToRecord];
#endif
    
    // Initiate and prepare the recorder
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                     withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                           error:nil];
    
}

-(void)startRecording{
    [auRecorder startRecording];
#if MIC_GAIN_ENABLED
    double secondsToFire = 0.005f;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        [avRecorder record];
    });
    
    micGageTimer = createDispatchTimer(secondsToFire, queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self micGageTimerAction];
        });
    });
#endif
}


- (void) stopAudioRecording {
    [auRecorder stopRecording];
#if MIC_GAIN_ENABLED
    [avRecorder stop];
    if (micGageTimer) {
        dispatch_source_cancel(micGageTimer);
        micGageTimer = nil;
    }
#endif
}

-(NSTimeInterval)currentTime {
    return avRecorder.currentTime;
}

- (NSString *) dateString{
    // return a formatted string for a file name
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"ddMMMYY_hhmmssa";
    return [formatter stringFromDate:[NSDate date]];
}
// Rename recorded file path with new name
-(NSString*)renameFileName:(NSString*)oldname withNewName:(NSString*)newname{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *oldPath = [documentsDirectory stringByAppendingPathComponent:oldname];
    newPath = [documentsDirectory stringByAppendingPathComponent:[newname stringByAppendingString:@".wav"]];
    
    NSFileManager *fileMan = [NSFileManager defaultManager];
    NSError *error = nil;
    
    if (![fileMan moveItemAtPath:oldPath toPath:newPath error:&error]){
        //DLog(@"Failed to move '%@' to '%@': %@", oldPath, newPath, [error localizedDescription]);
        
        return false;
    }
    //[self trimAudioFileWithInputFilePath:newPath toOutputFilePath:newPath];
    return newPath;
}

- (void)trimAudioFileWithInputFilePath :(NSString *)inputPath toOutputFilePath:(NSString *)outputPath
{
    // Path of your source audio file
    NSString *strInputFilePath = inputPath;
    NSURL *audioFileInput = [NSURL fileURLWithPath:strInputFilePath];
    
    // Path of trimmed file.
    NSString *strOutputFilePath = [outputPath stringByDeletingPathExtension];
    strOutputFilePath = [strOutputFilePath stringByAppendingString:@".m4a"];
    NSURL *audioFileOutput = [NSURL fileURLWithPath:strOutputFilePath];
    
    newPath = strOutputFilePath;
    if (!audioFileInput || !audioFileOutput)
    {
        //return NO;
    }
    
    [[NSFileManager defaultManager] removeItemAtURL:audioFileOutput error:NULL];
    AVAsset *asset = [AVAsset assetWithURL:audioFileInput];
    
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    
    if (exportSession == nil)
    {
        //return NO;
    }
    
    // Start time from which you want the audio file to be saved.
    float startTrimTime = 0.15;
    // End time till which you want the audio file to be saved.
    // For eg. your file's length.
    float endTrimTime = 13.0;
    
    CMTime startTime = CMTimeMake((int)(floor(startTrimTime * 100)), 100);
    CMTime stopTime = CMTimeMake((int)(ceil(endTrimTime * 100)), 100);
    CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime);
    
    exportSession.outputURL = audioFileOutput;
    exportSession.outputFileType = AVFileTypeAppleM4A;
    exportSession.timeRange = exportTimeRange;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^
     {
         if (AVAssetExportSessionStatusCompleted == exportSession.status)
         {
             DLog(@"Success!");
             
         }
         else if (AVAssetExportSessionStatusFailed == exportSession.status)
         {
             DLog(@"failed");
         }
     }];
}


// continuous timer action for mic gain
- (void)micGageTimerAction {
    [avRecorder updateMeters];
    peakPowerForChannel = pow(10, (0.05 * ([avRecorder peakPowerForChannel:0] + [avRecorder averagePowerForChannel:0])/2));
    
    micGain = (int)(peakPowerForChannel*100.0f);
    NSString *micGainString = [NSString stringWithFormat:@"%d",micGain];
    NSDictionary *dct = @{@"micGainValue":micGainString};
    //NSLog(@"%@ \n", micGainString);
    //    //NSLog(@"Average input: %f Peak input: %f", [recorder averagePowerForChannel:0], [recorder peakPowerForChannel:0]);
    if (avRecorder.isRecording) {
        //NSLog(@"mic gain input: %d", micGain);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateMicGain"
                                                            object:dct];
    }
}

-(BOOL)isRecording {
    return avRecorder.recording;
}


@end
