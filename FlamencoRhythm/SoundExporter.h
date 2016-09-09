//
//  SoundExporter.h
//  Making Music
//
//  Created by Nirma on 08/09/16.
//  Copyright © 2016 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <Accelerate/Accelerate.h>
#import "SoundParameters.h"
#include <AVFoundation/AVFoundation.h>

@protocol ExportFileDelegate <NSObject>

-(void)exportedFileUrl:(NSString*)url;
@optional
-(void)exportFileFailed;

@end

typedef struct AVAudioTapProcessorContext {
    
    float leftChannelVolume;
    float rightChannelVolume;
    
} AVAudioTapProcessorContext;

@interface SoundExporter : NSObject

@property (nonatomic, assign) id<ExportFileDelegate> delegate;
- (void)mixAudioFilesWithParams:(NSMutableArray*)soundParams
                    withTotalDuration:(float)totalAudioDuration
                  withRecordingString:(NSString *)recordingString
                             andTempo:(float)tempo;
@end
