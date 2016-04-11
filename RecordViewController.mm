//
//  RecordViewController.m
//  FlamencoRhythm
//
//  Created by Mayank Mathur on 04/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import "RecordViewController.h"
#import "FrequencyViewController.h"
#import <Foundation/Foundation.h>
#import "MainNavigationViewController.h"
#import "DBManager.h"
#import "RhythmClass.h"
#import "MultichannelMixerController.h"

#import "DroneName.h"
#import "AudioRecorderManager.h"
#import "PureLayout.h"
#import "Constants.h"
#define DRONE_PICKERVIEW_NUMBER_OF_ROWS 20000
// get the volume of player
#define playerVolume(playerOn) (playerOn == 0 ? @"0" : @"1")
float tempo = 94.0f;
int caraouselIndex = 0;

int inputMic;

@interface RecordViewController ()<MainNavigationViewControllerDelegate>{
    NSMutableArray *dronePickerArray, *countArray,*bpmPickerArray;
    BOOL clapFlag1, clapFlag2, clapFlag3, clapFlag4;
    int playFlag, stopFlag;
    int micCounter, endresult;
    
    // Sajiv Elements
    float sampleRate;
    NSString *duration;
    int seconds, minutes;
    int mCurrentScore, currentRhythmId,currentBpm;
    int lag1;
    NSString *currentRythmName;
    
    NSError *audioSessionError;
    double peakPowerForChannel;
    NSString *currentMusicFileName;
    NSString *documentDir;
    NSString *newPath;
    AVAudioPlayer *myplayer;
    NSTimeInterval myTime;
    
    NSInteger pickerRow;
    
    // Database related Tags or Flags
    NSString *musicDuration, *mergeFilePath;
    int inst1,inst2,inst3,inst4,vol1,vol2,vol3,vol4,pan1,pan2,pan3,pan4,bpm,timeStamp,t1,t2,t3,t4,t1Vol,t2Vol,t3Vol,t4Vol,t1Pan,t2Pan,t3Pan,t4Pan;
    
    NSMutableArray *rhythmArray, *droneArray,*droneLocationArray;
    NSArray *droneNames;
    NSString *beatOneMusicFile, *beatTwoMusicFile;
    NSTimer *beatTimer;
    
    int counter,grayCounter,redCounter;
    DropDown *dropDownObj;
    DropDown *micDropDown;
    MultichannelMixerController *mixerController;
    AudioRecorderManager *audioRecorder;
    UInt32 audioUnitCount;
    bool isMetronome, isBpmPickerChanged;  //sn14Sept
}
@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    mixerController = [[MultichannelMixerController alloc]init];
    // Creating AudioRecorderManager class
    audioRecorder = [AudioRecorderManager SharedManager];
    
    [self setNeedsStatusBarAppearanceUpdate];
    // control actions of chromatic tuner and volume
    self.myNavigationController.delegate = self;
    
    //Hide genre dropdown background view
    [self.dropDownBgView setHidden:YES];
    
    // Do any additional setup after loading the view.
    _genreIdSelected = 1; // default genre is set to 1
    isStopped = 0;
    currentRhythmId = 0;
    
    // set beat1 & beat2
    [self resetFlags];
    
    mCurrentScore = 94;
    peakPowerForChannel = 0.0f;
    micCounter = endresult = 0;
    playFlag = stopFlag = seconds = minutes = 0;
    [_recordView setHidden:YES];
    
    [_playTimerBtn setHidden:YES];
    [_playStopBtn setHidden:YES];
    
    _myPort = nil;
    audioSessionError = nil;
    
    droneArray = [[NSMutableArray alloc]init];
    
    [_dronePickerView setHidden:NO];
    //   [_dronePickerLayer setHidden:NO];
    _dronePickerView.layer.cornerRadius = 20.0;
    
    //Add Gestures to bpm and dropn picker view
    [self setUpGestureAction];
    
    //for circular lay out of bpm pickerview
    self.bpmPickderBackView.layer.cornerRadius = 30;
    self.dronePickerBackView.layer.cornerRadius = 30;
    
    dronePickerArray = [[NSMutableArray alloc]init];
    bpmPickerArray = [[ NSMutableArray alloc]init];
    for (int i = 60; i <= 240 ; i++) {
        //[bpmPickerArray addObject:[NSString stringWithFormat:@"%d",i]];
    }
    [self.bpmPickerView removeFromSuperview];
   
    _carousel.type = iCarouselTypeCoverFlow2;
    
    // Setup MPVolumeView not to show on main screen
    [self setUpMPVolumeView];
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    //    /////////////////////////////////////////// AURecorder ///////////////////////////////////////////
    //    _session = [AVAudioSession sharedInstance];
    //    [_session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    //    for (_input in [_session availableInputs]) {
    //        // set as an input the build-in microphone
    //        if ([_input.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
    //            _myPort = _input;
    //            break;
    //        }
    //    }
    //    [_session setPreferredInput:_myPort error:nil];
    
    [self registerForMediaPlayerNotifications];
    
    micArray = [[NSArray alloc]initWithObjects:mic1,mic2,mic3,mic4,mic5,mic6,mic7,mic8,mic9,mic10, nil];
    
    // Default values to be saved after app launches
    [self setDefaultValuesToMusicFiles];
    // initialize genre drop down table
    [self setUpDropDown];
    
    [_dropDownBtn setTitle:@"Metronome" forState:UIControlStateNormal];
    
    NSDictionary *dict = [[NSDictionary alloc]initWithObjectsAndKeys:@"0",@"genreId",@"1",@"bpmDefault", nil];
    self.genreIdDict = dict;
    
    // showing Metronome by default
    [self setDropDownLblWithString:@"Metronome"];
    [self refershRhythmsData];
   
    
    //    save number of recording in userdefaults. initially the value is '0'
    userDefaults = [NSUserDefaults standardUserDefaults];
    int value = [[userDefaults objectForKey:@"recodingid"] intValue];
    if (!value) {
        [userDefaults setObject:@"0" forKey:@"recodingid"];
        [userDefaults synchronize];
    }
    
    // Populating drone Values
    for (int i = 0; i < 1; i++) {
        [dronePickerArray addObjectsFromArray:droneArray];
    }
    _droneType = [droneArray objectAtIndex:0];
    [_dronePickerView reloadAllComponents];
   // [_dronePickerView selectRow:300 inComponent:0 animated:NO];
    int startIndex = (DRONE_PICKERVIEW_NUMBER_OF_ROWS/2)- ((DRONE_PICKERVIEW_NUMBER_OF_ROWS/2)%[dronePickerArray count]);
    [_dronePickerView selectRow:startIndex inComponent:0 animated:NO];
    pickerRow = startIndex;
    audioUnitCount = 0;
    isBpmPickerChanged = false;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChanged:) name:@"AUDIOROUTECHANGE" object:nil];
    [self addBackButton];
    [self changeBackGroundColors];
    [self addSlider];
    [self addSepratorOnCaresoule];
    [self addClap3Image];
    [self addBlurrEffect];
    [self addHeadPhoneMicDropDownButton];
    _recordTimerText.font = [UIFont fontWithName:FONT_LIGHT size:30];
    
    if(![MainNavigationViewController isHeadphonePlugged]) {
        _headPhoneMic.hidden = YES;
        inputMic = kUserInput_BuiltIn;
    }
    else {
        _headPhoneMic.hidden = NO;
        inputMic = kUserInput_Headphone;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideMicSwitch:)
                                                 name:@"HIDEMICSWITCH"
                                               object:nil];
   
  //  [self addBackGroundViewToInstriments];
    
}

-(void)hideMicSwitch:(NSNotification *)notification{
    NSString *hideMicSwitch = [notification object];
    if([hideMicSwitch isEqualToString:@"NO"]) {
        //[_micLabel  setHidden:NO];
        //[_micSwitch setHidden:NO];
        //[_micSwitch setOn:NO];
        [_headPhoneMic setHidden:NO];
        
        //inputMic = [_micSwitch isOn];
        inputMic = kUserInput_Headphone;
        
    } else {
        //[_micLabel  setHidden:YES];
        //[_micSwitch setHidden:YES];
        
        [_headPhoneMic setHidden:YES];
        
        inputMic = kUserInput_BuiltIn;
    }
}

