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
#import "Constants.h"

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioFilePlayedOnce:) name:@"AUDIOFILENOTLOOPING" object:nil];
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
    
    tP1 = [cellData.panTrackOne floatValue];
    tP2 = [cellData.panTrackTwo floatValue];
    tP3 = [cellData.panTrackThree floatValue];
    tP4 = [cellData.panTrackFour floatValue];
    
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
    //NSLog(@" timer stoped ");
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
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

-(void)audioFilePlayedOnce:(NSNotification *)sender{
    NSDictionary *dict = (NSDictionary *)sender.object;
    [mixerController enableInput:(UInt32)[dict[@"BUSNUMBER"] intValue] isOn:0.0];
}

- (void) playSelectedRecording:(RecordingListData *)data {
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
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

- (void)loadFilesForMixingAndSharing:(RecordingListData *)data {
    [self setDataFromRecord:data forSharing:YES];
    NSString *fileLocation;
    
    mixArray = [[NSMutableArray alloc]init];
    float tempo = [_startBPM floatValue]/[originalBPM floatValue];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *listItems = [beatOneMusicFile componentsSeparatedByString:@"/"];
    NSString *lastWordString = [NSString stringWithFormat:@"%@", listItems.lastObject];
    
    if (![beatOneMusicFile isEqualToString:@"-1"]) {
        if(clapFlag1 == 1) {
            
            if(tempo == 1.0f) {
                fileLocation = [self getAbsoluteBundlePath:lastWordString];
            } else {
                fileLocation = [self getAbsoluteDocumentsPath:@"Beats"];
                fileLocation = [NSString stringWithFormat:@"%@/%@", fileLocation, lastWordString];
            }
            
            [mixArray addObject:[self getFilePathWithFormat:fileLocation
                                                    withKey:@"loopTrack"]];
        }
    }
    
    if (![beatTwoMusicFile isEqualToString:@"-1"]) {
        if(clapFlag2 == 1) {
            listItems = [beatTwoMusicFile componentsSeparatedByString:@"/"];
            lastWordString = [NSString stringWithFormat:@"%@", listItems.lastObject];
            
            if(tempo == 1.0f) {
                fileLocation = [self getAbsoluteBundlePath:lastWordString];
            } else {
                fileLocation = [self getAbsoluteDocumentsPath:@"Beats"];
                fileLocation = [NSString stringWithFormat:@"%@/%@", fileLocation, lastWordString];
            }
            
            [mixArray addObject:[self getFilePathWithFormat:fileLocation
                                                    withKey:@"loopTrack"]];
        }
    }
    
    if(clapFlag3 == 1) {
        fileLocation = [self getAbsoluteDocumentsPath:@"Click.m4a"];
        [mixArray addObject:[self getFilePathWithFormat:fileLocation
                                                withKey:@"Metronome"]];
    }
    
    if(clapFlag4 == 1) {
        fileLocation = [self locationOfFileWithName:[NSString stringWithFormat:@"%@.m4a", _droneType]];
        [mixArray addObject:[self getFilePathWithFormat:fileLocation
                                                withKey:@"loopTrack"]];
    }
    
    if (![_recTrackOne isEqualToString:@"-1"]) {
        if(recFlag1 == 1) {
            fileLocation = [documentsDirectory stringByAppendingPathComponent:[_recTrackOne lastPathComponent]];
            [mixArray addObject:[self getFilePathWithFormat:fileLocation
                                                    withKey:@"recording"]];
        }
    }
    
    if (![_recTrackTwo isEqualToString:@"-1"]) {
        if(recFlag2 == 1) {
            fileLocation = [documentsDirectory stringByAppendingPathComponent:[_recTrackTwo lastPathComponent]];
            [mixArray addObject:[self getFilePathWithFormat:fileLocation
                                                    withKey:@"recording"]];
        }
    }
    
    if (![_recTrackThree isEqualToString:@"-1"]) {
        if(recFlag3 == 1) {
            fileLocation = [documentsDirectory stringByAppendingPathComponent:[_recTrackThree lastPathComponent]];
            [mixArray addObject:[self getFilePathWithFormat:fileLocation
                                                    withKey:@"recording"]];
        }
    }
    
    if (![_recTrackFour isEqualToString:@"-1"]) {
        if(recFlag4 == 1) {
            fileLocation = [documentsDirectory stringByAppendingPathComponent:[_recTrackFour lastPathComponent]];
            [mixArray addObject:[self getFilePathWithFormat:fileLocation
                                                    withKey:@"recording"]];
        }
    }
    
    if([mixArray count] == 0) {
        [self.delegate tracksMuted];
        return ;
    }
    //  NSString *mergeOutputPath =
  [self mixAudioFiles:mixArray
        withTotalDuration:songDuration
        withRecordingString:currentRythmName
                andTempo:tempo];
    
    
    //return mergeOutputPath;
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
- (NSDictionary*)getTheDictionaryWithFileLocation:(NSString *)locaiton
                                           volume:(NSString *)volume
                                              pan:(NSString *)pan
                                              bpm:(NSNumber *)rhythmBpmValue
                                      andStartBPM:(NSNumber *)rhythmStartBPMValue
                                         fileType:(NSString *)type
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

- (NSString *)getAbsoluteBundlePath:(NSString *)fileName {
    return [MainNavigationViewController getAbsBundlePath:fileName];
}

- (NSString *)getAbsoluteDocumentsPath:(NSString *)fileName {
    return [MainNavigationViewController getAbsDocumentsPath:fileName];
}

- (void)trimRequiredAudioFiles:(BOOL)isShared {
    
    if(isShared) {
        float tempo = [_startBPM floatValue]/[originalBPM floatValue];
        
        NSArray *beatOneItems = [beatOneMusicFile componentsSeparatedByString:@"/"];
        NSString *beatOne = [NSString stringWithFormat:@"%@", beatOneItems.lastObject];
        
        NSArray *beatTwoItems = [beatTwoMusicFile componentsSeparatedByString:@"/"];
        NSString *beatTwo = [NSString stringWithFormat:@"%@", beatTwoItems.lastObject];
        
        beatOne = [self getAbsoluteBundlePath:beatOne];
        NSString *beatOneTimeStretched = [self getAbsoluteDocumentsPath:@"Beats"];
        
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
        
        beatTwo = [self getAbsoluteBundlePath:beatTwo];
        NSString *beatTwoTimeStretched = [self getAbsoluteDocumentsPath:@"Beats"];
        beatTwoTimeStretched = [NSString stringWithFormat:@"%@/%@", beatTwoTimeStretched, beatTwoItems.lastObject];
        
        [timeStretcher timeStretchAndConvert:beatTwo
                              withOutputFile:beatTwoTimeStretched
                                   withTempo:tempo];
        
        // Trim code
        NSString *beatOnePath = beatOneTimeStretched;
        
        NSString *bundlePath = [self getAbsoluteBundlePath:[beatOneMusicFile lastPathComponent]];
        
        AVURLAsset *bundleAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:bundlePath]
                                                         options:nil];
        
        CMTime bundleAssetDuration = bundleAsset.duration;
        float bundleAssetDurationSeconds = CMTimeGetSeconds(bundleAssetDuration);

        beatOnePath = [beatOnePath stringByDeletingPathExtension];
        beatOnePath = [beatOnePath stringByAppendingPathExtension:@"wav"];
        
        AVURLAsset *assetAfterTimeStretching = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:beatOnePath]
                                                         options:nil];
        
        CMTime assetAfterTimeStretchingDuration = assetAfterTimeStretching.duration;
        float assetAfterTimeStretchingDurationSeconds = CMTimeGetSeconds(assetAfterTimeStretchingDuration);
        
        float durationToBeRemoved = bundleAssetDurationSeconds/tempo - assetAfterTimeStretchingDurationSeconds;
        
        NSString *beatTwoPath = beatTwoTimeStretched;
        beatTwoPath = [beatTwoPath stringByDeletingPathExtension];
        beatTwoPath = [beatTwoPath stringByAppendingPathExtension:@"wav"];
        
        [self trimAudioFileInputFilePath:beatOnePath toOutputFilePath:beatOneTimeStretched withStartTrimTime:durationToBeRemoved];
        [self trimAudioFileInputFilePath:beatTwoPath toOutputFilePath:beatTwoTimeStretched withStartTrimTime:durationToBeRemoved];
        
        [NSThread sleepForTimeInterval:0.5];
    }
    
    [self trimMetronomeFile];
}

