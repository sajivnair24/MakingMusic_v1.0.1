//
//  SoundPlayManger.m
//  FlamencoRhythm
//
//  Created by Nirma on 09/03/16.
//  Copyright © 2016 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import "SoundPlayManger.h"
#import "MainNavigationViewController.h"
#import "SavedListDetailViewController.h"
#import "MultichannelMixerController.h"
#import "TimeStretcher.h"

#define SAMPLE_RATE 44100

@interface SoundPlayManger ()
{
    SavedListDetailViewController *listController;
    MultichannelMixerController *mixerController;
    TimeStretcher *timeStretcher;
    NSMutableArray* mixArray;
}

@end

@implementation SoundPlayManger
-(id)init{
    self = [super init];
    if (self) {
        sqlManager = [[DBManager alloc] init];
        mixerController = [[MultichannelMixerController alloc]init];
        listController = [[SavedListDetailViewController alloc]init];
        timeStretcher = [[TimeStretcher alloc]init];
    }
    return self;
   
}
-(void)setDataFromRecord:(RecordingListData *)data
              forSharing:(BOOL)isShared {
    RecordingListData *cellData = data;//[[RecordingListData alloc] init];
    rhythmRecord = [[RhythmClass alloc] init];
    
    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
    dataArray = [sqlManager fetchRhythmRecordsByID:[NSNumber numberWithInt:[cellData.rhythmID intValue]]];
    rhythmRecord = [dataArray objectAtIndex:0];
    
    _droneType =  [sqlManager getDroneLocationFromName:cellData.droneType];
    
    beatOneMusicFile = cellData.beat1;
    beatTwoMusicFile = cellData.beat2;
    
    clapFlag1 = [cellData.instOne intValue];
    clapFlag2 = [cellData.instTwo intValue];
    clapFlag3 = [cellData.instThree intValue];
    clapFlag4 = [cellData.instFour intValue];
    //volume leveles of each track
    
    instrV1 = [cellData.volOne floatValue];
    instrV2 = [cellData.volTwo floatValue];
    instrV3 = [cellData.volThree floatValue];
    instrV4 = [cellData.volFour floatValue];
    
    instrP1 = [cellData.panOne floatValue];
    instrP2 = [cellData.panTwo floatValue];
    instrP3 = [cellData.panThree floatValue];
    instrP4 = [cellData.panFour floatValue];
    
    tV1 = [cellData.volTrackOne floatValue];
    tV2 = [cellData.volTrackTwo floatValue];
    tV3 = [cellData.volTrackThree floatValue];
    tV4 = [cellData.volTrackFour floatValue];
    
    _recTrackOne = cellData.trackOne;
    _recTrackTwo = cellData.trackTwo;
    _recTrackThree = cellData.trackThree;
    _recTrackFour = cellData.trackFour;
    
    recFlag1 = [cellData.t1Flag intValue];
    recFlag2 = [cellData.t2Flag intValue];
    recFlag3 = [cellData.t3Flag intValue];
    recFlag4 = [cellData.t4Flag intValue];
    
    _startBPM = cellData.BPM;
    originalBPM = rhythmRecord.rhythmBPM;
    currentRythmName = cellData.recordingName;
    songDuration = [cellData.durationString floatValue];
    
    // For adjusting the tempo of audio files.
    [self trimRequiredAudioFiles:isShared];
    
    [self addStopSoundTimer:songDuration];
}

-(void)addStopSoundTimer:(float)timerTime{
    if (stopSoundTimer != nil) {
        [stopSoundTimer invalidate];
        stopSoundTimer =  nil;
    }
    stopSoundTimer = [NSTimer scheduledTimerWithTimeInterval:timerTime+1
                                                      target:self
                                                    selector:@selector(stopSound:)
                                                    userInfo:nil
                                                     repeats:NO];
    //[stopSoundTimer fire];
}