-(void)addHeadPhoneMicDropDownButton{
    _headPhoneMic = [[UIView alloc]init];
    //headPhoneMic.backgroundColor = [UIColor redColor];
    [self.view addSubview:_headPhoneMic];
    
    headPhoneLabel = [[UILabel alloc]init];
    [_headPhoneMic addSubview:headPhoneLabel];
    headPhoneLabel.text = @"Headphone Mic";
    headPhoneLabel.font = [UIFont fontWithName:FONT_REGULAR size:9];
    headPhoneLabel.textColor = UIColorFromRGB(FONT_BLUE_COLOR);
    [headPhoneLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:5];
    [headPhoneLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    
    UIImageView *dropDownImageView = [[UIImageView alloc]init];
    //dropDownImageView.backgroundColor = [UIColor blueColor];
    dropDownImageView.image = [UIImage imageNamed:@"dropdown"];
    [dropDownImageView autoSetDimensionsToSize:CGSizeMake(6, 4)];
    [_headPhoneMic addSubview:dropDownImageView];
    [dropDownImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:5];
    [dropDownImageView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    
    
    [_headPhoneMic autoAlignAxis:ALAxisVertical toSameAxisOfView:_stopBtn];
    [_headPhoneMic autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_stopBtn withOffset:0];
    [_headPhoneMic autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:6];
   // [_headPhoneMic autoSetDimension:ALDimensionHeight toSize:20];
   // _headPhoneMic.backgroundColor = [UIColor redColor];
    headPhoneDropdownViewWidthConstraint =  [_headPhoneMic autoSetDimension:ALDimensionWidth toSize:84];
    
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(headPhoneOptions:)];
    [_headPhoneMic addGestureRecognizer:gestureRecognizer];
   // [dropDownImageView addGestureRecognizer:gestureRecognizer];
    //dropDownImageView.userInteractionEnabled = YES;
}

-(void)headPhoneOptions:(id)sender{
    DLog(@"headPhoneOptions");
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Built In Mic" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        headPhoneDropdownViewWidthConstraint.constant = 64;
        headPhoneLabel.text = @"Built In Mic";
        inputMic = kUserInput_BuiltIn;
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Headphone Mic" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        headPhoneDropdownViewWidthConstraint.constant = 84;
        headPhoneLabel.text = @"Headphone Mic";
        inputMic = kUserInput_Headphone;
    }]];
    [self presentViewController:actionSheet animated:YES completion:nil];
}
-(void)addBackGroundViewToInstriments{
    _instBtn1.backgroundColor = UIColorFromRGB(FONT_BLUE_COLOR);
  // _instBtn1.layer.cornerRadius = _instBtn1.frame.size.width/2;
  //  _instBtn1.layer.borderColor = UIColorFromRGB(FONT_BLUE_COLOR).CGColor;
   // _instBtn1.layer.masksToBounds = YES;
    //UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:_instBtn1.bounds byRoundingCorners:(UIRectCornerTopRight | UIRectCornerBottomRight) cornerRadii:CGSizeMake(7.0, 7.0)];
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:_instBtn1.bounds cornerRadius:_instBtn1.bounds.size.width/2];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.view.bounds;
    maskLayer.path  = maskPath.CGPath;
    _instBtn1.layer.mask = maskLayer;
    
    CAShapeLayer *borderLayer = [[CAShapeLayer alloc] init];
    borderLayer.frame = self.view.bounds;
    borderLayer.path  = maskPath.CGPath;
    borderLayer.lineWidth   = 1.5f;
    borderLayer.strokeColor = UIColorFromRGB(FONT_BLUE_COLOR).CGColor;
    borderLayer.fillColor   = UIColorFromRGB(FONT_BLUE_COLOR).CGColor;
    [_instBtn1.layer addSublayer:borderLayer];
    //_instBtn1.layer.borderWidth = 1;
   // _instBtn1.clipsToBounds = YES;
    [_instBtn1 setImage:nil forState:UIControlStateNormal];
     [_instBtn1 setImage:nil forState:UIControlStateSelected];
     [_instBtn1 setImage:nil forState:UIControlStateDisabled];
    [_instBtn1 setBackgroundImage:nil forState:UIControlStateNormal];
    [_instBtn1 setBackgroundImage:nil forState:UIControlStateSelected];
    [_instBtn1 setBackgroundImage:nil forState:UIControlStateDisabled];
   /* UIView *instBtn1BackGround = [[UIView alloc]init];
    instBtn1BackGround.backgroundColor = UIColorFromRGB(FONT_BLUE_COLOR);
    [_instBtn1.superview insertSubview:instBtn1BackGround belowSubview:_instBtn1];
    [instBtn1BackGround autoAlignAxis:ALAxisVertical toSameAxisOfView:_instBtn1];
    [instBtn1BackGround autoAlignAxis:ALAxisHorizontal toSameAxisOfView:_instBtn1];
    [instBtn1BackGround autoSetDimensionsToSize:CGSizeMake(60, 60)];
    instBtn1BackGround.layer.cornerRadius = 30;*/
    
}
-(void)refershRhythmsData{
    [self fetchDBData];
    [_carousel reloadData];
    [_carousel scrollToItemAtIndex:carouselFirtValue duration:0.0f];
}
#pragma -mark addViews
/******************/
-(void)addClap3Image{
    //[_instBtn3 setImage:[UIImage imageNamed:@"Claps3_Gray.png"] forState:UIControlStateNormal];
    clap3ImageView = [[UIButton alloc]initWithFrame: CGRectMake(0, 0, self.bpmPickderBackView.frame.size.width, self.bpmPickderBackView.frame.size.height)];
    [clap3ImageView setImage:[UIImage imageNamed:@"Claps3_Gray.png"] forState:UIControlStateNormal];
    //clap3ImageView.frame = CGRectMake(0, 0, self.bpmPickderBackView.frame.size.width, self.bpmPickderBackView.frame.size.height);
    clap3ImageView.tag = 33;
    [self.bpmPickderBackView addSubview:clap3ImageView];
    [clap3ImageView addTarget:self action:@selector(clap3Clicked:) forControlEvents:UIControlEventTouchUpInside];
     [clap3ImageView setImage:[UIImage imageNamed:@"Claps3_Blue.png"] forState:UIControlStateSelected];
    [clap3ImageView setSelected:YES];
}
-(void)clap3Clicked:(id)sender{
    UIButton *btn = (UIButton*)sender;
    if (clapFlag3 == 0) {
        [btn setSelected:YES];
        clapFlag3 = 1;
        if(playFlag == 1){
            [mixerController setInputVolume:(audioUnitCount - 2) value:clapFlag3];
            //[mixerController setMetronomeVolume:clapFlag3];
        }
    } else {
        [btn setSelected:NO];
        clapFlag3 = 0;
        [mixerController setInputVolume:(audioUnitCount - 2) value:clapFlag3];
        //[mixerController setMetronomeVolume:clapFlag3];
    }
   
}
-(void)addBlurrEffect{
    UIBlurEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    visualEffectView.frame = dropDownObj.frame;
    [dropDownObj removeFromSuperview];
    //_dropDownBgView.frame = CGRectMake(_dropDownBgView.frame.origin.x,457, _dropDownBgView.frame.size.width,  100);
    [_dropDownBgView removeFromSuperview];
    
    [visualEffectView.contentView addSubview:dropDownObj];
    [self.view addSubview:visualEffectView];
    
    footerFadedBackground = [[UIView alloc]initWithFrame:CGRectMake(0,457, _dropDownBgView.frame.size.width,  150)];
    footerFadedBackground.backgroundColor = [UIColor blackColor];
    footerFadedBackground.alpha = 0.0;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeDropDown)];
    [_myNavigationController.footerFadedBackground addGestureRecognizer:tapGesture];
    [self.view addSubview:footerFadedBackground];
}

-(void)changeBackGroundColors{
    _recordView.backgroundColor = [UIColor whiteColor];
    _carousel.backgroundColor = [UIColor colorWithRed:239.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1];//UIColorFromRGB(SHARE_BUTTON_COLOR);
}
-(void)addBackButton{
    //_genreBGView.backgroundColor = [UIColor redColor];
    UIButton *backButton = [[UIButton alloc]init];
    [_genreBGView addSubview:backButton];
    [backButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:0];
    [backButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [backButton autoSetDimensionsToSize:CGSizeMake(31, 44)];
    [backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    //[backButton setBackgroundColor:[UIColor redColor]];
    [backButton addTarget:self action:@selector(backToRecordedSoundListing:) forControlEvents:UIControlEventTouchUpInside];
}
-(void)addSlider{
    
    //_micView.backgroundColor = [UIColor yellowColor];
    bpmSliderBackGround = [[UIView alloc]init];
    [self.view insertSubview:bpmSliderBackGround belowSubview:dropDownObj];
   // [self.view addSubview:bpmSliderBackGround];
    [bpmSliderBackGround autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [bpmSliderBackGround autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [bpmSliderBackGround autoSetDimension:ALDimensionHeight toSize:30];
    [bpmSliderBackGround autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_recordTimerText withOffset:5];
   // bpmSliderBackGround.backgroundColor = [UIColor blackColor];
   // bpmSliderBackGround.backgroundColor = [UIColor yellowColor];
    
    UIButton *minusButton = [[UIButton alloc]init];
    [bpmSliderBackGround addSubview:minusButton];
    [minusButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:11];
    [minusButton autoSetDimensionsToSize:CGSizeMake(30, 30)];
   
    //[minusButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [minusButton addTarget:self action:@selector(bpmMinus:) forControlEvents:UIControlEventTouchUpInside];
    [minusButton setImage:[UIImage imageNamed:@"minusBtn.png"] forState:UIControlStateNormal];
    //[minusButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:143];
    
    UIButton *plusButton = [[UIButton alloc]init];
    [bpmSliderBackGround addSubview:plusButton];
    [plusButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:11];
    [plusButton autoSetDimensionsToSize:CGSizeMake(30, 30)];
    //[plusButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [plusButton addTarget:self action:@selector(bpmPlus:) forControlEvents:UIControlEventTouchUpInside];
    [plusButton setImage:[UIImage imageNamed:@"plusBtn.png"] forState:UIControlStateNormal];
    [plusButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:bpmSliderBackGround withOffset:0.77];
     [minusButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:bpmSliderBackGround withOffset:0.77];
    //minusButton.backgroundColor = [UIColor redColor];
    //plusButton.backgroundColor = [UIColor redColor];
    //[plusButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:143];
    //bpmSliderBackGround.backgroundColor = [UIColor redColor];
    bpmSlider = [[UISlider alloc]init];
    [bpmSliderBackGround addSubview:bpmSlider];
    
    bpmSlider.minimumValue = 60.0f;
    bpmSlider.maximumValue = 240.0f;
    bpmSlider.value = 120.0f;
    
    [bpmSlider setMinimumTrackTintColor:[UIColor grayColor]];
    [bpmSlider setMaximumTrackTintColor:[UIColor lightGrayColor]];
    
    //[bpmSlider autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:133];
    [bpmSlider autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [bpmSlider autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [bpmSlider autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:minusButton withOffset:10];
    [bpmSlider autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:plusButton withOffset:-10];
    [bpmSlider addTarget:self action:@selector(bpmSliderChanged:) forControlEvents:UIControlEventValueChanged];
   // bpmSlider.backgroundColor = [UIColor blueColor];
    //UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTapped:)];
    //[_recSlider addGestureRecognizer:tapGestureRecognizer];
    
    [bpmSlider addTarget:self action:@selector(sliderDidEndSliding:) forControlEvents:UIControlEventTouchUpInside];
    
    [bpmSlider setThumbImage:[UIImage imageNamed:@"sliderThumb.png"] forState:UIControlStateNormal];
    [self micHides];
   // [bpmPickerArray addObject:[NSString stringWithFormat:@"%d",120]];
    //minusButton.backgroundColor = [UIColor redColor];
   // plusButton.backgroundColor = [UIColor redColor];
}
-(void)addSepratorOnCaresoule{
    UIColor *sepratorColor = [UIColor colorWithRed:223.0/255.0 green:223.0/255.0 blue:227.0/255.0 alpha:1.0];
   UIView *topSeprator = [[UIView alloc]init];
    topSeprator.backgroundColor = sepratorColor;
    [_carousel addSubview:topSeprator];
    
    UIView *bottomSeprator = [[UIView alloc]init];
    bottomSeprator.backgroundColor = sepratorColor;//[UIColor lightGrayColor];
    [_carousel addSubview:bottomSeprator];
    
    [topSeprator autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [topSeprator autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [topSeprator autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [topSeprator autoSetDimension:ALDimensionHeight toSize:0.5];
    //[topSeprator autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:_carousel withOffset:-0.5];
    
    [bottomSeprator autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [bottomSeprator autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [bottomSeprator autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [bottomSeprator autoSetDimension:ALDimensionHeight toSize:0.5];
    //[bottomSeprator autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_carousel];
    
    
   
  //230.230.232
    //_carousel.layer.masksToBounds = NO;
    //_carousel.layer.shadowOffset = CGSizeMake(0, 0);
   // _carousel.layer.shadowRadius = 0.5;
   // _carousel.layer.shadowOpacity = 0.6;
    
}
-(void)micHides{
    for (int i = 0; i<[micArray count]; i++) {
        UIImageView *mic = [micArray objectAtIndex:i];
        mic.hidden = YES;
    }
    bpmSliderBackGround.hidden = NO;
    _headPhoneMic.userInteractionEnabled = YES;
    _headPhoneMic.alpha = 1.0f;
}
-(void)micShow{
    for (int i = 0; i<[micArray count]; i++) {
        UIImageView *mic = [micArray objectAtIndex:i];
        mic.hidden = NO;
    }
    bpmSliderBackGround.hidden = YES;
    _headPhoneMic.userInteractionEnabled = NO;
    _headPhoneMic.alpha = 0.3f;
}

-(void)bpmPlus:(id)sender{
    DLog(@"bpmPlus");
    bpmSlider.value = ++mCurrentScore;
    [self updateBpmText];
    [self restartAUGraph];
}

-(void)bpmMinus:(id)sender{
    DLog(@"bpmMinus");
    bpmSlider.value = --mCurrentScore;
    [self updateBpmText];
    [self restartAUGraph];
}

-(void)bpmSliderChanged:(id)sender{
    UISlider *slider = (UISlider *)sender;
    mCurrentScore = slider.value;
    DLog(@"%@ =",[NSString stringWithFormat:@"%f", slider.value]);
    [self updateBpmText];
}
-(void)updateBpmText{
    [_recordTimerText setText:[NSString stringWithFormat:@"%d bpm", (int)mCurrentScore]];
}
- (void)sliderDidEndSliding:(NSNotification *)notification {
    DLog(@"sliderDidEndSliding");
    [self restartAUGraph];
}

- (void)restartAUGraph {
    if(playFlag == 1) {
        if ([beatTimer isValid]) {
            [beatTimer invalidate];
            // beatTimer = nil;
        }
        
        [self stopAudioFiles];
        [self playAudioFile];
    }
}

/******************/
-(void)backToRecordedSoundListing:(id)sender{
    [self.myNavigationController goBackToSoundListing];
}
-(void)audioRouteChanged:(id)sender{

    //NSLog(@"RecordViewController");
    [self setVolumeInputOutput];
    
}

// SetupMPVolumeView
-(void)setUpMPVolumeView {
    _volumeView = [[MPVolumeView alloc] initWithFrame: CGRectMake(-100,-100,16,16)];
    _volumeView.showsRouteButton = NO;
    _volumeView.userInteractionEnabled = NO;
    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] addSubview:_volumeView];
}

-(void)setUpGestureAction {
    UITapGestureRecognizer *dismissPicker = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissPicker:)];
    dismissPicker.delegate = self;
    [self.dronePickerView addGestureRecognizer:dismissPicker];
    
    UITapGestureRecognizer *clap3Tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clap3TapAction:)];
    clap3Tap.delegate = self;
    [self.bpmPickerView addGestureRecognizer:clap3Tap];
    
    UITapGestureRecognizer *dropDownTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dropDownLblTapAction)];
    dropDownTap.delegate = self;
    
    UITapGestureRecognizer *micDropDownTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(micDropDownLblTapAction)];
    micDropDownTap.delegate = self;
    [self.micDropDownLbl addGestureRecognizer:micDropDownTap];

    [self.genreBGView addGestureRecognizer:dropDownTap];
    
    UISwipeGestureRecognizer *swiperecognizer;
    swiperecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dropDownLblTapAction)];
    [swiperecognizer setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [self.genreBGView addGestureRecognizer:swiperecognizer];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if([audioRecorder isRecording]) {
        [audioRecorder stopAudioRecording];
    }
    
    _session = [AVAudioSession sharedInstance];
    //[_session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    for (_input in [_session availableInputs]) {
        // set as an input the build-in microphone
        
        if ([_input.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
            _myPort = _input;
            break;
        }
    }
    [_session setPreferredInput:_myPort error:nil];
    [self calculateMicGain:0];
    //    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
    //                                     withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
    //                                           error:nil];
    
    [_micView setHidden:NO];
    //  //NSLog(@"RhythmArray = %@",[rhythmArray objectAtIndex:0]);
    if (_bpmDefaultFlag == 1) {
        [self setDataToUIElements:(int)[_carousel currentItemIndex]];
    }
    CGRect visibleSize = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = visibleSize.size.width;
    
    // set genre font according to ios device
    if (screenWidth == 414) { // iPhone 6+ condition
        [_dropDownLbl setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:18.0]];
    }else if(screenWidth == 375){ // iPhone 6 condition
        [_dropDownLbl setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0]];
    }
    
    if(![MainNavigationViewController isHeadphonePlugged]) {
        _headPhoneMic.hidden = YES;
        inputMic = kUserInput_BuiltIn;
    }
    else {
        _headPhoneMic.hidden = NO;
        inputMic = kUserInput_Headphone;
    }
    
    [_playBtn setBackgroundImage:[UIImage imageNamed:@"play-button"] forState:UIControlStateNormal];
    //[self setDropDownLblWithString:@"Metronome"];
    //[self refershRhythmsData];
}

