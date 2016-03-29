//
//  AudioUnitRecorder.m
//  AudioUnitPlayer
//
//  Created by Sajiv Nair on 02/07/15.
//  Copyright (c) 2015 intelliswift. All rights reserved.
//

#import "AudioUnitRecorder.h"
#import <AudioToolbox/AudioSession.h>
#import <AudioUnit/AUComponent.h>
#import <AudioUnit/AudioUnitProperties.h>
#import <AudioUnit/AudioOutputUnit.h>

@implementation AudioUnitRecorder {
    AudioComponentInstance      mAudioUnit;
    ExtAudioFileRef             mAudioFileRef;
    InMemoryAudioFile           *inMemoryAudioFile;
    AudioStreamBasicDescription mAudioFormat;

}

OSStatus recordCallback(void                              *inRefCon,
                        AudioUnitRenderActionFlags        *ioActionFlags,
                        const AudioTimeStamp              *inTimeStamp,
                        UInt32                            inBusNumber,
                        UInt32                            inNumberFrames,
                        AudioBufferList                   *ioData){
    
    AudioBufferList bufferList;
    UInt16 numSamples=inNumberFrames*kChannels;
    UInt16 samples[numSamples];
    memset (&samples, 0, sizeof (samples));
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = samples;
    bufferList.mBuffers[0].mNumberChannels = kChannels;
    bufferList.mBuffers[0].mDataByteSize = numSamples*sizeof(UInt16);
    AudioUnitRecorder* this = (__bridge AudioUnitRecorder *)inRefCon;
    CheckError(AudioUnitRender(this->mAudioUnit,
                               ioActionFlags,
                               inTimeStamp,
                               kInputBus,
                               inNumberFrames,
                               &bufferList),"AudioUnitRender failed");
        ExtAudioFileWriteAsync(this->mAudioFileRef, inNumberFrames, &bufferList);
    
    
//    UInt32 ui32propSize = sizeof(UInt32);
//    UInt32 f32propSize = sizeof(Float32);
//    UInt32 inputGainAvailable = 0;
////
////    OSStatus err =
////    AudioSessionGetProperty(kAudioSessionProperty_InputGainAvailable
////                            , &ui32propSize
////                            , &inputGainAvailable);
////    
////    
//    AudioSessionGetProperty(kAudioSessionProperty_InputGainScalar
//                            , &f32propSize
//                            , &inputGainAvailable);
//    
//    NSLog(@"Input Gain = %d",inputGainAvailable);
//    double timeInSeconds = inTimeStamp->mSampleTime / 44100;
//
//
//    
//        printf("\n%fs inBusNumber: %u inNumberFrames: %u ", inTimeStamp->mSampleTime, (unsigned int)inBusNumber, (unsigned int)inNumberFrames);
//    AudioBuffer audioBuffer = bufferList.mBuffers [0];
//    int bufferSize = audioBuffer.mDataByteSize / sizeof(Float32);
//    
//    // the data type, SInt32, determines
//    // the type the data will be returned in.
//    SInt32 *frame = audioBuffer.mData;
//    
//    for ( int i = 0; i < bufferSize; i++ ){
//        SInt32 currentSample = frame [ i ];
//        printf("%d\n", currentSample);
//    }
    
    return noErr;
}

static void CheckError(OSStatus error,const char *operaton){
    if (error==noErr) {
        return;
    }
    char errorString[20]={};
    *(UInt32 *)(errorString+1)=CFSwapInt32HostToBig(error);
    if (isprint(errorString[1])&&isprint(errorString[2])&&isprint(errorString[3])&&isprint(errorString[4])) {
        errorString[0]=errorString[5]='\'';
        errorString[6]='\0';
    }else{
        sprintf(errorString, "%d",(int)error);
    }
    fprintf(stderr, "Error:%s (%s)\n",operaton,errorString);
    exit(1);
}

void routeChangeListener1( void                      *inClientData,
                           AudioSessionPropertyID    inID,
                           UInt32                    inDataSize,
                           const void                *inData) {
    
    
    //trigger event
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AUDIOROUTECHANGE" object:nil ];
    //printf("audioRouteChangeListener");
}