-(void)stopSound:(NSTimer *) timer{
    NSLog(@" timer stoped ");
    [timer invalidate];
        [self stopAllSound];
    [self.delegate soundStopped];

}
-(void)stopAllSound {
    if([stopSoundTimer isValid]) {
        [stopSoundTimer invalidate];
        stopSoundTimer = nil;
    }
    
    [mixerController stopAUGraph:YES];
}

- (void) playSelectedRecording:(RecordingListData *)data {
    [self setDataFromRecord:data forSharing:NO];
    NSString *fileLocation;
    NSString *volume;
    NSString *pan;
    NSDictionary *dct;
    
    audioPlayerArray = [[NSMutableArray alloc]init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *listItems = [beatOneMusicFile componentsSeparatedByString:@"/"];
    NSString *lastWordString = [NSString stringWithFormat:@"%@", listItems.lastObject];
    
    if (![beatOneMusicFile isEqualToString:@"-1"]) {
        fileLocation = [self locationOfFileWithName:lastWordString];
        if(clapFlag1 == 1) {
            if (instrV1 == 0)
                volume = [NSString stringWithFormat:@"%f",1/MAX_VOL];
            else
                volume = [NSString stringWithFormat:@"%f",instrV1/MAX_VOL];
        }else {
            volume = [NSString stringWithFormat:@"%d",0];
        }
        
        pan = [NSString stringWithFormat:@"%f",instrP1/MAX_VOL];
        
        dct = [self getTheDictionaryWithFileLocation:fileLocation
                                              volume:volume
                                                 pan:pan
                                                 bpm:originalBPM
                                         andStartBPM:_startBPM
                                            fileType:@""
                                    withRecordString:@"clap1"];
        [audioPlayerArray addObject:dct];
    }
    
    if (![beatTwoMusicFile isEqualToString:@"-1"]) {
        listItems = [beatTwoMusicFile componentsSeparatedByString:@"/"];
        lastWordString = [NSString stringWithFormat:@"%@", listItems.lastObject];
        fileLocation = [self locationOfFileWithName:lastWordString];
        //volume = playerVolume(clapFlag2);
        if(clapFlag2 == 1) {
            if (instrV2 == 0)
                volume = [NSString stringWithFormat:@"%f",1/MAX_VOL];
            else
                volume = [NSString stringWithFormat:@"%f",instrV2/MAX_VOL];
        }else {
            volume = [NSString stringWithFormat:@"%d",0];
        }
        
        pan = [NSString stringWithFormat:@"%f",instrP2/MAX_VOL];
        
        dct = [self getTheDictionaryWithFileLocation:fileLocation
                                              volume:volume
                                                 pan:pan
                                                 bpm:originalBPM
                                         andStartBPM:_startBPM
                                            fileType:@""
                                    withRecordString:@"clap2"];
        [audioPlayerArray addObject:dct];
    }
    
    fileLocation = [self getAbsoluteDocumentsPath:@"Click.m4a"];
    //volume = playerVolume(clapFlag2);
    if(clapFlag3 == 1) {
        if (instrV3 == 0)
            volume = [NSString stringWithFormat:@"%f",1/MAX_VOL];
        else
            volume = [NSString stringWithFormat:@"%f",instrV3/MAX_VOL];
    }else {
        volume = [NSString stringWithFormat:@"%d",0];
    }
    
    pan = [NSString stringWithFormat:@"%f",instrP3/MAX_VOL];
    
    dct = [self getTheDictionaryWithFileLocation:fileLocation
                                          volume:volume
                                             pan:pan
                                             bpm:originalBPM
                                     andStartBPM:_startBPM
                                        fileType:@"metronome"
                                withRecordString:@"clap3"];
    [audioPlayerArray addObject:dct];
    
    fileLocation = [self locationOfFileWithName:[NSString stringWithFormat:@"%@.m4a", _droneType]];
    //fileLocation = [self locationOfFileWithName:@"C.wav"];
    //volume = playerVolume(clapFlag2);
    if(clapFlag4 == 1) {
        if (instrV4 == 0)
            volume = [NSString stringWithFormat:@"%f",1/MAX_VOL];
        else
            volume = [NSString stringWithFormat:@"%f",instrV4/MAX_VOL];
    }else {
        volume = [NSString stringWithFormat:@"%d",0];
    }
    
    pan = [NSString stringWithFormat:@"%f",instrP4/MAX_VOL];
    
    dct = [self getTheDictionaryWithFileLocation:fileLocation
                                          volume:volume
                                             pan:pan
                                             bpm:originalBPM
                                     andStartBPM:_startBPM
                                        fileType:@""
                                withRecordString:@"clap4"];
    [audioPlayerArray addObject:dct];
    if (![_recTrackOne isEqualToString:@"-1"]) {
        fileLocation = [documentsDirectory stringByAppendingPathComponent:[_recTrackOne lastPathComponent]];
        //volume = playerVolume(clapFlag2);
        if(recFlag1 == 1)
        {
            if (tV1 == 0)
                volume = [NSString stringWithFormat:@"%f",1/MAX_VOL];
            else
                volume = [NSString stringWithFormat:@"%f",tV1/MAX_VOL];
        }
        else
            volume = [NSString stringWithFormat:@"%i",0];
        
        pan = [NSString stringWithFormat:@"%f",tP1/MAX_VOL];
        
        dct = [self getTheDictionaryWithFileLocation:fileLocation
                                              volume:volume
                                                 pan:pan
                                                 bpm:originalBPM
                                         andStartBPM:rhythmRecord.rhythmStartBPM
                                            fileType:@"Recorded"
                                    withRecordString:@"track1"];
        [audioPlayerArray addObject:dct];
    }
    
    if (![_recTrackTwo isEqualToString:@"-1"]) {
        fileLocation = [documentsDirectory stringByAppendingPathComponent:[_recTrackTwo lastPathComponent]];
        //volume = playerVolume(clapFlag2);
        if(recFlag2 == 1)
        {
            if (tV2 == 0)
                volume = [NSString stringWithFormat:@"%f",1/MAX_VOL];
            else
                volume = [NSString stringWithFormat:@"%f",tV2/MAX_VOL];
        }
        else
            volume = [NSString stringWithFormat:@"%i",0];
        
        pan = [NSString stringWithFormat:@"%f",tP2/MAX_VOL];
        
        dct = [self getTheDictionaryWithFileLocation:fileLocation
                                              volume:volume
                                                 pan:pan
                                                 bpm:originalBPM
                                         andStartBPM:rhythmRecord.rhythmStartBPM
                                            fileType:@"Recorded"
                                    withRecordString:@"track2"];
        [audioPlayerArray addObject:dct];
    }
    
    if (![_recTrackThree isEqualToString:@"-1"]) {
        fileLocation = [documentsDirectory stringByAppendingPathComponent:[_recTrackThree lastPathComponent]];
        //volume = playerVolume(clapFlag2);
        if(recFlag3 == 1)
        {
            if (tV3 == 0)
                volume = [NSString stringWithFormat:@"%f",1/MAX_VOL];
            else
                volume = [NSString stringWithFormat:@"%f",tV3/MAX_VOL];
        }
        else
            volume = [NSString stringWithFormat:@"%i",0];
        
        pan = [NSString stringWithFormat:@"%f",tP3/MAX_VOL];
        
        dct = [self getTheDictionaryWithFileLocation:fileLocation
                                              volume:volume
                                                 pan:pan
                                                 bpm:originalBPM
                                         andStartBPM:rhythmRecord.rhythmStartBPM
                                            fileType:@"Recorded"
                                    withRecordString:@"track3"];
        [audioPlayerArray addObject:dct];
        
    }
    
    if (![_recTrackFour isEqualToString:@"-1"]) {
        fileLocation = [documentsDirectory stringByAppendingPathComponent:[_recTrackFour lastPathComponent]];
        //volume = playerVolume(clapFlag2);
        if(recFlag4 == 1)
        {
            if (tV4 == 0)
                volume = [NSString stringWithFormat:@"%f",1/MAX_VOL];
            else
                volume = [NSString stringWithFormat:@"%f",tV4/MAX_VOL];
        }
        else
            volume = [NSString stringWithFormat:@"%i",0];
        
        pan = [NSString stringWithFormat:@"%f",tP4/MAX_VOL];
        
        dct = [self getTheDictionaryWithFileLocation:fileLocation
                                              volume:volume
                                                 pan:pan
                                                 bpm:originalBPM
                                         andStartBPM:rhythmRecord.rhythmStartBPM
                                            fileType:@"Recorded"
                                    withRecordString:@"track4"];
        [audioPlayerArray addObject:dct];
    }
    
    //audioUnitCount = (UInt32)audioPlayerArray.count;
    [mixerController stopAUGraph:YES];
    [mixerController fillBuffers:audioPlayerArray andNumberOfBus:(unsigned)audioPlayerArray.count];
    [mixerController initializeAUGraph];
    
    for (int i = 0; i <audioPlayerArray.count; i++) {
        NSDictionary *dict = [audioPlayerArray objectAtIndex:i];
        [mixerController setInputVolume:(unsigned)i value:(Float32)[[dict valueForKey:@"volume"] floatValue]];
        [mixerController setPanPosition:(unsigned)i value:(Float32)[[dict valueForKey:@"pan"] floatValue]];
    }
    
    [mixerController initializeAudioForMetronome];
    
    [self performSelector:@selector(startAUGraphVC) withObject:self afterDelay:1.0];
}

- (NSString *)loadFilesForMixingAndSharing:(RecordingListData *)data {
    [self setDataFromRecord:data forSharing:YES];
    NSString *fileLocation;
    
    mixArray = [[NSMutableArray alloc]init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *listItems = [beatOneMusicFile componentsSeparatedByString:@"/"];
    NSString *lastWordString = [NSString stringWithFormat:@"%@", listItems.lastObject];
    
    if (![beatOneMusicFile isEqualToString:@"-1"]) {
        fileLocation = [MainNavigationViewController getAbsDocumentsPath:@"Beats"];
        fileLocation = [NSString stringWithFormat:@"%@/%@", fileLocation, lastWordString];
        
        [mixArray addObject:[self getFilePathWithFormat:fileLocation
                                                withKey:@"loopTrack"]];
    }
    
    if (![beatTwoMusicFile isEqualToString:@"-1"]) {
        listItems = [beatTwoMusicFile componentsSeparatedByString:@"/"];
        lastWordString = [NSString stringWithFormat:@"%@", listItems.lastObject];
        
        fileLocation = [MainNavigationViewController getAbsDocumentsPath:@"Beats"];
        fileLocation = [NSString stringWithFormat:@"%@/%@", fileLocation, lastWordString];
        
        [mixArray addObject:[self getFilePathWithFormat:fileLocation
                                                withKey:@"loopTrack"]];
    }
    
    fileLocation = [self getAbsoluteDocumentsPath:@"Click.m4a"];
    [mixArray addObject:[self getFilePathWithFormat:fileLocation
                                            withKey:@"loopTrack"]];
    
    fileLocation = [self locationOfFileWithName:[NSString stringWithFormat:@"%@.m4a", _droneType]];
    [mixArray addObject:[self getFilePathWithFormat:fileLocation
                                            withKey:@"loopTrack"]];
    
    if (![_recTrackOne isEqualToString:@"-1"]) {
        fileLocation = [documentsDirectory stringByAppendingPathComponent:[_recTrackOne lastPathComponent]];
        [mixArray addObject:[self getFilePathWithFormat:fileLocation
                                                withKey:@"recording"]];
    }
    
    if (![_recTrackTwo isEqualToString:@"-1"]) {
        fileLocation = [documentsDirectory stringByAppendingPathComponent:[_recTrackTwo lastPathComponent]];
        [mixArray addObject:[self getFilePathWithFormat:fileLocation
                                                withKey:@"recording"]];
    }
    
    if (![_recTrackThree isEqualToString:@"-1"]) {
        fileLocation = [documentsDirectory stringByAppendingPathComponent:[_recTrackThree lastPathComponent]];
        [mixArray addObject:[self getFilePathWithFormat:fileLocation
                                                withKey:@"recording"]];
    }
    
    if (![_recTrackFour isEqualToString:@"-1"]) {
        fileLocation = [documentsDirectory stringByAppendingPathComponent:[_recTrackFour lastPathComponent]];
        [mixArray addObject:[self getFilePathWithFormat:fileLocation
                                                withKey:@"recording"]];
    }
    
    NSString *mergeOutputPath = [listController mixAudioFiles:mixArray
                                            withTotalDuration:songDuration
                                          withRecordingString:currentRythmName];
    
    NSString *beatsDirectory = [MainNavigationViewController getAbsDocumentsPath:@"Beats"];
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:beatsDirectory]) {
        [[NSFileManager defaultManager] removeItemAtPath:beatsDirectory error:nil];
    }
    
    return mergeOutputPath;
}