// Fetching data from Database for the First time
-(void)fetchDBData{
    [countArray removeAllObjects];
    _genreIdSelected = [[_genreIdDict valueForKey:@"genreId"] intValue];
    if (_genreIdSelected == 0) {
        _genreIdSelected = 1;
    }
    DBManager *rhythmQuery = [[DBManager alloc]init];
    rhythmArray = [rhythmQuery getRhythmRecords:[NSNumber numberWithInt:_genreIdSelected]];
    
    for (RhythmClass *cls in rhythmArray) {
        NSString *str = [cls valueForKey:@"rhythmName"];
        [countArray addObject:str];
    }
    NSMutableArray *emptyArray = [[NSMutableArray alloc]init];
    int numberOfTimes = 100;
    for (int i = 0; i < numberOfTimes; i++) {
        for (NSString *str in countArray) {
            [emptyArray addObject:str];
        }
    }
    carouselFirtValue = 49*(int)rhythmArray.count;
    
    countArray = emptyArray;
    RhythmClass *cls = [rhythmArray objectAtIndex:0];
    int startBpm = ( [cls.rhythmStartBPM  intValue] -60);
    [_bpmPickerView selectRow:startBpm inComponent:0 animated:NO];
    mCurrentScore = [cls.rhythmStartBPM  intValue];
    currentBpm = [cls.rhythmBPM intValue];
    bpmSlider.value = mCurrentScore;
    [self updateBpmText];
    
    currentRythmName = [countArray objectAtIndex:0];
    lag1 = [cls.lag1  intValue];
    
    // Fetch Drone Type
    droneNames = [rhythmQuery getDroneName];
    for (DroneName *drone in droneNames) {
        //NSLog(@"the drone location: %@",drone.droneLocation);
        //NSLog(@"the drone location: %@",drone.droneName);
        [droneArray addObject:drone.droneName];
    }
}
-(void)setDefaultValuesToMusicFiles{
    inst1 = inst2 = 1;
    inst3 = inst4 = 0;
    vol1 = vol2 = vol3 = vol4 = 60;
    pan1 = pan2 = pan3 = pan4 = 50;
    t1 = t2 = t3 = t4 = -1;
    t1Vol = t2Vol = t3Vol = t4Vol = -1;
    t1Pan = t2Pan = t3Pan = t4Pan = -1;
    
    //bpm = 60;
    timeStamp = 007;
    
    musicDuration = @"-1";
    mergeFilePath = @"-1";
}

- (void)awakeFromNib{
    countArray = [[NSMutableArray alloc]init];
}

- (float) bpmForSelectedRythm:(NSString*)_rythm{
    for (RhythmClass *cls in rhythmArray) {
        NSString *str = [cls valueForKey:@"rhythmName"];
        if ([str isEqualToString:_rythm]) {
            return [[cls valueForKey:@"rhythmStartBPM"] floatValue];
        }
    }
    return 0;
}

#pragma mark - Timer Actions
-(void)changeRecBeatImages {
    
    if (counter == beatCount) {
        counter = 0;
    }
    if (redCounter == beatCount) {
        redCounter = 0;
    }
    UIImageView *grayBeatImg = (UIImageView*)[self.beatsView viewWithTag:counter];
    [grayBeatImg setImage:[UIImage imageNamed:@"beat_ball_grey"]];
    
    UIImageView *beatImg = (UIImageView*)[self.beatsView viewWithTag:redCounter];
    [beatImg setImage:[UIImage imageNamed:@"beat_ball_red.png"]];
    
    counter++;    redCounter++;
}
-(void)onPlayTimer:(NSTimer *)timer {
    seconds++;
    if(seconds == 60)
    {
        seconds = 0;
        minutes++;
    }
    duration = [NSString stringWithFormat:@"%.2d:%.2d", minutes, seconds];
    // timer value change
    [_recordTimerText setText:duration];
    
    //[self setVolumeInputOutput];
}

- (void) updateMicGain:(NSNotification *) notification {
    NSDictionary *micGainDct = notification.object;
    endresult = [micGainDct[@"micGainValue"] intValue];
    //NSLog(@"updateing mic gain: %d",endresult);
    //    endresult = int(peakPowerForChannel*100.0f);
    if(endresult > 0 && endresult <= 9)
    {
        [self calculateMicGain:0];
    }
    else if(endresult > 9 && endresult <= 10)
    {
        [self calculateMicGain:1];
    }
    else if(endresult > 10 && endresult <= 100)
    {
        [self calculateMicGain:endresult/10 + 1];
    }
}

- (void)restartMixer {
    
    if([_playBtn isUserInteractionEnabled])  {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:@"AUDIOROUTECHANGE"
                                                      object:nil];
        
        //[_session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
        if(playFlag == 1) {
            [self stopAudioFiles];
            [beatTimer invalidate];
            beatTimer = nil;
            
            [self resetBeatMeterImages];
            
            [_playTimer invalidate];
            _playTimer = nil;
            
            // to reset record timer text
            [_recordTimer invalidate];
            _recordTimer = nil;
            
            _recordTimerText.text = @"00:00";
            
            seconds = 0;
            minutes = 0;

        }
        if(stopFlag == 1) {
            [_playBtn setSelected:NO];
            [_stopBtn setSelected:NO];
            
            [_recImgTimer invalidate];
            _recImgTimer = nil;
            
            UIImageView *grayBeatImg = (UIImageView*)[self.beatsView viewWithTag:redCounter-1];
            [grayBeatImg setImage:[UIImage imageNamed:@"beat_ball_grey"]];
            
            //[_recorder stop];
            [audioRecorder stopAudioRecording];
            //[self.recordDelegate recordingDone];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"recordingDone"
                                                                object:nil];
            
            [_playTimer invalidate];
            _playTimer = nil;
            
            // to reset record timer text
            [_recordTimer invalidate];
            _recordTimer = nil;
            
            seconds = 0;
            minutes = 0;
            
            [self stopAudioFiles];
            [self calculateMicGain:0];   // to reset mic gain images to grey
            
            //[self saveRhythmRecording];
            stopFlag = 0;
            playFlag = 0;
            
            _recordTimerText.text = @"00:00";
            [_recordView setHidden:YES];
            [_bpmView setHidden:NO];
            [_micView setHidden:NO];

        }
        
        [_session setPreferredInput:_myPort error:nil];
        if(playFlag == 1) {
            [self performSelector:@selector(playAudioFile) withObject:self afterDelay:1.0];
        }
    }
}

-(void)setVolumeInputOutput{
    currentOutputs = _session.currentRoute.outputs;
    for( _output in currentOutputs )
    {
        if([_output.portType isEqualToString:AVAudioSessionPortHeadphones])
        {
            [self restartMixer];
            break;
        }
        else if([_output.portType isEqualToString:AVAudioSessionPortBuiltInSpeaker]){
            [self restartMixer];
            break;
        }
        else if([_output.portType isEqualToString:AVAudioSessionPortBuiltInReceiver]){
            //[_session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
            break;
        }
    }
}