void interruptionListener1(void *inClientData,UInt32 inInterruptionState){
    switch (inInterruptionState) {
        case kAudioSessionBeginInterruption:
            break;
        case kAudioSessionEndInterruption:
            break;
        default:
            break;
    }
}



-(void)initializeAudioSession{
 CheckError(AudioSessionInitialize(NULL, kCFRunLoopDefaultMode, interruptionListener1, (__bridge void *)(self)), "couldn't initialize the audio session");
   CheckError(AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, routeChangeListener1, (__bridge void *)(self)),"couldn't add a route change listener");
   
}

-(void)configAudio {
    
    //Is there an audio input device available
    UInt32 inputAvailable;
    UInt32 propSize=sizeof(inputAvailable);
    CheckError(AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &propSize, &inputAvailable), "not available for the current input audio device");
    if (!inputAvailable) {
        return;
    }
    
    //Adjust audio hardware I/O buffer duration.If I/O latency is critical in your app, you can request a smaller duration.
    Float32 ioBufferDuration = .100;
    CheckError(AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(ioBufferDuration), &ioBufferDuration),"couldn't set the buffer duration on the audio session");
    
    //Set the audio category
    UInt32 audioCategory = kAudioSessionCategory_RecordAudio;
    CheckError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory), "couldn't set the category on the audio session");
    
//    UInt32 override=true;
//    AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(override), &override);
    
    UInt32 overrid = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(overrid), &overrid);
    
    //Get hardware sample rate and setting the audio format
    Float64 sampleRate;
    UInt32 sampleRateSize=sizeof(sampleRate);
    CheckError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &sampleRateSize, &sampleRate),                                      "Couldn't get hardware samplerate");
    mAudioFormat.mSampleRate         = sampleRate;
    mAudioFormat.mFormatID           = kAudioFormatLinearPCM; //kAudioFormatMPEG4AAC
    mAudioFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;  // kMPEG4Object_AAC_Main
    mAudioFormat.mFramesPerPacket    = 1;
    mAudioFormat.mChannelsPerFrame   = kChannels;
    mAudioFormat.mBitsPerChannel     = 16;
    mAudioFormat.mBytesPerFrame      = mAudioFormat.mBitsPerChannel*mAudioFormat.mChannelsPerFrame/8;
    mAudioFormat.mBytesPerPacket     = mAudioFormat.mBytesPerFrame*mAudioFormat.mFramesPerPacket;
    mAudioFormat.mReserved           = 0;
    
    //Obtain a RemoteIO unit instance
    AudioComponentDescription acd;
    acd.componentType = kAudioUnitType_Output;
    acd.componentSubType = kAudioUnitSubType_RemoteIO;
    acd.componentFlags = 0;
    acd.componentFlagsMask = 0;
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &acd);
    CheckError(AudioComponentInstanceNew(inputComponent, &mAudioUnit), "Couldn't new AudioComponent instance");
    
    //The Remote I/O unit, by default, has output enabled and input disabled
    //Enable input scope of input bus for recording.
    UInt32 enable = 1;
    UInt32 disable=0;
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Input,
                                    kInputBus,
                                    &enable,
                                    sizeof(enable)),
                                    "kAudioOutputUnitProperty_EnableIO::kAudioUnitScope_Input::kInputBus");
    
    //Apply format to output scope of input bus for recording.
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    kInputBus,
                                    &mAudioFormat,
                                    sizeof(mAudioFormat)),
                                    "kAudioUnitProperty_StreamFormat::kAudioUnitScope_Output::kInputBus");
    
    //Disable buffer allocation for recording(optional)
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioUnitProperty_ShouldAllocateBuffer,
                                    kAudioUnitScope_Output,
                                    kInputBus,
                                    &disable,
                                    sizeof(disable)),
                                    "kAudioUnitProperty_ShouldAllocateBuffer::kAudioUnitScope_Output::kInputBus");
    
    //AudioUnitInitialize
    CheckError(AudioUnitInitialize(mAudioUnit), "AudioUnitInitialize");
}