-(void)startAUGraphVC{
     [mixerController startAUGraph];
}
- (NSString*)locationOfFileWithName:(NSString*)fileName{
    NSArray* array = [fileName componentsSeparatedByString:@"/"];
    NSString *beatFilePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], array.lastObject];
    
    //    beatFilePath = [beatFilePath stringByReplacingOccurrencesOfString:@"m4a"
    //                                                           withString:@"wav"];
    return beatFilePath;
}
- (NSDictionary*)getTheDictionaryWithFileLocation:(NSString*)locaiton
                                           volume:(NSString*)volume
                                              pan:(NSString*)pan
                                              bpm:(NSNumber*)rhythmBpmValue
                                      andStartBPM:(NSNumber *)rhythmStartBPMValue
                                         fileType:(NSString*)type
                                 withRecordString:(NSString *)recordedString{
    return @{
             @"fileLocation":locaiton,
             @"volume":volume,
             @"pan":pan,
             @"bpm":rhythmBpmValue,
             @"startbpm":rhythmStartBPMValue,
             @"type":type,
             @"recorded":recordedString
             };
}

- (NSString *)getFilePathWithFormat:(NSString *)filePath withKey:(NSString *)key {
    return [NSString stringWithFormat:@"%@:%@", key, filePath];
}

- (NSString *)getAbsoluteDocumentsPath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName];
}