- (void) calculateMicGain:(int) gain
{
    if(gain == 0){
        for(micCounter = 0;micCounter < 10;micCounter++){
            UIImageView *img = (UIImageView*)[micArray objectAtIndex:micCounter];
            [img setImage:[UIImage imageNamed:@"grey_strips.png"]];
        }
    }
    else if(gain > 0){
        for(micCounter = 1;micCounter <= gain;micCounter++){
            if(micCounter <= 7){
                UIImageView *img = (UIImageView*)[micArray objectAtIndex:(micCounter - 1)];
                [img setImage:[UIImage imageNamed:@"green-strip"]];
            }
            else if(micCounter == 8 || micCounter == 9){
                UIImageView *img = (UIImageView*)[micArray objectAtIndex:(micCounter - 1)];
                [img setImage:[UIImage imageNamed:@"orange-strip.png"]];
            }
            else if(micCounter == 10){
                UIImageView *img = (UIImageView*)[micArray objectAtIndex:(micCounter - 1)];
                [img setImage:[UIImage imageNamed:@"red-strip.png"]];
            }
        }
        for(micCounter = gain+1;micCounter < 11;micCounter++){
            UIImageView *img = (UIImageView*)[micArray objectAtIndex:(micCounter - 1)];
            [img setImage:[UIImage imageNamed:@"grey_strips.png"]];
        }
    }
}
-(void)resetFlags{
    //    clapFlag3 = clapFlag4 = 0;
    clapFlag1 = clapFlag2 = 1;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleDefault;
}
-(void)viewDidDisappear:(BOOL)animated{
    //    [super viewDidAppear:animated];
    
    if (playFlag == 1)
        [self.playBtn sendActionsForControlEvents: UIControlEventTouchUpInside];
    //     reset all timers
    [self resetAllTimers];
}
- (void)viewDidUnload{
    [super viewDidUnload];
    //free up memory by releasing subviews
    self.carousel = nil;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)toggleDronBtn {
    UIButton *btn = (UIButton*)[self.view viewWithTag:44];
    [self onTapClap4Btn:btn];
}
- (void)clap3TapAction:(UITapGestureRecognizer*)gestureRecognizer {
    UIButton *btn = (UIButton *)[self.view viewWithTag:33];
    [self onTapClap3Btn:btn];
}

- (void)dismissPicker:(UITapGestureRecognizer*)gestureRecognizer {
    UIButton *btn = (UIButton*)[self.view viewWithTag:44];
    [self onTapClap4Btn:btn];
}

- (IBAction)onTapClap1Btn:(id)sender {
    UIButton *btn = (UIButton*)sender;
    
    if (clapFlag1 == 0) {
        [btn setSelected:YES];
        clapFlag1 = 1;
        if(playFlag == 1){
            [mixerController setInputVolume:0 value:clapFlag1];
        }
    } else {
        [btn setSelected:NO];
        clapFlag1 = 0;
        [mixerController setInputVolume:0 value:clapFlag1];
    }
    if (btn.isSelected) {
      //  btn.backgroundColor = UIColorFromRGB(FONT_BLUE_COLOR);
    }
    else{
       // btn.backgroundColor = [UIColor colorWithRed:239.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1];
    }
    // [btn setImage:[UIImage imageNamed:@"Clap_Blue.png"] forState:UIControlStateSelected];
}

- (IBAction)onTapClap2Btn:(id)sender {
    UIButton *btn = (UIButton*)sender;
    if (clapFlag2 == 0) {
        [btn setSelected:YES];
        
        clapFlag2 = 1;
        if(playFlag == 1){
            [mixerController setInputVolume:1 value:clapFlag2];
        }
    } else {
        [btn setSelected:NO];
        clapFlag2 = 0;
        [mixerController setInputVolume:1 value:clapFlag2];
    }
    // [btn setImage:[UIImage imageNamed:@"Claps2_Selected.png"] forState:UIControlStateSelected];
}
- (IBAction)onTapClap3Btn:(id)sender {
    [self clap3Clicked:sender];
   /* UIButton *btn = (UIButton*)sender;
    if (clapFlag3 == 0) {
        [btn setSelected:YES];
        clapFlag3 = 1;
        if(playFlag == 1){
            [mixerController setInputVolume:(audioUnitCount - 2) value:clapFlag3];
            //[mixerController setMetronomeVolume:clapFlag3];
        }
    } else {
        [btn setSelected:NO];
        clapFlag3 = 0;
        [mixerController setInputVolume:(audioUnitCount - 2) value:clapFlag3];
        //[mixerController setMetronomeVolume:clapFlag3];
    }
    [btn setImage:[UIImage imageNamed:@"Claps4_Blue.png"] forState:UIControlStateSelected];*/
}

- (IBAction)onTapClap4Btn:(id)sender {
    
    UIButton *btn = (UIButton*)sender;
    if (clapFlag4 == 0) {
        [btn setSelected:YES];
        clapFlag4 = 1;
        
        if(playFlag == 1){
            [mixerController setInputVolume:(audioUnitCount - 1) value:clapFlag4];
        }
    } else {
        [btn setSelected:NO];
        clapFlag4 = 0;
        [mixerController setInputVolume:(audioUnitCount - 1) value:clapFlag4];
    }
    
    [_dronePickerView selectRow:pickerRow inComponent:0 animated:NO];
    
    if ([[_dronePickerView viewForRow:pickerRow forComponent:0] isKindOfClass:[UILabel class]]) {
        UILabel *selectedRow = (UILabel *)[_dronePickerView viewForRow:pickerRow forComponent:0];
        selectedRow.textColor = (clapFlag4 == 1) ? [UIColor whiteColor] : [UIColor blackColor];
    }

    // [btn setImage:[UIImage imageNamed:@"Claps4_Blue.png"] forState:UIControlStateSelected];
}

#pragma mark - paly 4 players
// '-(void)play4Players' Method has been removed

- (IBAction)onTapPlayBtn:(id)sender {
    // Show 2 Labels
    
    // Play button selected and audio is playing
    if (playFlag == 0) {
        [_stopBtn setEnabled:NO];
        playFlag = 1;
        
        //[_playBtn setBackgroundImage:[UIImage imageNamed:@"stopicon@2x.png"] forState:UIControlStateNormal];
        [_playBtn setBackgroundImage:[UIImage imageNamed:@"stopicon"] forState:UIControlStateNormal];
        [_playTimerBtn setHidden:NO];
        [_playStopBtn setHidden:NO];
        _playBtn.userInteractionEnabled = NO;
        [self playAudioFile];
        //wrote the below code in '- (void)playMusicFilesAfterDelay'
    }
    else if(playFlag == 1){
        
        [self enableDropDownLbl:YES];
        
        [_stopBtn setEnabled:YES];
       // [_playBtn setBackgroundImage:[UIImage imageNamed:@"PlayIcon"] forState:UIControlStateNormal];
        [_playBtn setBackgroundImage:[UIImage imageNamed:@"play-button"] forState:UIControlStateNormal];
        [_playTimerBtn setHidden:YES];
        [_playStopBtn setHidden:YES];
        
        //Stop multichannel mixer audio player
        [self stopAudioFiles];
        //[audioRecorder stopAudioRecording];
        // reset all timers
        [self resetAllTimers];
        
        //_recordTimerText.text = @"00:00";
        //[self.recordDelegate recordingDone];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"recordingDone"
                                                            object:nil];
        
        for (int i = 0; i < 12; i++) {
            UIImageView *grayBeatImg = (UIImageView*)[self.beatsView viewWithTag:i];
            [grayBeatImg setImage:[UIImage imageNamed:@"beat_ball_grey"]];
        }
        seconds = 0;
        minutes = 0;
        
        playFlag = 0;
    }
    if (stopFlag == 1) {
        [self micHides];
        [self updateBpmText];
        
        [_playBtn setSelected:NO];
        [_stopBtn setSelected:NO];
        stopFlag = 0;
        playFlag = 0;
        
        //[self stopAudioFiles];
        [audioRecorder stopAudioRecording];
        
        [self calculateMicGain:0];
        [_recordView setHidden:YES];
        [_bpmView setHidden:NO];
        [_micView setHidden:NO];
    }
}
- (IBAction)onTapStopBtn:(id)sender {
    //    [self enableDropDownLbl:YES];
    // change 2 buttons image
    
    // Recording button pressed
    if (stopFlag == 0) {
        [_playBtn setSelected:YES];
        [_stopBtn setSelected:YES];
        
        stopFlag = 1;
        playFlag = 1;
        _playBtn.userInteractionEnabled = NO;
        _stopBtn.userInteractionEnabled = NO;
        
        [self enableDropDownLbl:NO];
        
        [_recordView setHidden:NO];
        [_bpmView setHidden:YES];
        [_micView setHidden:NO];
        
        [self micShow];
        
        //[self.recordDelegate tappedRecordButton];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"tappedRecordButton"
                                                            object:nil];
        
        [_recordTimerText setText:@"00:00"];
        
        [self playAudioFile]; // Play audio files
        // [self startRecord]; // Start recording
    } // End of recording button
    else if (stopFlag == 1) {
        [self micHides];
        [self updateBpmText];
        
        [_playBtn setSelected:NO];
        [_stopBtn setSelected:NO];
        
        [_recImgTimer invalidate];
        _recImgTimer = nil;
        
        UIImageView *grayBeatImg = (UIImageView*)[self.beatsView viewWithTag:redCounter-1];
        [grayBeatImg setImage:[UIImage imageNamed:@"beat_ball_grey"]];
        
        //[_recorder stop];
        [audioRecorder stopAudioRecording];
        //[self.recordDelegate recordingDone];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"recordingDone"
                                                            object:nil];
        
        [_playTimer invalidate];
        _playTimer = nil;
        
        // to reset record timer text
        [_recordTimer invalidate];
        _recordTimer = nil;
        
        seconds = 0;
        minutes = 0;
        
        [self stopAudioFiles];
        [self calculateMicGain:0];   // to reset mic gain images to grey
        
        [self saveRhythmRecording];
        stopFlag = 0;
        playFlag = 0;
        
        [_recordView setHidden:YES];
        [_bpmView setHidden:NO];
        [_micView setHidden:NO];
    }
}
- (IBAction)onTapPlusBtn:(id)sender {
    if (mCurrentScore < 240) {
        
        mCurrentScore++;
        sampleRate = mCurrentScore;
        
        // first Stop timer
        [beatTimer invalidate];
        beatTimer = nil;
        
        if (playFlag == 1) {
            [self changeBeatMeterImages];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    //NSLog(@"button Index =  %ld",(long)buttonIndex);
    if (buttonIndex == 1) {
        currentMusicFileName = [alertView textFieldAtIndex:0].text;
        [self saveRhythmRecording];
    }
}
- (NSString *) timeStamp {
    return [NSString stringWithFormat:@"%ld",(long int)[[NSDate date] timeIntervalSince1970]];
}

-(BOOL)renameFileName:(NSString*)oldname withNewName:(NSString*)newname{
    documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *oldPath = [documentDir stringByAppendingPathComponent:oldname];
    newPath = [documentDir stringByAppendingPathComponent:newname];
    
    NSFileManager *fileMan = [NSFileManager defaultManager];
    NSError *error = nil;
    //NSLog(@"file exist :%d", [fileMan fileExistsAtPath:oldname]);
    if (![fileMan moveItemAtPath:oldPath toPath:newPath error:&error]){
        //NSLog(@"Failed to move '%@' to '%@': %@", oldPath, newPath, [error localizedDescription]);
        return false;
    }
    [self trimAudioFileWithInputFilePath:newPath toOutputFilePath:newPath];
    return true;
}

- (double)processAudio:(float)totalFileDuration withFilePathURL:(NSURL *)filePathURL{
    NSMutableData *data = [NSMutableData dataWithContentsOfURL:filePathURL];
    NSMutableData *Wave1= [NSMutableData dataWithData:[data subdataWithRange:NSMakeRange(44, [data length] - 44)]];
    uint8_t * bytePtr = (uint8_t  * )[Wave1 bytes] ;
    NSInteger totalData = [Wave1 length] / sizeof(uint8_t);
    int endRange = 0;
    for (int i = 0 ; i < totalData; i ++){
        //   NSLog(@"%x", bytePtr[i]);
        if (bytePtr[i] == 0) {
            endRange = i;
        }else
            break;
    }
    
    double silentAudioDuration =((endRange/(float)totalData)*totalFileDuration)*10;
    return silentAudioDuration;
}

- (void)trimAudioFileWithInputFilePath :(NSString *)inputPath toOutputFilePath : (NSString *)outputPath{
    // Path of your source audio file
    NSString *strInputFilePath = inputPath;
    NSURL *audioFileInput = [NSURL fileURLWithPath:strInputFilePath];
    
    // Path of trimmed file.
    NSString *strOutputFilePath = [outputPath stringByDeletingPathExtension];
    strOutputFilePath = [strOutputFilePath stringByAppendingString:@".m4a"];
    NSURL *audioFileOutput = [NSURL fileURLWithPath:strOutputFilePath];
    newPath = strOutputFilePath;
    
    if (!audioFileInput || !audioFileOutput){
        //return NO;
    }
    
    [[NSFileManager defaultManager] removeItemAtURL:audioFileOutput error:NULL];
    AVAsset *asset = [AVAsset assetWithURL:audioFileInput];
    CMTime audioDuration = asset.duration;
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    //NSLog(@"File Duration = %f ",audioDurationSeconds);
    
    
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    
    if (exportSession == nil){
        //return NO;
    }
    
    // Start time from which you want the audio file to be saved.
    float startTrimTime;
    
    if([MainNavigationViewController isIPhoneOlderThanVersion6])
        startTrimTime = 0.117;
    else
        startTrimTime = 0.15;
    // End time till which you want the audio file to be saved.
    // For eg. your file's length.
    float endTrimTime = audioDurationSeconds;
    
    recordingDuration = audioDurationSeconds-startTrimTime;
    
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
             //             NSLog(@"Success!");
             //             sound = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:newPath] error:nil];
             //             NSLog(@"Duration = %f",sound.duration);
             
         }
         else if (AVAssetExportSessionStatusFailed == exportSession.status)
         {
             // NSLog(@"failed");
         }
     }];
}