- (id)init {
    return self;
}

-(void)setFilePath:(NSString *)destinationFilePath {
    
    [self configAudio];
   // [self performSelectorInBackground:@selector(configAudio) withObject:nil];

    
    AURenderCallbackStruct recorderStruct;
    recorderStruct.inputProc = recordCallback;
    recorderStruct.inputProcRefCon = (__bridge void *)(self);
    CheckError(AudioUnitSetProperty(mAudioUnit,
                                    kAudioOutputUnitProperty_SetInputCallback,
                                    kAudioUnitScope_Input,
                                    kInputBus,
                                    &recorderStruct,
                                    sizeof(recorderStruct)),
               "kAudioOutputUnitProperty_SetInputCallback::kAudioUnitScope_Input::kInputBus");
    
    CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)destinationFilePath, kCFURLPOSIXPathStyle, false);
    CheckError(ExtAudioFileCreateWithURL(destinationURL, kAudioFileWAVEType, &mAudioFormat, NULL, kAudioFileFlags_EraseFile, &mAudioFileRef),"Couldn't create a file for writing");
    CFRelease(destinationURL);

}

-(void)startRecording {
     AudioOutputUnitStart(mAudioUnit);
}

-(void)stopRecording {
    AudioOutputUnitStop(mAudioUnit);
    CheckError(ExtAudioFileDispose(mAudioFileRef),"ExtAudioFileDispose failed");
}

@end