- (void)trimRequiredAudioFiles:(BOOL)isShared {
    
    if(isShared) {
        float tempo = [_startBPM floatValue]/[originalBPM floatValue];
        
        NSArray *beatOneItems = [beatOneMusicFile componentsSeparatedByString:@"/"];
        NSString *beatOne = [NSString stringWithFormat:@"%@", beatOneItems.lastObject];
        
        NSArray *beatTwoItems = [beatTwoMusicFile componentsSeparatedByString:@"/"];
        NSString *beatTwo = [NSString stringWithFormat:@"%@", beatTwoItems.lastObject];
        
        beatOne = [MainNavigationViewController getAbsBundlePath:beatOne];
        NSString *beatOneTimeStretched = [MainNavigationViewController getAbsDocumentsPath:@"Beats"];
        
        BOOL isDir;
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:beatOneTimeStretched isDirectory:&isDir]) {
            if(![[NSFileManager defaultManager] createDirectoryAtPath:beatOneTimeStretched
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:NULL])
                NSLog(@"Error: Folder creation failed %@", beatOneTimeStretched);
        }
        
        beatOneTimeStretched = [NSString stringWithFormat:@"%@/%@", beatOneTimeStretched, beatOneItems.lastObject];
        
        [timeStretcher timeStretchAndConvert:beatOne
                              withOutputFile:beatOneTimeStretched
                                   withTempo:tempo];
        
        beatTwo = [MainNavigationViewController getAbsBundlePath:beatTwo];
        NSString *beatTwoTimeStretched = [MainNavigationViewController getAbsDocumentsPath:@"Beats"];
        beatTwoTimeStretched = [NSString stringWithFormat:@"%@/%@", beatTwoTimeStretched, beatTwoItems.lastObject];
        
        [timeStretcher timeStretchAndConvert:beatTwo
                              withOutputFile:beatTwoTimeStretched
                                   withTempo:tempo];
        
        // Trim code
        NSString *beatOnePath = beatOneTimeStretched;
        beatOnePath = [beatOnePath stringByDeletingPathExtension];
        beatOnePath = [beatOnePath stringByAppendingPathExtension:@"wav"];
        
        NSString *beatTwoPath = beatTwoTimeStretched;
        beatTwoPath = [beatTwoPath stringByDeletingPathExtension];
        beatTwoPath = [beatTwoPath stringByAppendingPathExtension:@"wav"];
        
        [self trimAudioFileInputFilePath:beatOnePath toOutputFilePath:beatOneTimeStretched];
        [self trimAudioFileInputFilePath:beatTwoPath toOutputFilePath:beatTwoTimeStretched];
        
        [NSThread sleepForTimeInterval:0.5];
    }
    
    [self trimMetronomeFile];
}

