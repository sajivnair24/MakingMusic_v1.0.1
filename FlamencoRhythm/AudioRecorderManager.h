//
//  AudioRecorderManager.h
//  FlamencoRhythm
//
//  Created by intelliswift on 20/08/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioRecorderManager : NSObject{
    NSString *newPath;
}

+(id)SharedManager;
- (void) startAudioRecording:(NSString*)fileName;
- (void) startRecording;
- (void) stopAudioRecording;
-(NSTimeInterval)currentTime;
- (BOOL)isRecording;
-(NSString*)renameFileName:(NSString*)oldname withNewName:(NSString*)newname;
@end