- (void)saveRhythmRecording {
    // Get the input text
    [self enableDropDownLbl:YES];
    //    currentMusicFileName = [alertView textFieldAtIndex:0].text;
    int value = [[userDefaults objectForKey:@"recodingid"] intValue];
    
    currentMusicFileName = [NSString stringWithFormat:@"Session %d",++value];
    [userDefaults setObject:[NSString stringWithFormat:@"%d",value] forKey:@"recodingid"];
    [userDefaults synchronize];
    
    //tempoCounter = NSString(audioPlayer.rate;
    time_t     now = time(0);
    struct tm  tstruct;
    char       date[80];
    char       time[80];
    tstruct = *localtime(&now);
    strftime(date, sizeof(date), "%d/%m/%Y", &tstruct);
    strftime(time, sizeof(time), "%X", &tstruct);
    
    // currentMusicFileName=[currentMusicFileName stringByAppendingString:@".m4a"];
    //NSString *str = [NSString stringWithFormat:@"Recording %d",value];
    //newPath = [audioRecorder renameFileName:@"MyAudioMemo.wav" withNewName:str];
    NSString *str = [NSString stringWithFormat:@"Recording_%d_%@.wav",value,[self timeStamp]];
    [self renameFileName:@"MyAudioMemo.wav" withNewName:str];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"MM/dd/yyyy"];
    NSString *stringFromDate = [dateFormatter stringFromDate:[NSDate date]];
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat: @"HH:mm:ss"];
    
    NSString *stringFromTime = [timeFormatter stringFromDate:[NSDate date]];
    if(_droneType == nil)
        _droneType = @"-1";
    // Have to change BPM value instaed of _bpmTxt.text in next line
    NSDictionary *musicDict = [[NSDictionary alloc]initWithObjectsAndKeys:currentMusicFileName,@"name",
                               [NSString stringWithFormat:@"%d",(clapFlag1)],@"inst1",
                               [NSString stringWithFormat:@"%d",(clapFlag2)],@"inst2",
                               [NSString stringWithFormat:@"%d",(clapFlag3)],@"inst3",
                               [NSString stringWithFormat:@"%d",(clapFlag4)],@"inst4",
                               [NSString stringWithFormat:@"%d",vol1],@"vol1",
                               [NSString stringWithFormat:@"%d",vol2],@"vol2",
                               [NSString stringWithFormat:@"%d",vol3],@"vol3",
                               [NSString stringWithFormat:@"%d",vol4],@"vol4",
                               [NSString stringWithFormat:@"%d",pan1],@"pan1",
                               [NSString stringWithFormat:@"%d",pan2],@"pan2",
                               [NSString stringWithFormat:@"%d",pan3],@"pan3",
                               [NSString stringWithFormat:@"%d",pan4],@"pan4",
                               [NSString stringWithFormat:@"%d",currentRhythmId],@"rhythmId",
                               [NSString stringWithFormat:@"%d",mCurrentScore],@"bpm",
                               stringFromDate,@"date",
                               stringFromTime,@"time",
                               [NSString stringWithFormat:@"%f",recordingDuration], @"duration",
                               _droneType,@"droneType",
                               newPath,@"t1",
                               @"-1",@"t2",
                               @"-1",@"t3",
                               @"-1",@"t4",
                               @"100",@"t1vol",
                               @"-1",@"t2vol",
                               @"-1",@"t3vol",
                               @"-1",@"t4vol",
                               @"50",@"t1pan",
                               @"-1",@"t2pan",
                               @"-1",@"t3pan",
                               @"-1",@"t4pan",
                               @"-1",@"mergefile",
                               @"0",@"isDeleted",
                               [NSString stringWithFormat:@"%f",recordingDuration],@"t1Duration",
                               @"-1",@"t2Duration",
                               @"-1",@"t3Duration",
                               @"-1",@"t4Duration",
                               @"1",@"t1Flag",
                               @"0",@"t2Flag",
                               @"0",@"t3Flag",
                               @"0",@"t4Flag",
                               nil];
    
    //NSLog(@"dict = %@",musicDict);
    sound = nil;
    DBManager *saveRhythm = [[DBManager alloc]init];
    [saveRhythm insertDataToRecordingInDictionary:musicDict];
   // NSMutableArray *songList = [saveRhythm getAllRecordingData];
    RecordingListData *recordingData = [saveRhythm getFirstRecordingData];
    [_myNavigationController openDetailRecordingView:recordingData];
    //[_myNavigationController viewToPresent:2 withDictionary:];
}

- (IBAction)onChangeBPM:(id)sender {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    RhythmClass *rhytmObj = appDelegate.latestRhythmClass;
    if(isMetronome) {
        tempoVal = 1.0f;
    } else {
        tempoVal = mCurrentScore/[rhytmObj.rhythmBPM floatValue];
    }
    
    
    
    [self enableDropDownLbl:YES];
    
    [_stopBtn setEnabled:YES];
    [_playBtn setBackgroundImage:[UIImage imageNamed:@"PlayIcon"] forState:UIControlStateNormal];
    
    [_playTimerBtn setHidden:YES];
    [_playStopBtn setHidden:YES];
    
    //[audioRecorder stopAudioRecording];
    //         reset all timers
    
    if(playFlag != 0){
        [self stopAudioFiles];
        [self resetAllTimers];
        
        _recordTimerText.text = @"00:00";
        //[self.recordDelegate recordingDone];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"recordingDone"
                                                            object:nil];
        
        for (int i = 0; i < 12; i++) {
            UIImageView *grayBeatImg = (UIImageView*)[self.beatsView viewWithTag:i];
            [grayBeatImg setImage:[UIImage imageNamed:@"beat_ball_grey"]];
        }
        seconds = 0;
        minutes = 0;
        
        playFlag = 0;
        [self onTapPlayBtn:self];
    }
    //[self playAudioFile];
    
    
    // Call BeatMeter Image change method
    // first Stop timer
    //    [beatTimer invalidate];
    //    beatTimer = nil;
}

-(void)changeBeatMeterImages{
    
    //    // Take Beat meter count and current BPM
    float beatFrequency = 60.0 / mCurrentScore;
    //    //NSLog(@"beatFreq = %f",beatFrequency);
    if ([beatTimer isValid]) {
        [beatTimer invalidate];
        // beatTimer = nil;
    }
    beatTimer = [NSTimer scheduledTimerWithTimeInterval:beatFrequency
                                                 target:self
                                               selector:@selector(changeBeatMeterImage)
                                               userInfo:nil
                                                repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:beatTimer forMode:NSRunLoopCommonModes];
}

-(void)changeBeatMeterImage{
    
    if(beatCount == counter)
    {
        counter = 0;
    }
    if (grayCounter == beatCount) {
        grayCounter = 0;
    }
    
    UIImageView *grayBeatImg = (UIImageView*)[self.beatsView viewWithTag:grayCounter];
    [grayBeatImg setImage:[UIImage imageNamed:@"beat_ball_grey"]];
    
    UIImageView *beatImg = (UIImageView*)[self.beatsView viewWithTag:counter];
    [beatImg setImage:[UIImage imageNamed:@"beat_ball_green.png"]];
    
    counter++;
    grayCounter++;
}
#pragma mark - UIPickerView Datasource mehods
- (int)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (int)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    if (pickerView.tag) {
        return (int)bpmPickerArray.count;
    }
    return DRONE_PICKERVIEW_NUMBER_OF_ROWS;//(int)[dronePickerArray count];
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return dronePickerArray[row%[dronePickerArray count]];;//dronePickerArray[row];
}