- (void)trimMetronomeFile {
    [MainNavigationViewController trimClickFile:[_startBPM floatValue]];
    [NSThread sleepForTimeInterval:0.1];
}

- (void)trimAudioFileInputFilePath:(NSString *)inputPath
                  toOutputFilePath:(NSString *)outputPath {
    
    NSError *error;
    
    // Path of your source audio file
    NSString *strInputFilePath = inputPath;
    NSURL *audioFileInput = [NSURL fileURLWithPath:strInputFilePath];
    
    // Path of trimmed file.
    float startTrimTime;
    float endTrimTime;
    NSURL *audioFileOutput = [NSURL fileURLWithPath:outputPath];
    
    if (!audioFileInput || !audioFileOutput){
        //return NO;
    }
    
    [[NSFileManager defaultManager] removeItemAtURL:audioFileOutput error:NULL];
    AVAsset *asset = [AVAsset assetWithURL:audioFileInput];
    CMTime audioDuration = asset.duration;
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    
    if (exportSession == nil){
        //return;
    }
    
    float tempo = [_startBPM floatValue]/[originalBPM floatValue];
    //startTrimTime = 0.0525/tempo;
    
    //startTrimTime = 0.0480/tempo;
    
    //[self processAudio:audioDurationSeconds withFilePathURL:audioFileInput];
    // End time till which you want the audio file to be saved.
    // For eg. your file's length.
    if(tempo == 1.0f) {
        startTrimTime = 0.0480;
        endTrimTime = audioDurationSeconds - 0.0202;
    }
    else {
        startTrimTime = 0.0480/tempo - 0.0055;
        //startTrimTime = (0.0480 - 0.0055)/tempo;
        endTrimTime = audioDurationSeconds;
    }
    
    CMTime startTime = CMTimeMake((int)(floor(startTrimTime * SAMPLE_RATE)), SAMPLE_RATE);
    CMTime stopTime = CMTimeMake((int)(ceil(endTrimTime * SAMPLE_RATE)), SAMPLE_RATE);
    CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime);
    
    exportSession.outputURL = audioFileOutput;
    exportSession.outputFileType = AVFileTypeAppleM4A;
    exportSession.timeRange = exportTimeRange;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^
     {
         if (AVAssetExportSessionStatusCompleted == exportSession.status)
         {
             NSLog(@"Success!");
         }
         else if (AVAssetExportSessionStatusFailed == exportSession.status)
         {
             NSLog(@"failed");
         }
     }];
    
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:inputPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:inputPath error:&error];
    }
}

@end