- (void)trimMetronomeFile {
    [MainNavigationViewController trimClickFile:[_startBPM floatValue]];
    [NSThread sleepForTimeInterval:0.1];
}

- (void)trimAudioFileInputFilePath:(NSString *)inputPath
                  toOutputFilePath:(NSString *)outputPath
                 withStartTrimTime:(float)startTrimTime {
    
    NSError *error;
    
    // Path of your source audio file
    NSString *strInputFilePath = inputPath;
    NSURL *audioFileInput = [NSURL fileURLWithPath:strInputFilePath];
    
    // Path of trimmed file.
    //float startTrimTime;
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
//    if(tempo == 1.0f) {
//        startTrimTime = 0.0480;
//        endTrimTime = audioDurationSeconds - 0.0202;
//    }
//    else {
//        startTrimTime = 0.0480/tempo - 0.0055;
//        //startTrimTime = (0.0480 - 0.0055)/tempo;
//        endTrimTime = audioDurationSeconds;
//    }
    
    endTrimTime = audioDurationSeconds;
    
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
             //NSLog(@"Success!");
         }
         else if (AVAssetExportSessionStatusFailed == exportSession.status)
         {
             //NSLog(@"failed");
         }
     }];
    
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:inputPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:inputPath error:&error];
    }
}