////
////  AudioUnitRecorder.m
////  AudioUnitPlayer
////
////  Created by Sajiv Nair on 02/07/15.
////  Copyright (c) 2015 intelliswift. All rights reserved.
////
//
//
//
//#import "AudioUnitRecorder.h"
//#import <AudioToolbox/AudioSession.h>
//#import <AudioUnit/AUComponent.h>
//#import <AudioUnit/AudioUnitProperties.h>
//#import <AudioUnit/AudioOutputUnit.h>
//#include "TPCircularBuffer.h"
//
//@implementation AudioUnitRecorder {
//    AudioComponentInstance      mAudioUnit;
//    ExtAudioFileRef             mAudioFileRef;
//    InMemoryAudioFile           *inMemoryAudioFile;
//    AudioStreamBasicDescription mAudioFormat;
//    TPCircularBuffer buffer;
//}
//
//UInt32 frames = 0;
//
//OSStatus recordCallback(void                              *inRefCon,
//                        AudioUnitRenderActionFlags        *ioActionFlags,
//                        const AudioTimeStamp              *inTimeStamp,
//                        UInt32                            inBusNumber,
//                        UInt32                            inNumberFrames,
//                        AudioBufferList                   *ioData){
//    NSLog(@"Recorder");
//    AudioBufferList bufferList;
//    UInt16 numSamples=inNumberFrames*kChannels;
//    UInt16 samples[numSamples];
//    memset (&samples, 0, sizeof (samples));
//    bufferList.mNumberBuffers = 1;
//    bufferList.mBuffers[0].mData = samples;
//    bufferList.mBuffers[0].mNumberChannels = kChannels;
//    bufferList.mBuffers[0].mDataByteSize = numSamples*sizeof(UInt16);
//    AudioUnitRecorder* tthis = (__bridge AudioUnitRecorder *)inRefCon;
//    CheckError(AudioUnitRender(tthis->mAudioUnit,
//                               ioActionFlags,
//                               inTimeStamp,
//                               kInputBus,
//                               inNumberFrames,
//                               &bufferList),"AudioUnitRender failed");
//    
//    frames += inNumberFrames;
//    
//    // Now, we have the samples we just read sitting in buffers in bufferList
//    TPCircularBufferProduceBytes(&tthis->buffer, &bufferList, inNumberFrames);
//    
//    //ExtAudioFileWriteAsync(tthis->mAudioFileRef, inNumberFrames, &bufferList);
//    return noErr;
//}
//
//static void CheckError(OSStatus error,const char *operaton){
//    if (error==noErr) {
//        return;
//    }
//    char errorString[20]={};
//    *(UInt32 *)(errorString+1)=CFSwapInt32HostToBig(error);
//    if (isprint(errorString[1])&&isprint(errorString[2])&&isprint(errorString[3])&&isprint(errorString[4])) {
//        errorString[0]=errorString[5]='\'';
//        errorString[6]='\0';
//    }else{
//        sprintf(errorString, "%d",(int)error);
//    }
//    fprintf(stderr, "Error:%s (%s)\n",operaton,errorString);
//    exit(1);
//}
//
//void routeChangeListener1(void                      *inClientData,
//                          AudioSessionPropertyID    inID,
//                          UInt32                    inDataSize,
//                          const void                *inData) {
//    
//    //trigger event
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"AUDIOROUTECHANGE" object:nil ];
//    printf("audioRouteChangeListener");
//}
//
//
//
//void interruptionListener1(void *inClientData,UInt32 inInterruptionState){
//    switch (inInterruptionState) {
//        case kAudioSessionBeginInterruption:
//            break;
//        case kAudioSessionEndInterruption:
//            break;
//        default:
//            break;
//    }
//}
//
//#define kBufferLength 1024
//
//-(void)initializeAudioSession{
//    CheckError(AudioSessionInitialize(NULL, kCFRunLoopDefaultMode, interruptionListener1, (__bridge void *)(self)), "couldn't initialize the audio session");
//    CheckError(AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, routeChangeListener1, (__bridge void *)(self)),"couldn't add a route change listener");
//    
//}
//
//-(void)configAudio {
//    
//    TPCircularBufferInit(&buffer, kBufferLength);
//    
//    //Is there an audio input device available
//    UInt32 inputAvailable;
//    UInt32 propSize=sizeof(inputAvailable);
//    CheckError(AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &propSize, &inputAvailable), "not available for the current input audio device");
//    if (!inputAvailable) {
//        return;
//    }
//    
//    //Adjust audio hardware I/O buffer duration.If I/O latency is critical in your app, you can request a smaller duration.
//    Float32 ioBufferDuration = .100;
//    CheckError(AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(ioBufferDuration), &ioBufferDuration),"couldn't set the buffer duration on the audio session");
//    
//    //Set the audio category
//    UInt32 audioCategory = kAudioSessionCategory_RecordAudio;
//    CheckError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory), "couldn't set the category on the audio session");
//    
//    //UInt32 override=true;
//    //AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(override), &override);
//    
//    UInt32 overrid = kAudioSessionOverrideAudioRoute_Speaker;
//    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(overrid), &overrid);
//    
//    //Get hardware sample rate and setting the audio format
//    Float64 sampleRate;
//    UInt32 sampleRateSize=sizeof(sampleRate);
//    CheckError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &sampleRateSize, &sampleRate),                                      "Couldn't get hardware samplerate");
//    mAudioFormat.mSampleRate         = sampleRate;
//    mAudioFormat.mFormatID           = kAudioFormatLinearPCM; //kAudioFormatMPEG4AAC
//    mAudioFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;  // kMPEG4Object_AAC_Main
//    mAudioFormat.mFramesPerPacket    = 1;
//    mAudioFormat.mChannelsPerFrame   = kChannels;
//    mAudioFormat.mBitsPerChannel     = 16;
//    mAudioFormat.mBytesPerFrame      = mAudioFormat.mBitsPerChannel*mAudioFormat.mChannelsPerFrame/8;
//    mAudioFormat.mBytesPerPacket     = mAudioFormat.mBytesPerFrame*mAudioFormat.mFramesPerPacket;
//    mAudioFormat.mReserved           = 0;
//    
//    //Obtain a RemoteIO unit instance
//    AudioComponentDescription acd;
//    acd.componentType = kAudioUnitType_Output;
//    acd.componentSubType = kAudioUnitSubType_RemoteIO;
//    acd.componentFlags = 0;
//    acd.componentFlagsMask = 0;
//    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
//    AudioComponent inputComponent = AudioComponentFindNext(NULL, &acd);
//    CheckError(AudioComponentInstanceNew(inputComponent, &mAudioUnit), "Couldn't new AudioComponent instance");
//    
//    //The Remote I/O unit, by default, has output enabled and input disabled
//    //Enable input scope of input bus for recording.
//    UInt32 enable = 1;
//    UInt32 disable=0;
//    CheckError(AudioUnitSetProperty(mAudioUnit,
//                                    kAudioOutputUnitProperty_EnableIO,
//                                    kAudioUnitScope_Input,
//                                    kInputBus,
//                                    &enable,
//                                    sizeof(enable)),
//               "kAudioOutputUnitProperty_EnableIO::kAudioUnitScope_Input::kInputBus");
//    
//    //Apply format to output scope of input bus for recording.
//    CheckError(AudioUnitSetProperty(mAudioUnit,
//                                    kAudioUnitProperty_StreamFormat,
//                                    kAudioUnitScope_Output,
//                                    kInputBus,
//                                    &mAudioFormat,
//                                    sizeof(mAudioFormat)),
//               "kAudioUnitProperty_StreamFormat::kAudioUnitScope_Output::kInputBus");
//    
//    //Disable buffer allocation for recording(optional)
//    CheckError(AudioUnitSetProperty(mAudioUnit,
//                                    kAudioUnitProperty_ShouldAllocateBuffer,
//                                    kAudioUnitScope_Output,
//                                    kInputBus,
//                                    &disable,
//                                    sizeof(disable)),
//               "kAudioUnitProperty_ShouldAllocateBuffer::kAudioUnitScope_Output::kInputBus");
//    
//    //AudioUnitInitialize
//    CheckError(AudioUnitInitialize(mAudioUnit), "AudioUnitInitialize");
//}
//
//
//- (id)init {
//    return self;
//}
//
//-(void)setFilePath:(NSString *)destinationFilePath {
//    
//    [self configAudio];
//    // [self performSelectorInBackground:@selector(configAudio) withObject:nil];
//    
//    
//    AURenderCallbackStruct recorderStruct;
//    recorderStruct.inputProc = recordCallback;
//    recorderStruct.inputProcRefCon = (__bridge void *)(self);
//    CheckError(AudioUnitSetProperty(mAudioUnit,
//                                    kAudioOutputUnitProperty_SetInputCallback,
//                                    kAudioUnitScope_Input,
//                                    kInputBus,
//                                    &recorderStruct,
//                                    sizeof(recorderStruct)),
//               "kAudioOutputUnitProperty_SetInputCallback::kAudioUnitScope_Input::kInputBus");
//    
//    CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)destinationFilePath, kCFURLPOSIXPathStyle, false);
//    CheckError(ExtAudioFileCreateWithURL(destinationURL, kAudioFileWAVEType, &mAudioFormat, NULL, kAudioFileFlags_EraseFile, &mAudioFileRef),"Couldn't create a file for writing");
//    CFRelease(destinationURL);
//    
//}
//
//-(void)startRecording {
//    AudioOutputUnitStart(mAudioUnit);
//    //    UInt32 uInt32Size = sizeof(UInt32);
//    //    UInt32 isGainAvaiable = 0;
//    //    OSStatus status = AudioSessionGetProperty(kAudioSessionProperty_InputGainAvailable, &uInt32Size, &isGainAvaiable);
//    //    if (isGainAvaiable)
//    //    {
//    //        Float32 gainFloat = 0.142857f; //for example...
//    //        status = AudioSessionSetProperty(kAudioSessionProperty_InputGainScalar, sizeof(gainFloat), &gainFloat);
//    //    }
//}
//
//-(void)stopRecording {
//    AudioOutputUnitStop(mAudioUnit);
//    //ExtAudioFileWrite(mAudioFileRef, frames, buffer);
//    CheckError(ExtAudioFileDispose(mAudioFileRef),"ExtAudioFileDispose failed");
//    //mAudioUnit = NULL;
//}
//
//@end