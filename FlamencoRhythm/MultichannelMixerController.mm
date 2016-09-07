
#import "MultiChannelMixerController.h"

#define kChannels   8
#define kInputBus   1

const Float64 kGraphSampleRate = 44100.0;
UInt32 kNumOfLoopStartBus;
UInt32 kNumOfRecordStartBus;

int seekEnabled = 0;
UInt32 numFramesArr[8];
UInt32 framesDiffArr[8];

int _mutx = 0;
inline void setMutex(int lock) { _mutx = lock; }
inline int  getMutex()         { return _mutx; }

#pragma mark- RenderProc

// audio render procedure, don't allocate memory, don't take any locks, don't waste time, printf statements for debugging only may adversly affect render you have been warned
static OSStatus renderInput(void *inRefCon,
                            AudioUnitRenderActionFlags *ioActionFlags,
                            const AudioTimeStamp *inTimeStamp,
                            UInt32 inBusNumber,
                            UInt32 inNumberFrames,
                            AudioBufferList *ioData){
    SoundBufferPtr sndbuf = (SoundBufferPtr)inRefCon;
    
    if(seekEnabled == 1 && kNumOfRecordStartBus > 0) {
        sndbuf[inBusNumber].sampleNum = framesDiffArr[inBusNumber];
        if(inBusNumber == kNumOfLoopStartBus - 1)
            seekEnabled++;
    }

    UInt32 sample = sndbuf[inBusNumber].sampleNum;
    UInt32 bufSamples = sndbuf[inBusNumber].numFrames;
    Float32 *in = sndbuf[inBusNumber].data;
    if(in == nullptr) {
        return noErr;
    }
    Float32 *outA = (Float32 *)ioData->mBuffers[0].mData;
    Float32 *outB = (Float32 *)ioData->mBuffers[1].mData;
    
    for (UInt32 i = 0; i < inNumberFrames; ++i) {
        if(sample < bufSamples && inBusNumber > kNumOfRecordStartBus-1 && kNumOfRecordStartBus != 0){
            outA[i] = in[sample];
            outB[i] = in[sample];
            sample++;
        }
        else if(inBusNumber < kNumOfRecordStartBus || kNumOfRecordStartBus == 0) {
            outA[i] = in[sample];
            outB[i] = in[sample];
            sample++;
            
            if (sample == bufSamples) {
                sample = 0;
            }
        }
    }
    
    if(sndbuf[inBusNumber].numFrames == sample) {
        if(kNumOfRecordStartBus != 0) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName: @"AUDIOFILENOTLOOPING"
             object: @{@"BUSNUMBER":[NSString stringWithFormat:@"%ud",inBusNumber]}];
        }
        else
            sndbuf[inBusNumber].sampleNum = sample;
    }
    else
        sndbuf[inBusNumber].sampleNum = sample;
    
    return noErr;
}


#pragma mark- MultichannelMixerController

@interface MultichannelMixerController (hidden)

- (void)loadFiles;

@end

@implementation MultichannelMixerController

@synthesize isPlaying;

- (void)dealloc{
    DisposeAUGraph(mGraph);
}

-(void)fillBuffers:(id)options andNumberOfBus:(UInt32)numBuses {
    kNumOfRecordStartBus = 0;
    isPlaying = false;
    metronomeBusIndex = -1;
    memset(&mSoundBuffer, 0, sizeof(mSoundBuffer));
    NSMutableArray *fileArray = (NSMutableArray *)options;
    
    for (int i=0;i<fileArray.count;i++) {
        NSDictionary *dict = [fileArray objectAtIndex:i];
        sourceURL[i] = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)[dict valueForKey:@"fileLocation"], kCFURLPOSIXPathStyle, false);
        bpmValue[i] = [[dict valueForKey:@"bpm"] floatValue] / [[dict valueForKey:@"startbpm"] floatValue];
        if( [[dict valueForKey:@"type"] isEqualToString:@"metronome"]){
            metronomeBusIndex = i;
        }
    }
    
    [fileArray enumerateObjectsUsingBlock:^(NSDictionary *object,NSUInteger idX, BOOL *stop){
        if([[object valueForKey:@"type"] isEqualToString:@"Recorded"]){
            kNumOfRecordStartBus = (UInt32)idX;
            *stop = YES;
        }
    }];
    
    _numbuses = numBuses;
    kNumOfLoopStartBus = numBuses;
}