-(UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    if (pickerView.tag) {
        UILabel *lbl = [[UILabel alloc]initWithFrame:CGRectMake(5, 0, 50, 27)];
        [lbl setBackgroundColor:[UIColor clearColor]];
        lbl.textColor = [UIColor whiteColor];
        [lbl setFont:[UIFont fontWithName:@"HelveticaNeue" size:25.0]];
        lbl.clipsToBounds = YES;
        lbl.text = bpmPickerArray[row];
        
        [lbl setTextAlignment:NSTextAlignmentCenter];
        return lbl;
    }
    
    UILabel *lbl = [[UILabel alloc]initWithFrame:CGRectMake(7, 0, 50, 27)];
    [lbl setBackgroundColor:[UIColor clearColor]];
    
    UIColor *textColor;
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:25.0];
    [lbl setFont:font];

    (clapFlag4 == 1) ? textColor = [UIColor whiteColor] : textColor = [UIColor blackColor];
    
    NSString *droneTxt =  dronePickerArray[row%[dronePickerArray count]];//dronePickerArray[row];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:droneTxt
                                                                                         attributes:@{NSFontAttributeName: font}];
    if([droneTxt length] > 1) {
        [attributedString setAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue" size:18]
                                          , NSBaselineOffsetAttributeName:@10} range:NSMakeRange(1, 1)];
    }
    [attributedString addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0,attributedString.length)];
    
    lbl.attributedText = attributedString;
    
    [lbl setTextAlignment:NSTextAlignmentCenter];
    return lbl;
    
}
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 60;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    int updatedBpm;
    if (pickerView.tag) {
        isBpmPickerChanged = true;
        updatedBpm = bpmSlider.value;//[[bpmPickerArray objectAtIndex:[pickerView selectedRowInComponent:component]] intValue];
        _droneType = [dronePickerArray objectAtIndex:pickerRow%[dronePickerArray count]];
        mCurrentScore = currentBpm = updatedBpm;
    }
    else {
        pickerRow = [pickerView selectedRowInComponent:component];
        _droneType = [dronePickerArray objectAtIndex:pickerRow%[dronePickerArray count]];
        updatedBpm = bpmSlider.value;//[[bpmPickerArray objectAtIndex:[_bpmPickerView selectedRowInComponent:component]] intValue];
        mCurrentScore = currentBpm = updatedBpm;
    }
    
    if(playFlag == 1)
        [self onChangeBPM:nil];
}

#pragma mark- iCarousel methods

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel{
    //return the total number of items in the carousel
    return [countArray count];
}


- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    UILabel *label = nil;
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        CGRect visibleSize = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = visibleSize.size.width;
        if (screenWidth == 414) {
            view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 250.0f, 80.0f)];  //220
        }else if(screenWidth == 375){
            view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 220.0f, 80.0f)];  //220
        }else{
            view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 190.0f, 80.0f)];  //220
        }
        
        // ((UIImageView *)view).image = [UIImage imageNamed:@"page.png"];
        view.contentMode = UIViewContentModeCenter;
        
        label = [[UILabel alloc] initWithFrame:view.bounds];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = UIColorFromRGB(FONT_BLUE_COLOR);
        //        label.font = [label.font fontWithSize:25];
        label.font = [UIFont fontWithName:FONT_MEDIUM size:20.5];
        label.tag = 1;
        // label.text = [countArray objectAtIndex:index];
        [view addSubview:label];
    }
    else
    {
        //get a reference to the label in the recycled view
        label = (UILabel *)[view viewWithTag:1];
    }
    
    label.text = [countArray objectAtIndex:index];
    return view;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    // return
    return true;
}


- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    if (option == iCarouselOptionSpacing)
    {
        return value * 1.5;
    }
    return value;
}
// to stop sound
- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel{
    isBpmPickerChanged = false;   //sn14Sept
    isMetronome = false;          //sn14Sept
    //          Never Never
    if ([_carousel currentItemIndex] < 0) {
        _carousel.currentItemIndex = 0;
    }
    if ([countArray count] != 0) {
        [self setDataToUIElements:(int)[_carousel currentItemIndex]];
        caraouselIndex = (int)[_carousel currentItemIndex];
        
        // Default rythm sent to player
        currentRythmName = [countArray objectAtIndex:caraouselIndex];
        float value = [self bpmForSelectedRythm:[countArray objectAtIndex:caraouselIndex]];
        _bpmString = [NSString stringWithFormat:@"%d bpm", (int)value];
        bpmSlider.value = (int)value;
        _recordTimerText.text = _bpmString;
        [_bpmPickerView selectRow:((int)value - 60) inComponent:0 animated:NO];
        
        [self enableDropDownLbl:YES];
    }
}

- (void)enableUserInteractionOfViews:(BOOL)enable {
    for(UIView *currentView in self.view.subviews) {
        currentView.userInteractionEnabled = enable;
    }
}

- (void)carouselWillBeginDecelerating:(iCarousel *)carousel {
    [self enableUserInteractionOfViews:NO];
}