-(void)trimAndConvertRecordedWavFileToM4A:(NSString*)waveFilePath{
    NSString *m4AOutPutFilePath = [waveFilePath stringByDeletingPathExtension];
     m4AOutPutFilePath = [m4AOutPutFilePath stringByAppendingString:@".m4a"];
    
     NSURL *audioFileOutput = [NSURL fileURLWithPath:m4AOutPutFilePath];
    
    
     NSURL *audioFileInput = [NSURL fileURLWithPath:waveFilePath];
    AVAsset *asset = [AVAsset assetWithURL:audioFileInput];
    CMTime audioDuration = asset.duration;
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    [[NSFileManager defaultManager] removeItemAtURL:audioFileOutput error:NULL];
     AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    
    float startTrimTime;
    float endTrimTime;
    
    if([MainNavigationViewController isIPhoneOlderThanVersion6])
        startTrimTime = 0.117;
    else
        startTrimTime = 0.15;
    // End time till which you want the audio file to be saved.
    // For eg. your file's length.
    endTrimTime = audioDurationSeconds;
  
    
    CMTime startTime = CMTimeMake((int)(floor(startTrimTime * 44100)), 44100);
    CMTime stopTime = CMTimeMake((int)(ceil(endTrimTime * 44100)), 44100);
    CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime);
    
    exportSession.outputURL = audioFileOutput;
    exportSession.outputFileType = AVFileTypeAppleM4A;
    exportSession.timeRange = exportTimeRange;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^
     {
        [self.delegate wavConvertedIntoM4A];
         if (AVAssetExportSessionStatusCompleted == exportSession.status)
         {
            
                 
                 
                 NSFileManager *fileManager = [NSFileManager defaultManager];
                 if ([fileManager fileExistsAtPath:waveFilePath]) {
                     [fileManager removeItemAtPath:waveFilePath error:nil];
                 }
            
             
                 
             
         }
         else if (AVAssetExportSessionStatusFailed == exportSession.status)
         {
             // NSLog(@"failed");
         }
     }];

}
-(void)mixAudioFiles:(NSMutableArray*)audioFileURLArray
       withTotalDuration:(float)totalAudioDuration
       withRecordingString:(NSString *)recordingString
       andTempo:(float)tempo{
    
    NSError* error = nil;
    NSString *outputFile;
    
    AVURLAsset* fileAsset;
    NSArray *fileAssetDetails;
    AVAssetExportSession* exportSession;
    AVMutableCompositionTrack* audioTrack;
    
    int length = (int)[audioFileURLArray count];
    
    AVMutableComposition* composition = [AVMutableComposition composition];
    
    // Get the maximum duration of files to be mixed.
    CMTime maxDuration = [self getMaxAudioAssetDuration:audioFileURLArray withTotalAudioDuration:totalAudioDuration];
    
    for(int i = 0; i < length; i++) {
        
        audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                              preferredTrackID:kCMPersistentTrackID_Invalid];
        
        fileAssetDetails = [[audioFileURLArray objectAtIndex:i] componentsSeparatedByString: @":"];
        
        fileAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:[fileAssetDetails objectAtIndex:1]]
                                            options:nil];
        
        // If not recordings.
        if(![[fileAssetDetails objectAtIndex:0] isEqualToString:@"recording"]) {
            if(CMTimeCompare(maxDuration, fileAsset.duration) == 1 || CMTimeCompare(maxDuration, fileAsset.duration) == 0 ){
                CMTime currTime = kCMTimeZero;
                CMTime audioDuration = fileAsset.duration;
                
                if(![[fileAssetDetails objectAtIndex:0] isEqualToString:@"Metronome"]) {
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
            DLog(@"file asset duration = %f" ,CMTimeGetSeconds(fileAsset.duration) );
            DLog(@"file asset Track value = %@ " ,[fileAsset tracksWithMediaType:AVMediaTypeAudio] );
            DLog(@"file asset Track = %@  " ,[[fileAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] );
            
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, fileAsset.duration)
                                ofTrack:[[fileAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                 atTime:kCMTimeZero
                                  error:&error];
        }
    }
    
    exportSession = [AVAssetExportSession exportSessionWithAsset:composition
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
    
    outputFile = [dataPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.m4a", recordingString]];
    
    exportSession.outputURL = [NSURL fileURLWithPath:outputFile];
    exportSession.outputFileType = AVFileTypeAppleM4A;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        
        // export status changed, check to see if it's done, errored, waiting, etc
        NSString *beatsDirectory = [self getAbsoluteDocumentsPath:@"Beats"];
        if ([[NSFileManager defaultManager] isDeletableFileAtPath:beatsDirectory]) {
            [[NSFileManager defaultManager] removeItemAtPath:beatsDirectory error:nil];
        }

        switch (exportSession.status)
        {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"#### Failed\n");
                [self.delegate trackExportedFailed];
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"### Success\n");
                [self.delegate trackExportedWithUrl:outputFile];
                break;
            case AVAssetExportSessionStatusWaiting:
                [self.delegate trackExportedFailed];
                break;
            default:
                break;
        }
    }];
    
    
}
- (CMTime)getMaxAudioAssetDuration:(NSMutableArray*)audioFileURLArray withTotalAudioDuration:(float)totalAudioDuration {
    AVURLAsset* fileAsset;
    NSArray *fileAssetDetails;
    CMTime maxDuration  = kCMTimeZero;
    CMTime lastDuration = kCMTimeZero;
    
    int length = (int)[audioFileURLArray count];
    
    for(int i = 0; i < length; i++) {
        fileAssetDetails = [[audioFileURLArray objectAtIndex:i] componentsSeparatedByString: @":"];
        
        fileAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:[fileAssetDetails objectAtIndex:1]]
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

@end