- (void)initializeAUGraph{
    @try {
        AUNode outputNode;
        AUNode mixerNode;
        AUNode timePitchNode;
        
        // this is the format for the graph
        mAudioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                        sampleRate:kGraphSampleRate
                                                          channels:2
                                                       interleaved:NO];
        OSStatus result = noErr;
        
        // load up the audio data
        [self performSelectorInBackground:@selector(loadFiles) withObject:nil];
        
        // create a new AUGraph
        result = NewAUGraph(&mGraph);
        if (result) {return; }
        
        // output unit
        CAComponentDescription output_desc(kAudioUnitType_Output,
                                           kAudioUnitSubType_RemoteIO,
                                           kAudioUnitManufacturer_Apple);
        CAShowComponentDescription(&output_desc);
        
        // timePitchNode unit
        CAComponentDescription timePitch_desc(kAudioUnitType_FormatConverter,
                                              kAudioUnitSubType_NewTimePitch,
                                              kAudioUnitManufacturer_Apple);
        CAShowComponentDescription(&timePitch_desc);
        
        // multichannel mixer unit
        CAComponentDescription mixer_desc(kAudioUnitType_Mixer,
                                          kAudioUnitSubType_MultiChannelMixer,
                                          kAudioUnitManufacturer_Apple);
        CAShowComponentDescription(&mixer_desc);
        
        // create a node in the graph that is an AudioUnit, using the supplied AudioComponentDescription to find and open that unit
        result = AUGraphAddNode(mGraph, &output_desc, &outputNode);
        if (result) {return; }
        
        result = AUGraphAddNode(mGraph, &timePitch_desc, &timePitchNode);
        if (result) { return; }
        
        result = AUGraphAddNode(mGraph, &mixer_desc, &mixerNode );
        if (result) { return; }
        
        
        // connect a node's output to a node's input
        // mixer -> timepitch -> output
        
        result = AUGraphConnectNodeInput(mGraph, mixerNode, 0, timePitchNode, 0);
        if (result) { return; }
        
        result = AUGraphConnectNodeInput(mGraph, timePitchNode, 0, outputNode, 0);
        if (result) { return; }
        
        
        // open the graph AudioUnits are open but not initialized (no resource allocation occurs here)
        result = AUGraphOpen(mGraph);
        if (result) { return; }
        
        result = AUGraphNodeInfo(mGraph, mixerNode, NULL, &mMixer);
        if (result) { return; }
        
        result = AUGraphNodeInfo(mGraph, timePitchNode, NULL, &mTimeAU);
        if (result) { return; }
        
        // set bus count
        //UInt32 numbuses = 2;
        
        result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_ElementCount,
                                      kAudioUnitScope_Input, 0, &_numbuses, sizeof(_numbuses));
        
//        result = AudioUnitSetProperty(mTimeAU, kAudioUnitProperty_ElementCount,
//                                      kAudioUnitScope_Input, 0, &_numbuses, sizeof(_numbuses));
        
        if (result) {return; }
        
        for (int i = 0; i < _numbuses; ++i) {
            // setup render callback struct
            AURenderCallbackStruct rcbs;
            rcbs.inputProc = &renderInput;
            rcbs.inputProcRefCon = mSoundBuffer;
            
            // Set a callback for the specified node's specified input
            result = AUGraphSetNodeInputCallback(mGraph, mixerNode, i, &rcbs);
            // equivalent to AudioUnitSetProperty(mMixer, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, i, &rcbs, sizeof(rcbs));
            if (result) {return; }
            
            // set input stream format to what we want
            result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_StreamFormat,
                                          kAudioUnitScope_Input, i, mAudioFormat.streamDescription, sizeof(AudioStreamBasicDescription));
            
            if (result) { return; }
        }
        
        // set output stream format to what we want
        result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Output, 0, mAudioFormat.streamDescription, sizeof(AudioStreamBasicDescription));
        if (result) {return; }
        
        result = AudioUnitSetProperty(mTimeAU, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, mAudioFormat.streamDescription, sizeof(AudioStreamBasicDescription));
        
        // now that we've set everything up we can initialize the graph, this will also validate the connections
        result = AUGraphInitialize(mGraph);
        if (result) {return; }
        
        metronomePlayer = [[MetronomePlayer alloc] init];
        
        CAShow(mGraph);
    }
    @catch (NSException *exception) {
        //NSLog(@"exception is: %@",exception);
    }
    @finally {
        
    }
}