- (void)carouselDidEndDecelerating:(iCarousel *)carousel {
    [self enableUserInteractionOfViews:YES];
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel {
    //NSLog(@"carouselDidEndScrollingAnimation");
    [_stopBtn setEnabled:YES];
    [_playBtn setBackgroundImage:[UIImage imageNamed:@"PlayIcon"] forState:UIControlStateNormal];
    
    [_playTimerBtn setHidden:YES];
    [_playStopBtn setHidden:YES];
    
    [self stopAudioFiles];
    [_playTimer invalidate];
    _playTimer = nil;
    
    [beatTimer invalidate];
    beatTimer = nil;
    for (int i = 0; i < 12; i++) {
        UIImageView *grayBeatImg = (UIImageView*)[self.beatsView viewWithTag:i];
        [grayBeatImg setImage:[UIImage imageNamed:@"beat_ball_grey"]];
    }
    
    seconds = 0;
    minutes = 0;
    
    //  Never Never
    if ([_carousel currentItemIndex] < 0) {
        _carousel.currentItemIndex = 0;
    }
    if ([countArray count] != 0) {
        [self setDataToUIElements:(int)[_carousel currentItemIndex]];
        caraouselIndex = (int)[_carousel currentItemIndex];
        
        // Default rythm sent to player
        currentRythmName = [countArray objectAtIndex:caraouselIndex];
        float value = [self bpmForSelectedRythm:[countArray objectAtIndex:caraouselIndex]];
        currentBpm = value;
        _bpmString = [NSString stringWithFormat:@"%d bpm", (int)value];
        [_bpmPickerView selectRow:((int)value - 60) inComponent:0 animated:NO];
        
        [self enableDropDownLbl:YES];
        
        if (playFlag == 1) {
            playFlag = 0;
            [self.playBtn sendActionsForControlEvents: UIControlEventTouchUpInside];
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            RhythmClass *rhytmObj = appDelegate.latestRhythmClass;
            
            float tempo = mCurrentScore/[rhytmObj.rhythmBPM floatValue];
            [mixerController changePlaybackRate:tempo];
        }
        
    }
}
// Set UI elements on Caraousel Item Change
-(void)setDataToUIElements:(int)_index{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    RhythmClass *selectedRhythmClass = [[RhythmClass alloc]init];
    if ([countArray count] != 0) {
        
        currentRythmName = [countArray objectAtIndex:_index];
        
        for (RhythmClass *cls in rhythmArray) {
            
            //  //NSLog(@"cls value for key: %@",[cls valueForKey:@"rhythmName"]);
            if ([[cls valueForKey:@"rhythmName"] isEqualToString:currentRythmName]) {
                appDelegate.latestRhythmClass = cls;
                //         selectedRhythmClass = cls;
                break;
            }
        }
    }
    selectedRhythmClass = appDelegate.latestRhythmClass;
    
    // Set Music
    beatOneMusicFile = selectedRhythmClass.rhythmBeatOne;
    beatTwoMusicFile = selectedRhythmClass.rhythmBeatTwo;
    
    currentRhythmId = [selectedRhythmClass.rhythmId intValue];
    lag1 = [selectedRhythmClass.lag1  intValue];
    
    int img1 = 1, img2 = 1;
    // Set Image
    if (![selectedRhythmClass.rhythmInstOneImage isEqualToString:@"-1"]) {
        [_instBtn1 setHidden:NO];
        
        //
        NSArray *listItems = [selectedRhythmClass.rhythmInstOneImage componentsSeparatedByString:@"."];
        NSString *lastWordString = [NSString stringWithFormat:@"%@", listItems.firstObject];
        
       [_instBtn1 setImage:[UIImage imageNamed:selectedRhythmClass.rhythmInstOneImage] forState:UIControlStateSelected];
    [_instBtn1 setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@_disabled.png",lastWordString]] forState:UIControlStateNormal];
        
        img1 = 1;
    }else{
        [_instBtn1 setHidden:YES];
        img1 = 0;
    }
    if (![selectedRhythmClass.rhythmInstTwoImage isEqualToString:@"-1"]) {
        [_instBtn2 setHidden:NO];
        
        //
        NSArray *listItems = [selectedRhythmClass.rhythmInstTwoImage componentsSeparatedByString:@"."];
        NSString *lastWordString = [NSString stringWithFormat:@"%@", listItems.firstObject];
        
        [_instBtn2 setImage:[UIImage imageNamed:selectedRhythmClass.rhythmInstTwoImage] forState:UIControlStateSelected];
        [_instBtn2 setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@_disabled.png",lastWordString]] forState:UIControlStateNormal];
        img2 = 1;
    }else{
        [_instBtn2 setHidden:YES];
        img2 = 0;
    }
    
    CGRect visibleSize = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = visibleSize.size.width;
    //    CGFloat screenHeight = visibleSize.size.height;
    int xDist = 0;  // for 320
    // If only 2 buttons are there
    if ((img1 == 0) && (img2 == 0)) {
        xDist = ((screenWidth - 120) / 3);
        //  Mayank changes
        _instBtn3.frame = CGRectMake(xDist, _instBtn3.frame.origin.y, 60, 60);
        _bpmPickderBackView.frame = CGRectMake(xDist, _bpmPickderBackView.frame.origin.y, 60, 60);
        _dronBtn.frame = CGRectMake((xDist*2)+60, _dronBtn.frame.origin.y, 60, 60);
        _dronePickerBackView.frame = CGRectMake((xDist*2)+60, _dronePickerBackView.frame.origin.y, 60, 60);
        
        _Instrument3_Layout.constant = xDist;
        _Bpm_Layout.constant =  xDist;
        _Intrument4_Layout.constant = xDist*2 +60;
        _drone_Layout.constant =  xDist*2 +60;
        
        [self.view setNeedsUpdateConstraints];
        
    }else if (img1 == 0){
        xDist = ((screenWidth - 180) / 4);
        //  Mayank changes
        _instBtn2.frame = CGRectMake(xDist, _instBtn2.frame.origin.y, 60, 60);
        _instBtn3.frame = CGRectMake((xDist*2)+60, _instBtn3.frame.origin.y, 60, 60);
        _bpmPickderBackView.frame = CGRectMake((xDist*2)+60, _bpmPickderBackView.frame.origin.y, 60, 60);
        _dronBtn.frame = CGRectMake((xDist*3)+120, _dronBtn.frame.origin.y, 60, 60);
        _dronePickerBackView.frame = CGRectMake((xDist*3)+120, _dronePickerBackView.frame.origin.y, 60, 60);
        
        _Instrument2_Layout.constant = xDist;
        _Instrument3_Layout.constant = xDist*2 +60;
        _Bpm_Layout.constant =  xDist*2 +60;
        _Intrument4_Layout.constant = xDist*3 +120;
        _drone_Layout.constant =  xDist*3 +120;
    }else if (img2 == 0){
        xDist = ((screenWidth - 180) / 4);
        //  Mayank changes
        _instBtn1.frame = CGRectMake(xDist, _instBtn1.frame.origin.y, 60, 60);
        _instBtn3.frame = CGRectMake((xDist*2)+60, _instBtn3.frame.origin.y, 60, 60);
        _bpmPickderBackView.frame = CGRectMake((xDist*2)+60, _bpmPickderBackView.frame.origin.y, 60, 60);
        _dronBtn.frame = CGRectMake((xDist*3)+120, _dronBtn.frame.origin.y, 60, 60);
        _dronePickerBackView.frame = CGRectMake((xDist*3)+120, _dronePickerBackView.frame.origin.y, 60, 60);
        
        _Instrument1_Layout.constant = xDist;
        _Instrument3_Layout.constant = xDist*2 +60;
        _Bpm_Layout.constant =  xDist*2 +60;
        _Intrument4_Layout.constant = xDist*3 +120;
        _drone_Layout.constant =  xDist*3 +120;
        
    }else{
        xDist = ((screenWidth - 240) / 5);
        _instBtn1.frame = CGRectMake(xDist, _instBtn1.frame.origin.y, 60, 60);
        _instBtn2.frame = CGRectMake((xDist*2)+60, _instBtn2.frame.origin.y, 60, 60);
        _instBtn3.frame = CGRectMake((xDist*3)+120, _instBtn3.frame.origin.y, 60, 60);
        _bpmPickderBackView.frame = CGRectMake((xDist*3)+120, _bpmPickderBackView.frame.origin.y, 60, 60);
        _dronBtn.frame = CGRectMake((xDist*4)+180, _dronBtn.frame.origin.y, 60, 60);
        _dronePickerBackView.frame = CGRectMake((xDist*4)+180, _dronePickerBackView.frame.origin.y, 60, 60);
        
        _Instrument1_Layout.constant = xDist;
        _Instrument2_Layout.constant = xDist*2 +60;
        _Instrument3_Layout.constant = xDist*3 +120;
        _Bpm_Layout.constant =  xDist*3 +120;
        _Intrument4_Layout.constant = xDist*4 +180;
        _drone_Layout.constant =  xDist*4 +180;
    }
    
    // Set BPM values
    if ([countArray count] != 0) {
        float value = [self bpmForSelectedRythm:[countArray objectAtIndex:[_carousel currentItemIndex]]];
        _bpmString = [NSString stringWithFormat:@"%d bpm", (int)value];
        [_bpmTxt setText:_bpmString];
        if(!isBpmPickerChanged)   //sn14thSept
            mCurrentScore = [selectedRhythmClass.rhythmStartBPM intValue];
        tempo = value;
    }
    // Set Beats Meter
    beatCount = [selectedRhythmClass.rhythmBeatsCount intValue];
    if (beatCount != 0) {
        
        // [[UIScreen mainScreen] bounds].size.width
        float XDist = (((screenWidth) - (beatCount*21))/(beatCount+1));
        float temp = 0.0;
        
        for (int i = 0; i < beatCount; i++) {
            UIImageView *img = (UIImageView*)[self.beatsView viewWithTag:i];
            temp = lroundf((i *21) + ((i+1)*XDist));
            img.frame = CGRectMake(temp, img.frame.origin.y, 21, 21);
            [img setHidden:NO];
        }
        for (int j = beatCount; j <12; j++) {
            UIImageView *img1 = (UIImageView*)[self.beatsView viewWithTag:j];
            img1.frame = CGRectMake(9000, img1.frame.origin.y, 21, 21);
            [img1 setHidden:YES];
        }
        _beat1Circle_Layout.constant = lroundf((0 *21) + (1*XDist));
        _beat2Circle_Layout.constant = lroundf((1 *21) + (2*XDist));
        _beat3Circle_Layout.constant = lroundf((2 *21) + (3*XDist));
        _beat4Circle_Layout.constant = lroundf((3 *21) + (4*XDist));
        _beat5Circle_Layout.constant = lroundf((4 *21) + (5*XDist));
        _beat6Circle_Layout.constant = lroundf((5 *21) + (6*XDist));
        _beat7Circle_Layout.constant = lroundf((6 *21) + (7*XDist));
        _beat8Circle_Layout.constant = lroundf((7 *21) + (8*XDist));
        _beat9Circle_Layout.constant = lroundf((8 *21) + (9*XDist));
        _beat10Circle_Layout.constant = lroundf((9 *21) + (10*XDist));
        _beat11Circle_Layout.constant = lroundf((10 *21) + (11*XDist));
        _beat12Circle_Layout.constant = lroundf((11 *21) + (12*XDist));
    }
    
    int xMyDist = ((screenWidth - 269) / 2);
    _micGainFirstLeading.constant = xMyDist;
    
    [self.view setNeedsUpdateConstraints];
   // _instBtn1.hidden = YES;
    //_instBtn2.hidden = YES;
    
    //[_instBtn1 setImage:[UIImage imageNamed:@"dropdown"] forState:UIControlStateSelected];
   // [_instBtn1 setImage:[UIImage imageNamed:@"dropdown"] forState:UIControlStateNormal];
    //_instBtn1.layer.cornerRadius = _instBtn1.frame.size.width/2;
}

// To learn about notifications, see "Notifications" in Cocoa Fundamentals Guide.
- (void) registerForMediaPlayerNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    // notification for the update mic gain
    [notificationCenter addObserver:self
                           selector:@selector(updateMicGain:)
                               name:@"updateMicGain"
                             object:nil];
    
    //    handle_NowPlayingItemChanged & handle_PlaybackStateChanged  notifications removed they have names respectively MPMusicPlayerControllerNowPlayingItemDidChangeNotification & MPMusicPlayerControllerPlaybackStateDidChangeNotification
}
// When the now-playing item changes, update the media item artwork and the now-playing label. notifications removed.

#pragma mark - DropDown setup & delegate methods
- (void)dropDownLblTapAction {
    //NSLog(@"lbl tap action");
    [self dropDownLblAction:nil];
}

- (void)micDropDownLblTapAction {
    CGRect rect = CGRectMake(self.micDropDownLbl.bounds.origin.x + self.micDropDownLbl.bounds.size.width, self.micDropDownLbl.bounds.origin.y + self.micDropDownLbl.bounds.size.height, self.micDropDownLbl.bounds.size.width, self.micDropDownLbl.bounds.size.height * 2);
    
    [UIView animateWithDuration:0.3 animations:^{
        micDropDown.frame = rect;//self.micDropDownLbl.bounds;
    } completion:^(BOOL finished) {
    }];

}

- (IBAction)dropDownLblAction:(id)sender {
    [self.dropDownBgView setHidden:NO];
    self.dropDownBgView.alpha = 0.6;
    
    [UIView animateWithDuration:0.2 animations:^{
        dropDownObj.frame = self.view.bounds;
        _myNavigationController.footerFadedBackground.alpha = 0.4;
        //visualEffectView.frame = self.view.bounds;
        visualEffectView.frame = CGRectMake(0, 0, self.view.frame.size.width,  457);

    } completion:^(BOOL finished) {
        
    }];
}


// initilize genre drop down tableview
- (void)setUpDropDown {
    CGRect rect = CGRectMake(self.micDropDownLbl.bounds.origin.x + self.micDropDownLbl.bounds.size.width, self.micDropDownLbl.bounds.origin.y + self.micDropDownLbl.bounds.size.height, self.micDropDownLbl.bounds.size.width, self.micDropDownLbl.bounds.size.height * 2);
    
    
    dropDownObj = [[DropDown alloc]initWithFrame:self.view.bounds heading:@"Select Genre"];
    //micDropDown = [[DropDown alloc]initWithFrame:self.micDropDownLbl.bounds];
    micDropDown = [[DropDown alloc]initWithFrame:rect];
    dropDownObj.delegate = self;
    micDropDown.delegate = self;
    dropDownObj.frame = CGRectMake(0, 0, self.view.frame.size.width, 0);
    //micDropDown.frame = CGRectMake(0, 0, self.micDropDownLbl.frame.size.width, 0);
    micDropDown.frame = rect;
    micDropDown.backgroundColor = [UIColor blackColor];
    [self.view addSubview:dropDownObj];
    [self.controlsView addSubview:micDropDown];
    
    _micDropDownLbl.text = @"Headphone";
    [_micDropDownLbl sizeToFit];
    _micDropDownLbl.userInteractionEnabled = YES;
}
// Close genre drop down list
-(void)closeDropDown {
    //    [self.dropDownBgView setHidden:YES];
    [UIView animateWithDuration:0.2 animations:^{
        dropDownObj.frame = CGRectMake(0, 0, self.view.frame.size.width, 0);
        self.dropDownBgView.alpha = 0;
       _myNavigationController.footerFadedBackground.alpha = 0;
        visualEffectView.frame = CGRectMake(0, 0, self.view.frame.size.width, 0);
    } completion:^(BOOL finished) {
        [self.dropDownBgView setHidden:YES];
    }];
}
// Genere Table selected button action
-(void)dropDownSelectedCell:(NSDictionary *)dct {
    [self setDropDownLblWithString:[dct objectForKey:@"selectedString"]];
    //NSLog(@"the lbl width is: %f",self.dropDownLbl.frame.size.width);
    self.genreIdDict = dct;
    [self closeDropDown];
    [self fetchDBData];
    
    [_carousel reloadData];
    [_carousel scrollToItemAtIndex:carouselFirtValue duration:0.0f];
    [self setDataToUIElements:(int)[_carousel currentItemIndex]];
    
    [self resetFlags];
    [_instBtn1 setSelected:YES];
    [_instBtn2 setSelected:YES];
}
// Genre table same cell selected
-(void)dropDownSameCellSelected{
    [self closeDropDown];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
    if (touch.tapCount > 1) { // It will ignore touch with less than two finger
        return YES;
    }
    return YES;
}
// Set Genre lable text

- (void)setDropDownLblWithString:(NSString*)string {
     NSString *title = [NSString stringWithFormat:@"Genre:%@",string];
    NSMutableAttributedString* genere = [[NSMutableAttributedString alloc]initWithString:@"Genre: " attributes:@{NSFontAttributeName:[UIFont fontWithName:FONT_MEDIUM size:15.5],NSForegroundColorAttributeName:[UIColor blackColor]}];
     NSMutableAttributedString* generType = [[NSMutableAttributedString alloc]initWithString:string attributes:@{NSFontAttributeName:[UIFont fontWithName:FONT_MEDIUM size:15.5],NSForegroundColorAttributeName:UIColorFromRGB(FONT_BLUE_COLOR)}];
    [genere appendAttributedString:generType];
    // for those calls we don't specify a range so it affects the whole string
    _dropDownLbl.attributedText = genere;
   // _dropDownLbl.text = title;
    [_dropDownLbl sizeToFit];
    _dropDownLbl.textAlignment = NSTextAlignmentCenter;
    _dropDownLbl.center = CGPointMake(self.view.frame.size.width/2, _dropDownLbl.center.y);
    
    //CGRect rect = _arrowImage.frame;
   // rect.origin.x = CGRectGetMaxX(_dropDownLbl.frame)+5;
   // _arrowImage.frame = rect;
    
    if([string isEqualToString:@"Metronome"]) {
        clapFlag3 = 0;
       
        //[_instBtn3 setSelected:YES];
       // [_instBtn3 setImage:[UIImage imageNamed:@"Claps4_Blue.png"] forState:UIControlStateSelected];
    }
    else {
        clapFlag3 = 1;
       // [_instBtn3 setSelected:NO];
    }
     [self clap3Clicked:clap3ImageView];
}
// enable/dissable Genre label
-(void)enableDropDownLbl:(BOOL)value {
    if (value) {
        _dropDownLbl.alpha = 1;
        _arrowImage.alpha = 1;
        _genreBGView.userInteractionEnabled = YES;
    }
    else {
        _dropDownLbl.alpha = 0.5;
        _arrowImage.alpha = 0.5;
        _genreBGView.userInteractionEnabled = NO;
    }
}
#pragma mark - volume changed action
- (void)volumeChanged:(CGFloat)value {
    [mixerController setOutputVolume:value];
    //[mixerController setMetronomeVolume:value];  //sn
}

#pragma mark - Reset Methods
- (void) resetBeatMeterImages {
    for (int i = 0; i < 12; i++) {
        UIImageView *grayBeatImg = (UIImageView*)[self.beatsView viewWithTag:i];
        [grayBeatImg setImage:[UIImage imageNamed:@"beat_ball_grey"]];
    }
    seconds = 0;
    minutes = 0;
}
#pragma mark - Play audio file methods
- (void) playAudioFile {
    
    [MainNavigationViewController trimClickFile:mCurrentScore];
    [self performSelector:@selector(prepareAudioFiles) withObject:self afterDelay:0.1];
}


- (void) prepareAudioFiles {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"enablePagingNotification"
                                                        object:@"NO"];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    NSMutableArray *audioArray = [[NSMutableArray alloc]init];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    RhythmClass *rhytmObj = appDelegate.latestRhythmClass;
    NSString *fileLocation;
    NSString *volume;
    NSDictionary *dct;
    //NSNumber *rhythmBpm = [NSNumber numberWithInt:currentBpm];
    NSNumber *rhythmBpm = [NSNumber numberWithInt:mCurrentScore];
    
    //NSLog(@"the nill value: %@",rhytmObj.rhythmBPM);
    if (![rhytmObj.rhythmBeatOne isEqualToString:@"-1"]) {
        fileLocation = [self locationOfFileWithName:beatOneMusicFile];
        volume = playerVolume(clapFlag1);
        dct = [self getTheDictionaryWithFileLocation:fileLocation
                                              volume:volume
                                                 bpm:rhytmObj.rhythmBPM
                                         andStartBPM:rhythmBpm
                                            fileType:@"beatOne"];
        [audioArray addObject:dct];
    }
    if (![rhytmObj.rhythmBeatTwo isEqualToString:@"-1"]) {
        fileLocation = [self locationOfFileWithName:beatTwoMusicFile];
        volume = playerVolume(clapFlag2);
        dct = [self getTheDictionaryWithFileLocation:fileLocation
                                              volume:volume
                                                 bpm:rhytmObj.rhythmBPM
                                         andStartBPM:rhythmBpm
                                            fileType:@"beatTwo"];
        [audioArray addObject:dct];
    }
    //fileLocation = [self locationOfFileWithName:@"Click Accented.wav"];
    fileLocation = [MainNavigationViewController getAbsDocumentsPath:@"Click.m4a"];
    volume = playerVolume(clapFlag3);
    dct = [self getTheDictionaryWithFileLocation:fileLocation
           //volume:@"0.0"
                                          volume:volume
                                             bpm:rhytmObj.rhythmBPM
                                     andStartBPM:rhythmBpm
                                        fileType:@"metronome"];
    [audioArray addObject:dct];
    
    // Get the drone location from droneArray with _droneType
    DroneName *dronObj = [droneNames objectAtIndex:[droneArray indexOfObject:_droneType]];
    
    fileLocation = [self locationOfFileWithName:[NSString stringWithFormat:@"%@.m4a", dronObj.droneLocation]];
    //fileLocation = [self locationOfFileWithName:[NSString stringWithFormat:@"C.wav"]];
    //NSLog(@"The file location: %@",fileLocation);
    volume = playerVolume(clapFlag4);
    dct = [self getTheDictionaryWithFileLocation:fileLocation
                                          volume:volume
                                             bpm:rhytmObj.rhythmBPM
                                     andStartBPM:rhythmBpm
                                        fileType:@"drone"];
    //NSLog(@"The dictionay is: %@",dct[@"fileLocation"]);
    [audioArray addObject:dct];
    
    audioUnitCount = (UInt32)audioArray.count;
    //[mixerController stopAUGraph];
    [mixerController fillBuffers:audioArray andNumberOfBus:(unsigned)audioArray.count];
    [mixerController initializeAUGraph];
    
    for (int i = 0; i<audioArray.count;i++) {
        NSDictionary *dict = [audioArray objectAtIndex:i];
        [mixerController setInputVolume:(unsigned)i value:(Float32)[[dict valueForKey:@"volume"] floatValue]];
    }
    if(stopFlag == 1) {
//        if(![_micSwitch isHidden]) {
//            [_micLabel  setEnabled:NO];
//            [_micSwitch setEnabled:NO];
//        }
        
        [audioRecorder startAudioRecording:@"MyAudioMemo.wav"];
        if(inputMic == kUserInput_BuiltIn) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                for (_input in [_session availableInputs]) {
                    // set as an input the build-in microphone
                    
                    if ([_input.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
                        _myPort = _input;
                        break;
                    }
                }
                
                [_session setPreferredInput:_myPort error:nil];
            });
        }
    }
    
    [mixerController initializeAudioForMetronome];
    
    //if(stopFlag == 1)
    // [self playAudioWithClick];
    // else
    [self performSelector:@selector(playAfterDelay) withObject:self afterDelay:1.0];
}

- (void)playAfterDelay {
    if (playFlag == 0)
        return;
    //    [mixerController stopAUGraph];
    //----------------------------------------------
//    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    RhythmClass *rhytmObj = appDelegate.latestRhythmClass;
    
//    if(isMetronome) {
//        tempoVal = 1.0f;
//    } else {
//        tempoVal = mCurrentScore/[rhytmObj.rhythmBPM floatValue];
//    }
//    
//    [mixerController setCurrentBpm:mCurrentScore];
//    [mixerController changePlaybackRate:tempoVal];
    //-----------------------------------------------
    
    //[self performSelectorInBackground:@selector(startAUGraph) withObject:nil];
    //[self performSelector:@selector(startAUGraph) withObject:self afterDelay:0.105];
    
    //     Recording audio button selected
    if (stopFlag == 1) {
        
        [_recordTimer invalidate];
        _recordTimer = nil;
        _recordTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0f
                                                        target: self
                                                      selector:@selector(onPlayTimer:)
                                                      userInfo: nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_recordTimer forMode:NSRunLoopCommonModes];
        
        //[_recordTimer fire];
        
        redCounter = 1;
        counter = 0;
        //        [audioRecorder startAudioRecording:@"MyAudioMemo.wav"];
        
        [self startAUGraph];
        [audioRecorder startRecording];
        
        if ([_recImgTimer isValid]) {
            [_recImgTimer invalidate];
        }
        _recImgTimer = nil;
        float beatFrequency = 60.0 / mCurrentScore;
        UIImageView *beatImg = (UIImageView*)[self.beatsView viewWithTag:0];
        [beatImg setImage:[UIImage imageNamed:@"beat_ball_red.png"]];
        if (!_recImgTimer) {
            _recImgTimer = [NSTimer scheduledTimerWithTimeInterval:beatFrequency target:self selector:@selector(changeRecBeatImages) userInfo:nil repeats:YES];
        }
    }
    else {
        [self startAUGraph];
        counter = 1;
        grayCounter = beatCount;
        for (int i = 0; i < 12; i++) {
            UIImageView *grayBeatImg = (UIImageView*)[self.beatsView viewWithTag:i];
            i == 0 ? [grayBeatImg setImage:[UIImage imageNamed:@"beat_ball_green.png"]] : [grayBeatImg setImage:[UIImage imageNamed:@"beat_ball_grey"]];
        }
        [self changeBeatMeterImages];
        
//        [_playTimer invalidate];
//        _playTimer = nil;
//        seconds = 0;
//        minutes = 0;
//        _playTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0f
//                                                      target: self
//                                                    selector:@selector(onPlayTimer:)
//                                                    userInfo: nil repeats:YES];
//        [[NSRunLoop mainRunLoop] addTimer:_playTimer forMode:NSRunLoopCommonModes];
        //[_playTimer fire];
    }
    
//    if(clapFlag3 == 0) {
//        [mixerController setMetronomeVolume:0.0f];
//    } else {
//        [mixerController setMetronomeVolume:1.0f];
//    }
    
    _playBtn.userInteractionEnabled = YES;
    if(stopFlag == 1)
        [self performSelector:@selector(enableRecordingButton) withObject:self afterDelay:1.0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChanged:) name:@"AUDIOROUTECHANGE" object:nil];

}

- (void) enableRecordingButton {
    _stopBtn.userInteractionEnabled = YES;
}

-(void)startRecord{
    //    [audioRecorder startAudioRecording:@"MyAudioMemo.wav"];
    [audioRecorder startRecording];
}
-(void)startAUGraph{
    [mixerController startAUGraph];
    
}
- (NSDictionary*)getTheDictionaryWithFileLocation:(NSString*)locaiton
                                           volume:(NSString*)volume
                                              bpm:(NSNumber*)rhythmBpmValue
                                      andStartBPM:(NSNumber *)rhythmStartBPMValue
                                         fileType:(NSString*)type{
    return @{@"fileLocation":locaiton,
             @"volume":volume,
             @"bpm":rhythmBpmValue,
             @"startbpm":rhythmStartBPMValue,
             @"type":type};
}
- (NSString*)locationOfFileWithName:(NSString*)fileName{
    
//    if([fileName isEqualToString:@"Indian/Sync 1.m4a"]){
//        fileName = @"Indian/Click AccentedNew.wav";
//        isMetronome = true;
//    }
//    if([fileName isEqualToString:@"Indian/Sync 2.m4a"]){
//        fileName = @"Indian/Click120.m4a";
//        isMetronome = true;
//    }
    
    NSArray* array = [fileName componentsSeparatedByString:@"/"];
    NSString *beatFilePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], array.lastObject];
    //    beatFilePath = [beatFilePath stringByReplacingOccurrencesOfString:@"m4a"
    //                                                          withString:@"wav"];
    return beatFilePath;
}

- (void)stopAudioFiles {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"enablePagingNotification"
                                                        object:@"YES"];
    [UIApplication sharedApplication].idleTimerDisabled = NO;   //sn
    
    [mixerController stopAUGraph:YES];
}
- (void)resetAllTimers {
    [beatTimer invalidate];
    beatTimer = nil;
    [_recordTimer invalidate]; // reset record and play timer after view dismiss
    _recordTimer = nil;
    [_playTimer invalidate];
    _playTimer = nil;
    [_recImgTimer invalidate];
    _recImgTimer = nil;
}

@end