// load up audio data from the demo files into mSoundBuffer.data used in the render proc
- (void)loadFiles{
    
    for (int i = 0; i < NUMFILES && i < MAXBUFS; i++)  {
        if(kNumOfRecordStartBus != 0){
            bpmMultiplier = (i < kNumOfRecordStartBus - 2) ? kGraphSampleRate * bpmValue[i] : kGraphSampleRate;
        }
        else {
            bpmMultiplier = (i < _numbuses - 2) ? (bpmValue[i] == 1) ? kGraphSampleRate + 1 : kGraphSampleRate * bpmValue[i] : kGraphSampleRate;
        }
        
        AVAudioFormat *clientFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                                       sampleRate:bpmMultiplier
                                                                         channels:1
                                                                      interleaved:NO];
        ExtAudioFileRef xafref = 0;
        
        // open one of the two source files
        OSStatus result = ExtAudioFileOpenURL(sourceURL[i], &xafref);
        if (result || !xafref) {break; }
        
        // get the file data format, this represents the file's actual data format
        AudioStreamBasicDescription fileFormat;
        UInt32 propSize = sizeof(fileFormat);
        
        result = ExtAudioFileGetProperty(xafref, kExtAudioFileProperty_FileDataFormat, &propSize, &fileFormat);
        if (result) { break; }
        
        // set the client format - this is the format we want back from ExtAudioFile and corresponds to the format
        // we will be providing to the input callback of the mixer, therefore the data type must be the same
        
        double rateRatio = bpmMultiplier/ fileFormat.mSampleRate;
        
        propSize = sizeof(AudioStreamBasicDescription);
        result = ExtAudioFileSetProperty(xafref, kExtAudioFileProperty_ClientDataFormat, propSize, clientFormat.streamDescription);
        if (result) { break; }
        
        // get the file's length in sample frames
        UInt64 numFrames = 0;
        propSize = sizeof(numFrames);
        result = ExtAudioFileGetProperty(xafref, kExtAudioFileProperty_FileLengthFrames, &propSize, &numFrames);
        if (result) { break; }
        
        //if(i==metronomeBusIndex)
           // numFrames = (numFrames+6484)*4;
        //numFrames = (numFrames * rateRatio); // account for any sample rate conversion
        numFrames *= rateRatio;
        
        
        // set up our buffer
        mSoundBuffer[i].numFrames = (UInt32)numFrames;
        mSoundBuffer[i].asbd = *(clientFormat.streamDescription);
        numFramesArr[i] = (UInt32)numFrames;    //sn
        
        UInt32 samples = ((UInt32)numFrames * mSoundBuffer[i].asbd.mChannelsPerFrame);
        mSoundBuffer[i].data = (Float32 *)calloc(samples, sizeof(Float32));
        mSoundBuffer[i].sampleNum = 0;
        
        // set up a AudioBufferList to read data into
        AudioBufferList bufList;
        bufList.mNumberBuffers = 1;
        bufList.mBuffers[0].mNumberChannels = 1;
        bufList.mBuffers[0].mData = mSoundBuffer[i].data;
        bufList.mBuffers[0].mDataByteSize = samples * sizeof(Float32);
        
        // perform a synchronous sequential read of the audio data out of the file into our allocated data buffer
        UInt32 numPackets = (UInt32)numFrames;
        
        result = ExtAudioFileRead(xafref, &numPackets, &bufList);
        if (result) {
            free(mSoundBuffer[i].data);
            mSoundBuffer[i].data = 0;
        }
        
        // close the file and dispose the ExtAudioFileRef
        ExtAudioFileDispose(xafref);
        //CFRelease(sourceURL[i]);
    }
    
    // [clientFormat release];
}

// Seek to a specific frame based on seconds.
- (void)seekToFrame:(int)seconds {
    seekEnabled = 1;
    UInt32 seekedFrame = (UInt32)seconds * kGraphSampleRate;
    for (int i = 0; i < NUMFILES && i < MAXBUFS; i++)  {
        if(numFramesArr[i] == 0)
            return;
        
        if(seekedFrame > numFramesArr[i]) {
            UInt32 totalFrames = numFramesArr[i];
            while(totalFrames < seekedFrame) {
                if(i > kNumOfRecordStartBus - 1) {
                    [self enableInput:i isOn:0.0];
                    break;
                }
                totalFrames = totalFrames + numFramesArr[i] + 1;
            }
            framesDiffArr[i] = seekedFrame - (totalFrames - numFramesArr[i]);
        } else if(seekedFrame < numFramesArr[i]) {
            if(i > kNumOfRecordStartBus - 1) {
                [self enableInput:i isOn:1.0];
            }
            framesDiffArr[i] = seekedFrame;
        } else
            framesDiffArr[i] = 0;
    }
}

#pragma mark-

// Enable or disables a specific bus
- (void)enableInput:(UInt32)inputNum isOn:(AudioUnitParameterValue)isONValue {
    OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, inputNum, isONValue, 0);
    if (result) {return; }
}

// Sets the input volume for a specific bus
- (void)setInputVolume:(UInt32)inputNum value:(AudioUnitParameterValue)inputVolume {
    OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, inputNum, inputVolume, 0);
    if (result) { return; }
}

// Sets the panned position for a specific bus
- (void)setPanPosition:(UInt32)inputNum value:(AudioUnitParameterValue)pannedPosition {
    float pan  = -1.0 + pannedPosition * 2.0;
    
    OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Pan, kAudioUnitScope_Input, inputNum, pan, 0);
    if (result) { return; }
}

// Sets the overall mixer output volume
- (void)setOutputVolume:(AudioUnitParameterValue)value {
    OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, value, 0);
    if (result) { return; }
}

// starts render
- (void)startAUGraph {
    
    if(getMutex() == 1) {
        return;
    }
    
    OSStatus result = AUGraphStart(mGraph);
    if (result) { return; }
    isPlaying = true;
    setMutex(1);
}

// stops render
- (void)stopAUGraph:(BOOL)release {
    Boolean isRunning = false;
    OSStatus result = AUGraphIsRunning(mGraph, &isRunning);
    if (result) {
        return;
    }
    
    if (isRunning) {
        if(getMutex() == 0) {
            [self releaseSoundBuffer];
            return;
        }
        //[metronomePlayer stop];
        result = AUGraphStop(mGraph);
        if (result) {return; }
        isPlaying = false;
        setMutex(0);
    }
    
    if(release)
        [self releaseSoundBuffer];
}

- (void)releaseSoundBuffer {
    for (int i = 0; i < NUMFILES && i < MAXBUFS; i++)  {
        if(mSoundBuffer[i].data != nullptr) {
            free(mSoundBuffer[i].data);
            mSoundBuffer[i].data = 0;
            CFRelease(sourceURL[i]);
            sourceURL[i] = 0;
        }
    }
}

- (void)initializeAudioForMetronome {
    [metronomePlayer initializeAudioOutputForMetronome];
}

- (void)setCurrentBpm:(float)currBpm { 
    currentBpm = currBpm;
}

// Changes playback rate
-(void)changePlaybackRate:(AudioUnitParameterValue)inputNum {
    [metronomePlayer reset:currentBpm];
}

-(void)setMetronomeVolume:(float)volume{
    [metronomePlayer setVolume:volume];
}

@end