//
//  SavedListDetailViewController.m
//  FlamencoRhythm
//
//  Created by Ashish Gore on 21/05/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import "SavedListDetailViewController.h"
#import "RAAlertController.h"
#import "MainNavigationViewController.h"
#import "AppDelegate.h"
#import "MultichannelMixerController.h"
#import "MHRotaryKnob.h"
#import "DroneName.h"
#import "AudioRecorderManager.h"
#import "TimeStretcher.h"
#import "PureLayout.h"
#import "Constants.h"

#define kChannels   2
#define kOutputBus  0
#define kInputBus   1

#define MAX_VOL 100.0f

enum MixerInputParams { kMixerParam_Vol, kMixerParam_Pan };
enum UserInputActions { kUserInput_Tap, kUserInput_Swipe };

@interface SavedListDetailViewController ()<MainNavigationViewControllerDelegate>
{
    MultichannelMixerController *mixerController;
    AudioRecorderManager *audioRecorder;
    TimeStretcher *timeStretcher;
    UInt32 audioUnitCount;
    UIAlertView *waitAlertView;
    UIActivityIndicatorView *waitActivityView;
    int mixerInputParam;
    BOOL isPurchaseRestored;
    NSArray *rotataryViewsArray;
    UIView *headPhoneMic;
    UILabel *headPhoneLabel;
    NSLayoutConstraint *headPhoneDropdownViewWidthConstraint;
}

@property (strong, nonatomic) RAAlertController *alertController;
@property (nonatomic, strong) UIPopoverController *activityPopoverController;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotatryClap1;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotatryClap2;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotatryClap3;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotataryClap4;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotatryT1;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotatryT2;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotatryT3;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotatryT4;

@end

@implementation SavedListDetailViewController

#pragma mark - View management

-(void)viewDidDisappear:(BOOL)animated {
    
    if (!_closeButtonClicked) {
        [self.delegate expandedCellWillCollapse];
    }
    
    if (playFlag == 1) {
        [self.playRecBtn sendActionsForControlEvents: UIControlEventTouchUpInside];
    }
    
//    if(stopFlag == 1) {
//        NSLog(@"stopppp\n");
//        [audioRecorder stopAudioRecording];
//        [self stopAudioFiles];
//    }
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

//This was in viewWillDisappear.
- (void)updateRecordingTable {
    [sqlManager updateFlagValueOfRecordID:recordID instr1:[NSNumber numberWithBool:clapFlag1] instr2:[NSNumber numberWithBool:clapFlag2] instr3:[NSNumber numberWithBool:clapFlag3] instr4:[NSNumber numberWithBool:clapFlag4] t1:[NSNumber numberWithBool:recFlag1 ] t2:[NSNumber numberWithBool:recFlag2 ] t3:[NSNumber numberWithBool:recFlag3 ] t4:[NSNumber numberWithBool:recFlag4]];
    
    [sqlManager updateVolumesofRecordID:recordID instr1Vol:[NSNumber numberWithInt:instrV1] instr2Vol:[NSNumber numberWithInt:instrV2] instr3Vol:[NSNumber numberWithInt:instrV3] instr4Vol:[NSNumber numberWithInt:instrV4] track1Vol:[NSNumber numberWithInt:tV1] trackVol2:[NSNumber numberWithInt:tV2] track3Vol:[NSNumber numberWithInt:tV3] track4Vol:[NSNumber numberWithInt:tV4]];
    
    [sqlManager updatePanofRecordID:recordID instr1Pan:[NSNumber numberWithInt:instrP1] instr2Pan:[NSNumber numberWithInt:instrP2] instr3Pan:[NSNumber numberWithInt:instrP3] instr4Pan:[NSNumber numberWithInt:instrP4] track1Pan:[NSNumber numberWithInt:tP1] trackPan2:[NSNumber numberWithInt:tP2] track3Pan:[NSNumber numberWithInt:tP3] track4Pan:[NSNumber numberWithInt:tP4]];
    
    [self resetVolImages];
    [self resetPlayButtonWithCell];
}

- (void)deleteTempBeatFiles:(NSArray*)beatsArray {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for(NSString* beatFile in beatsArray) {
        
        NSString* beatDocPath = [MainNavigationViewController getAbsDocumentsPath:[beatFile lastPathComponent]];
        
        if ([fileManager fileExistsAtPath:beatDocPath]) {
            [fileManager removeItemAtPath:beatDocPath error:nil];
            NSString* beatFileWav = [beatDocPath stringByDeletingPathExtension];
            beatFileWav = [beatFileWav stringByAppendingPathExtension:@"wav"];
            [fileManager removeItemAtPath:beatFileWav error:nil];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(_recordingData != nil){
        [self setDataForUIElements:0 RecordingData:_recordingData];
    }
    [self setUIElements];
   
    mixerInputParam = kMixerParam_Vol;
    _volumeBtn.tintColor = UIColorFromRGB(FONT_BLUE_COLOR);
    _panBtn.tintColor = [UIColor blackColor];
    
    [_panBtn.titleLabel setFont:[UIFont fontWithName:FONT_LIGHT size:15]];
    [_volumeBtn.titleLabel setFont:[UIFont fontWithName:FONT_MEDIUM size:15]];
    
    rotataryViewsArray = [[NSArray alloc] initWithObjects:_rotatryClap1,_rotatryClap2,_rotatryClap3,_rotataryClap4,_rotatryT1,_rotatryT2,_rotatryT3,_rotatryT4, nil];
    
    for (MHRotaryKnob *rotaryKnob in rotataryViewsArray)
        [self initializeRotatryViews:rotaryKnob];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self trimRequiredAudioFiles];
    });
    
    _closeButtonClicked = NO;
    
    if ([self.shareCheckString isEqualToString:@"opened"])
        self.shareCheckString = @"comeback";
    else
        self.shareCheckString = @"sameclass";
    
    [self changeMicrophoneSettings];
}

-(void)viewWillDisappear:(BOOL)animated {
    [audioRecorder stopAudioRecording];
    [self updateRecordingTable];
    
    NSArray* beatsArray = [[NSArray alloc] initWithObjects:clap1Path, clap2Path, nil];
    [self deleteTempBeatFiles:beatsArray];
}

-(void)trimAudioFilesOnBackThread{
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    [queue addOperationWithBlock:^{
        [self trimRequiredAudioFiles];
    }];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    int img1 = 1, img2 = 1;
    
    // Set Image
    if (![rhythmRecord.rhythmInstOneImage isEqualToString:@"-1"]) {
        
        [_instrument1 setHidden:NO];
        [_rotatryClap1 setHidden:NO];
        
        NSArray *listItems = [rhythmRecord.rhythmInstOneImage componentsSeparatedByString:@"."];
        NSString *lastWordString = [NSString stringWithFormat:@"%@", listItems.firstObject];
        
        [_instrument1 setImage:[UIImage imageNamed:rhythmRecord.rhythmInstOneImage] forState:UIControlStateSelected];
        [_instrument1 setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@_disabled.png",lastWordString]] forState:UIControlStateNormal];
        
        img1 = 1;
        
    } else {
        [_instrument1 setHidden:YES];
        [_rotatryClap1 setHidden:YES];
        clapFlag1 = 0;
        img1 = 0;
    }
    
    if (![rhythmRecord.rhythmInstTwoImage isEqualToString:@"-1"]) {
        [_instrument2 setHidden:NO];
        [_rotatryClap2 setHidden:NO];
        
        NSArray *listItems = [rhythmRecord.rhythmInstTwoImage componentsSeparatedByString:@"."];
        NSString *lastWordString = [NSString stringWithFormat:@"%@", listItems.firstObject];
        
        [_instrument2 setImage:[UIImage imageNamed:rhythmRecord.rhythmInstTwoImage] forState:UIControlStateSelected];
        [_instrument2 setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@_disabled.png",lastWordString]] forState:UIControlStateNormal];
        
        img2 = 1;
        
    } else {
        [_instrument2 setHidden:YES];
        [_rotatryClap2 setHidden:YES];
        clapFlag2 = 0;
        img2 = 0;
    }
    
    CGRect visibleSize = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = visibleSize.size.width;
    int xDist = 0;  // for 320
    
    // If only 2 buttons are there
    if ((img1 == 0) && (img2 == 0)) {
        xDist = ((screenWidth - 120) / 3);
        _audioPlayerClap1 = nil;
        _audioPlayerClap2 = nil;
        _instrument3.frame = CGRectMake(xDist, _instrument3.frame.origin.y, 60, 60);
        _instrument4.frame = CGRectMake((xDist*2)+60, _instrument4.frame.origin.y, 60, 60);
        _volImageInstru3.center = _instrument3.center;
        _volImageInstru4.center = _instrument4.center;
        _rotatryClap3.center = _instrument3.center;
        _rotataryClap4.center = _instrument4.center;
        
    } else if (img1 == 0) {
        
        xDist = ((screenWidth - 180) / 4);
        _audioPlayerClap1 = nil;
        _instrument2.frame = CGRectMake(xDist, _instrument2.frame.origin.y, 60, 60);
        _instrument3.frame = CGRectMake((xDist*2)+60, _instrument3.frame.origin.y, 60, 60);
        _instrument4.frame = CGRectMake((xDist*3)+120, _instrument4.frame.origin.y, 60, 60);
        _volImageInstru2.center = _instrument2.center;
        _volImageInstru3.center = _instrument3.center;
        _volImageInstru4.center = _instrument4.center;
        _rotatryClap2.center = _instrument2.center;
        _rotatryClap3.center = _instrument3.center;
        _rotataryClap4.center = _instrument4.center;
        
    } else if (img2 == 0) {
        
        xDist = ((screenWidth - 180) / 4);
        _audioPlayerClap2 = nil;
        _instrument1.frame = CGRectMake(xDist, _instrument1.frame.origin.y, 60, 60);
        _instrument3.frame = CGRectMake((xDist*2)+60, _instrument3.frame.origin.y, 60, 60);
        _instrument4.frame = CGRectMake((xDist*3)+120, _instrument4.frame.origin.y, 60, 60);
        _volImageInstru1.center = _instrument1.center;
        _volImageInstru3.center = _instrument3.center;
        _volImageInstru4.center = _instrument4.center;
        
        _rotatryClap1.center = _instrument1.center;
        _rotatryClap3.center = _instrument3.center;
        _rotataryClap4.center = _instrument4.center;

    } else {
        xDist = ((screenWidth - 240) / 5);
        _instrument1.frame = CGRectMake(xDist, _instrument1.frame.origin.y, 60, 60);
        _instrument2.frame = CGRectMake((xDist*2)+60, _instrument2.frame.origin.y, 60, 60);
        _instrument3.frame = CGRectMake((xDist*3)+120, _instrument3.frame.origin.y, 60, 60);
        _instrument4.frame = CGRectMake((xDist*4)+182, _instrument4.frame.origin.y, 60, 60);
        _volImageInstru1.center = _instrument1.center;
        _volImageInstru2.center = _instrument2.center;
        _volImageInstru3.center = _instrument3.center;
        _volImageInstru4.center = _instrument4.center;
        
        _rotatryClap1.center = _instrument1.center;
        _rotatryClap2.center = _instrument2.center;
        _rotatryClap3.center = _instrument3.center;
        _rotataryClap4.center = _instrument4.center;
    }
    
    if ([_recTrackOne isEqualToString:@"-1"]) {
        
        [_firstVolumeKnob setBackgroundImage:[UIImage imageNamed:@"one_redoutline.png"] forState:UIControlStateNormal];
        [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_greyoutline.png"] forState:UIControlStateNormal];
        [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_greyoutline.png"] forState:UIControlStateNormal];
        [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
        [_rotatryT1 setHidden:YES];
        [_rotatryT2 setHidden:YES];
        [_rotatryT3 setHidden:YES];
        [_rotatryT4 setHidden:YES];
    }
    else if ([_recTrackTwo isEqualToString:@"-1"]) {
        
        [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_redoutline.png"] forState:UIControlStateNormal];
        [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_greyoutline.png"] forState:UIControlStateNormal];
        [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
        
        [_rotatryT2 setHidden:YES];
        [_rotatryT3 setHidden:YES];
        [_rotatryT4 setHidden:YES];
    }
    else if ([_recTrackThree isEqualToString:@"-1"]) {
       // NSLog(@" _recTrackThree three_redoutline ");
        [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_redoutline.png"] forState:UIControlStateNormal];
        [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
        [_rotatryT3 setHidden:YES];
        [_rotatryT4 setHidden:YES];
    }
    else if ([_recTrackFour isEqualToString:@"-1"]) {
        
        [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_redoutline.png"] forState:UIControlStateNormal];
        [_rotatryT4 setHidden:YES];
    }
    
    if (![_recTrackOne isEqualToString:@"-1"]) {
        
        [_firstVolumeKnob setBackgroundImage:[UIImage imageNamed:@"one_blue.png"] forState:UIControlStateSelected];
        [_rotatryT1 setHidden:NO];
    }
    if (![_recTrackTwo isEqualToString:@"-1"]) {
        
        [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_blue.png"] forState:UIControlStateSelected];
        [_rotatryT2 setHidden:NO];
        
    }
    if (![_recTrackThree isEqualToString:@"-1"]) {
        
        [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_blue.png"] forState:UIControlStateSelected];
        [_rotatryT3 setHidden:NO];
    }
    if (![_recTrackFour isEqualToString:@"-1"]) {
        
        [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_blue.png"] forState:UIControlStateSelected];
        [_rotatryT4 setHidden:NO];
    }
    
    if (![droneName isEqualToString:@"-1"]) {
        
        [_instrument4 setTitle:droneName forState:UIControlStateNormal];
        [_instrument4 setTitle:droneName forState:UIControlStateSelected];
    }
    
    _instrument1.selected = clapFlag1;
    [self setRotaryKnobImage:_rotatryClap1 isSelected:_instrument1.isSelected];
    
    _instrument2.selected = clapFlag2;
    [self setRotaryKnobImage:_rotatryClap2 isSelected:_instrument2.isSelected];
    
    _instrument3.selected = clapFlag3;
    [self setRotaryKnobImage:_rotatryClap3 isSelected:_instrument3.isSelected];

    _instrument4.selected = clapFlag4;
    [self setRotaryKnobImage:_rotataryClap4 isSelected:_instrument4.isSelected];
    [self setDroneTitleColor:(_instrument4.selected) ? [UIColor whiteColor]   : [UIColor blackColor]
                    forState:(_instrument4.selected) ? UIControlStateSelected : UIControlStateNormal];

    _firstVolumeKnob.selected = recFlag1;
    [self setRotaryKnobImage:_rotatryT1 isSelected:_firstVolumeKnob.isSelected];

    _secondVolumeKnob.selected = recFlag2;
    [self setRotaryKnobImage:_rotatryT2 isSelected:_secondVolumeKnob.isSelected];
    
    _thirdVolumeKnob.selected = recFlag3;
    [self setRotaryKnobImage:_rotatryT3 isSelected:_thirdVolumeKnob.isSelected];

    _fourthVolumeKnob.selected = recFlag4;
    [self setRotaryKnobImage:_rotatryT4 isSelected:_fourthVolumeKnob.isSelected];
   // NSLog(@"_thirdVolumeKnob back ground image %@ = ",_thirdVolumeKnob.currentBackgroundImage.CGImage);
}

-(void)setInstuemntsAndKnobs{
    _instrument1.selected = clapFlag1;
    _instrument2.selected = clapFlag2;
    _instrument3.selected = clapFlag3;
    _instrument4.selected = clapFlag4;
    
    _firstVolumeKnob.selected = recFlag1;
    _secondVolumeKnob.selected = recFlag2;
    _thirdVolumeKnob.selected = recFlag3;
    _fourthVolumeKnob.selected = recFlag4;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    sqlManager = [[DBManager alloc] init];
    mixerController = [[MultichannelMixerController alloc]init];
    
    // Creating AudioRecorderManager class
    audioRecorder = [AudioRecorderManager SharedManager];
    
    [self initializeGestures];
    
    audioPlayerArray = [[NSMutableArray alloc] init];
    
    
    _musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
    
    [_musicPlayer beginGeneratingPlaybackNotifications];
    
    _myPort = nil;
    
    // Setup MPVolumeView not to show on main screen
    [self setUpMPVolumeView];
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    _session = [AVAudioSession sharedInstance];
    // [_session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    for (_input in [_session availableInputs]) {
        // set as an input the build-in microphone
        
        if ([_input.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
            _myPort = _input;
            break;
        }
    }
    
    [_session setPreferredInput:_myPort error:nil];
    
    [self registerForMediaPlayerNotifications];
    
    audioUnitCount = 0;
    
    //============== Change this =========================
   
//    if(![MainNavigationViewController inAppPurchaseEnabled]) {
//        self.recordingBtn.alpha =  0.3;
//    } else {
//        self.recordingBtn.alpha =  1.0;
//    }
    
    self.recordingBtn.alpha =  1.0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioFilePlayedOnce:) name:@"AUDIOFILENOTLOOPING" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChanged:) name:@"AUDIOROUTECHANGE" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopAudioPlayer:)
                                                 name:@"stopAudioPlayerNotification"
                                               object:nil];
    
    timeStretcher = [[TimeStretcher alloc] init];
    
    
    waitAlertView = [[UIAlertView alloc] initWithTitle:@"Please wait..." message:nil
                                            delegate:self
                                   cancelButtonTitle:nil
                                   otherButtonTitles:nil, nil];

    waitActivityView = [[UIActivityIndicatorView alloc]
                                             initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    waitActivityView.center = self.view.center;
    
    isPurchaseRestored = NO;
    mixerInputParam = kMixerParam_Vol;
    _panBtn.tintColor = [UIColor blackColor];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTapped:)];
    [_recSlider addGestureRecognizer:tapGestureRecognizer];
    
    [_recSlider addTarget:self action:@selector(sliderDragged:)forControlEvents:UIControlEventTouchDragInside|UIControlEventTouchDragOutside];
    
    //[_backButton addTarget:self action:@selector(backButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [_backButton setTitle:@"" forState:UIControlStateNormal];
    [self setFontsForAllLabels];
    [self addNavigationTopSeprator];
    [self addHeadPhoneMicDropButton];
    
    [self changeMicrophoneSettings];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideMicSwitch:)
                                                 name:@"HIDEMICSWITCH"
                                               object:nil];
}

-(void)addNavigationTopSeprator{
    UIView *seprator = [[UIView alloc]init];
    [self.view addSubview:seprator];
    seprator.backgroundColor = UIColorFromRGB(GRAY_COLOR);
    [seprator autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:30];
    [seprator autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [seprator autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:67];
    [seprator autoSetDimension:ALDimensionHeight toSize:0.5];
    [_cellTopSeprator removeFromSuperview];
}

//-(void)backButtonClicked:(id)sender {
//    [self updateRecordingTable];
//}

- (IBAction)backToRecordingList:(id)sender {
     [self.myNavigationController goBackToSoundListing];
}

-(void)setFontsForAllLabels {
    _songDetailLbl.font = [UIFont fontWithName:FONT_REGULAR size:15];
    _dateLbl.font = [UIFont fontWithName:FONT_LIGHT size:10];
    _TotalTimeLbl.font = [UIFont fontWithName:FONT_LIGHT size:10];
    _songDetailLbl.font = [UIFont fontWithName:FONT_LIGHT size:10];
    _recordingTimeLabel.font = [UIFont fontWithName:FONT_LIGHT size:30];
    [_panBtn.titleLabel setFont:[UIFont fontWithName:FONT_LIGHT size:15]];
    [_volumeBtn.titleLabel setFont:[UIFont fontWithName:FONT_MEDIUM size:15]];
    [_maxRecDurationLbl setFont:[UIFont fontWithName:FONT_LIGHT size:10]];
    [_minRecDurationLbl setFont:[UIFont fontWithName:FONT_LIGHT size:10]];
}

-(void)hideMicSwitch:(NSNotification *)notification{
    NSString *hideMicSwitch = [notification object];
    if([hideMicSwitch isEqualToString:@"NO"]) {
        [headPhoneMic setHidden:NO];
        [self setSelectedMicrophone:kUserInput_Headphone];
    } else {
        [headPhoneMic setHidden:YES];
        [self setSelectedMicrophone:kUserInput_BuiltIn];
    }
}

-(void)micShow {
    headPhoneMic.userInteractionEnabled = YES;
    headPhoneMic.alpha = 1.0f;
}

-(void)micHide {
    headPhoneMic.userInteractionEnabled = NO;
    headPhoneMic.alpha = 0.3f;
}

-(void)addHeadPhoneMicDropButton{
    headPhoneMic = [[UIView alloc]init];
    [self.view addSubview:headPhoneMic];
    
    headPhoneLabel = [[UILabel alloc]init];
    [headPhoneMic addSubview:headPhoneLabel];
    headPhoneLabel.text = @"Headphone Mic";
    headPhoneLabel.font = [UIFont fontWithName:FONT_REGULAR size:9];
    headPhoneLabel.textColor = UIColorFromRGB(FONT_BLUE_COLOR);
    [headPhoneLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:5];
    [headPhoneLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    
    UIImageView *dropDownImageView = [[UIImageView alloc]init];
    dropDownImageView.image = [UIImage imageNamed:@"dropdown"];
    [dropDownImageView autoSetDimensionsToSize:CGSizeMake(6, 4)];
    [headPhoneMic addSubview:dropDownImageView];
    [dropDownImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:5];
    [dropDownImageView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    
    [headPhoneMic autoAlignAxis:ALAxisVertical toSameAxisOfView:_recordingBtn];
    [headPhoneMic autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_recordingBtn withOffset:0];
    [headPhoneMic autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:6];
    headPhoneDropdownViewWidthConstraint =  [headPhoneMic autoSetDimension:ALDimensionWidth toSize:84];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(headPhoneOptions:)];
    [headPhoneMic addGestureRecognizer:gestureRecognizer];
}

-(void)headPhoneOptions:(id)sender{
    DLog(@"headPhoneOptions");
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Built In Mic" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        headPhoneDropdownViewWidthConstraint.constant = 64;
        headPhoneLabel.text = @"Built In Mic";
        [self setSelectedMicrophone:kUserInput_BuiltIn];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Headphone Mic" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        headPhoneDropdownViewWidthConstraint.constant = 84;
        headPhoneLabel.text = @"Headphone Mic";
        [self setSelectedMicrophone:kUserInput_Headphone];
    }]];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (BOOL)isHeadphoneConnected {
    return [MainNavigationViewController isHeadphonePlugged];
}

- (void)setSelectedMicrophone:(int)inputMic {
    [MainNavigationViewController setSelectedInputMic:inputMic];
}

- (int)getSelectedMicrophone {
    return [MainNavigationViewController getSelectedInputMic];
}

- (NSString *)getAbsoluteBundlePath:(NSString *)fileName {
    return [MainNavigationViewController getAbsBundlePath:fileName];
}

- (NSString *)getAbsoluteDocumentsPath:(NSString *)fileName {
    return [MainNavigationViewController getAbsDocumentsPath:fileName];
}

- (void)changeMicrophoneSettings {
    
    if(![self isHeadphoneConnected]) {
        headPhoneMic.hidden = YES;
        [self setSelectedMicrophone:kUserInput_BuiltIn];
    }
    else {
        headPhoneMic.hidden = NO;
        
        int selectedMic = [self getSelectedMicrophone];
        [self setSelectedMicrophone:selectedMic];
        
        if(selectedMic == kUserInput_Headphone) {
            headPhoneLabel.text = @"Headphone Mic";
            headPhoneDropdownViewWidthConstraint.constant = 84;
        }
        else {
            headPhoneLabel.text = @"Built In Mic";
            headPhoneDropdownViewWidthConstraint.constant = 64;
        }
    }
}

- (void)stopAudioPlayer:(NSNotification *)notification {
    if(playFlag == 1) {
        [self stopAudioFiles];
        [self resetPlayButtonWithCell];
    }
}

- (void)sliderTapped:(UIGestureRecognizer *)gestureRecognizer {
    if(playFlag == 0) return;
    
    CGPoint pointTapped = [gestureRecognizer locationInView:gestureRecognizer.view];
    CGFloat percentage = pointTapped.x / gestureRecognizer.view.bounds.size.width;
    CGFloat delta = percentage * (_recSlider.maximumValue - _recSlider.minimumValue);
    CGFloat value = _recSlider.minimumValue + delta;
    [_recSlider setValue:value animated:YES];
    
    [self updateSliderOnDragAndTouch];
}

- (void)sliderDragged:(id)sender
{
    if(playFlag == 0) return;
        
    [self updateSliderOnDragAndTouch];
}

- (void)updateSliderOnDragAndTouch {
    if (_updateSliderTimer != nil) {
        [_updateSliderTimer invalidate];
        _updateSliderTimer = nil;
    }
    
    seconds = [_recSlider value];
    
    [self stopMixerAfterSeeking];
    [self seekToSeconds:seconds];
    [self startMixerAfterSeeking];
    
    _updateSliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                          target:self
                                                        selector:@selector(resetSliderOnSeek:)
                                                        userInfo:nil
                                                         repeats:YES];
}

-(void)resetSliderOnSeek:(NSTimer *)timer {
    NSString *maxDuration = [self timeFormatted:[durationStringUnFormatted floatValue] - seconds];
    [self configureSliderValues:@{@"MINDURATION":[self timeFormatted:seconds],@"MAXDURATION":maxDuration}];
    _recSlider.value = seconds;
    
    if ([maxDuration isEqualToString:@"00:00"]) {
        _maxRecDurationLbl.text =  @"-00:01";
    }
    
    if ([durationStringUnFormatted floatValue] - seconds < 0.0) {
        [self resetPlayButtonWithCell];
    }
    
    seconds += 0.1f;
}

-(void)seekToSeconds:(int)sec {
    [mixerController seekToFrame:sec];
}

-(void)startMixerAfterSeeking {
    [mixerController startAUGraph];
}

-(void)stopMixerAfterSeeking {
    [mixerController stopAUGraph:NO];
}

-(void)audioRouteChanged:(id)sender {
    [self setVolumeInputOutput];
}

-(void)audioFilePlayedOnce:(NSNotification *)sender{
    NSDictionary *dict = (NSDictionary *)sender.object;
    [mixerController enableInput:(UInt32)[dict[@"BUSNUMBER"] intValue] isOn:0.0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIGesture
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer  {
    return YES;
}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender
{
    UIControl *control = sender.view;
    NSLog(@"handle Tap Gestures array %@",sender.view.gestureRecognizers);
    if (control.tag == 1 )
    {
        if (clapFlag1 == 0 ) {
            
            [_instrument1 setSelected:YES];
            
            clapFlag1 = 1;
            
            if(playFlag == 1)
            {
                if (instrV1 == 0)
                    [self setMixerInputParameter:0 value:1/MAX_VOL param:kMixerParam_Vol];
                else
                    [self setMixerInputParameter:0 value:instrV1/MAX_VOL param:kMixerParam_Vol];
            }
        } else {
            [_instrument1 setSelected:NO];
            
            
            clapFlag1 = 0;
            [self setMixerInputParameter:0 value:0 param:kMixerParam_Vol];
        }
    
        [self setRotaryKnobImageForButton:_instrument1 withRotaryKnob:_rotatryClap1];
    }
    
    if (control.tag == 2 )
    {
        if (clapFlag2 == 0) {
            [_instrument2 setSelected:YES];
            clapFlag2 = 1;
            if(playFlag == 1)
            {
                if (instrV2 == 0)
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Tap
                                           withValue:1/MAX_VOL
                                            withName:@"clap2"];
                else
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Tap
                                           withValue:instrV2/MAX_VOL
                                            withName:@"clap2"];
            }
        } else {
            [_instrument2 setSelected:NO];
            clapFlag2 = 0;
            
            [self setInputParamForAudioArray:audioPlayerArray
                              withActionType:kUserInput_Tap
                                   withValue:0
                                    withName:@"clap2"];
        }
        
        [self setRotaryKnobImageForButton:_instrument2 withRotaryKnob:_rotatryClap2];
    }
    
    if (control.tag == 3)
    {
        if (clapFlag3 == 0 ) {
            [_instrument3 setSelected:YES];
            clapFlag3 = 1;
            if(playFlag == 1)
            {
                if (instrV3 == 0)
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Tap
                                           withValue:1/MAX_VOL
                                            withName:@"clap3"];
                else
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Tap
                                           withValue:instrV3/MAX_VOL
                                            withName:@"clap3"];
            }
        } else {
            [_instrument3 setSelected:NO];
            clapFlag3 = 0;
            [self setInputParamForAudioArray:audioPlayerArray
                              withActionType:kUserInput_Tap
                                   withValue:0
                                    withName:@"clap3"];
        }
        
        [self setRotaryKnobImageForButton:_instrument3 withRotaryKnob:_rotatryClap3];
    }
    
    if (control.tag == 4)
    {
        if (clapFlag4 == 0) {
            [_instrument4 setSelected:YES];
            if(playFlag == 1)
            {
                if (instrV4 == 0)
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Tap
                                           withValue:1/MAX_VOL
                                            withName:@"clap4"];
                     
                else
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Tap
                                           withValue:instrV4/MAX_VOL
                                            withName:@"clap4"];
            }
            clapFlag4 = 1;
        } else {
            [_instrument4 setSelected:NO];
            clapFlag4 = 0;
            [self setInputParamForAudioArray:audioPlayerArray
                              withActionType:kUserInput_Tap
                                   withValue:0
                                    withName:@"clap4"];
        }
        
        if([_instrument4 isSelected])
            [self setDroneTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        else
            [self setDroneTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        [self setRotaryKnobImageForButton:_instrument4 withRotaryKnob:_rotataryClap4];
    }
    
    if (control.tag == 5 && ![_recTrackOne isEqualToString:@"-1"]) {
        if (recFlag1 == 0 )
        {
            [_firstVolumeKnob setSelected:YES];
            
            recFlag1 = 1;
            if(playFlag == 1)
            {
                if (tV1 == 0) {
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Tap
                                           withValue:1/MAX_VOL
                                            withName:@"track1"];
                }
                else
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Tap
                                           withValue:tV1/MAX_VOL
                                            withName:@"track1"];
            }
        } else {
            [_firstVolumeKnob setSelected:NO];
            recFlag1 = 0;
            [self setInputParamForAudioArray:audioPlayerArray
                              withActionType:kUserInput_Tap
                                   withValue:0
                                    withName:@"track1"];
        }
        
        [self setRotaryKnobImageForButton:_firstVolumeKnob withRotaryKnob:_rotatryT1];
    }
    
    if (control.tag == 6 && ![_recTrackTwo isEqualToString:@"-1"]) {
        if (recFlag2 == 0) {
            [_secondVolumeKnob setSelected:YES];
            recFlag2 = 1;
            if(playFlag == 1)
            {
                if (tV2 == 0) {
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Tap
                                           withValue:1/MAX_VOL
                                            withName:@"track2"];
                }
                else
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Tap
                                           withValue:tV2/MAX_VOL
                                            withName:@"track2"];
            }
        } else {
            [_secondVolumeKnob setSelected:NO];
            recFlag2 = 0;
            [self setInputParamForAudioArray:audioPlayerArray
                              withActionType:kUserInput_Tap
                                   withValue:0
                                    withName:@"track2"];
        }
        
        [self setRotaryKnobImageForButton:_secondVolumeKnob withRotaryKnob:_rotatryT2];
    }
    
    if (control.tag == 7 && ![_recTrackThree isEqualToString:@"-1"]) {
        if (recFlag3 == 0) {
            [_thirdVolumeKnob setSelected:YES];
            recFlag3 = 1;
            if(playFlag == 1)
            {
                if (tV3 == 0) {
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Tap
                                           withValue:1/MAX_VOL
                                            withName:@"track3"];
                }
                else
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Tap
                                           withValue:tV3/MAX_VOL
                                            withName:@"track3"];
            }
        } else {
            [_thirdVolumeKnob setSelected:NO];
            recFlag3 = 0;
            [self setInputParamForAudioArray:audioPlayerArray
                              withActionType:kUserInput_Tap
                                   withValue:0
                                    withName:@"track3"];
        }
        
        [self setRotaryKnobImageForButton:_thirdVolumeKnob withRotaryKnob:_rotatryT3];
    }
    
    if (control.tag == 8 && ![_recTrackFour isEqualToString:@"-1"]) {
        if (recFlag4 == 0) {
            [_fourthVolumeKnob setSelected:YES];
            recFlag4 = 1;
            if(playFlag == 1)
            {
                if (tV4 == 0) {
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Tap
                                           withValue:1/MAX_VOL
                                            withName:@"track4"];
                }
                else
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Tap
                                           withValue:tV4/MAX_VOL
                                            withName:@"track4"];
            }
        } else {
            [_fourthVolumeKnob setSelected:NO];
            recFlag4 = 0;
            [self setInputParamForAudioArray:audioPlayerArray
                              withActionType:kUserInput_Tap
                                   withValue:0
                                    withName:@"track4"];
        }
        
        [self setRotaryKnobImageForButton:_fourthVolumeKnob withRotaryKnob:_rotatryT4];
    }
}

-(void)setRotaryKnobImageForButton:(UIButton *)button withRotaryKnob:(MHRotaryKnob *)rotaryKnob {
    [self setRotaryKnobImage:rotaryKnob isSelected:[button isSelected]];
}

#pragma mark - notifications

// To learn about notifications, see "Notifications" in Cocoa Fundamentals Guide.
- (void) registerForMediaPlayerNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    // notification for the update mic gain
    [notificationCenter addObserver:self
                           selector:@selector(updateMicGain:)
                               name:@"updateMicGain"
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(handle_NowPlayingItemChanged:)
                               name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
                             object:_musicPlayer];
    
    [notificationCenter addObserver:self
                           selector:@selector(handle_PlaybackStateChanged:)
                               name:MPMusicPlayerControllerPlaybackStateDidChangeNotification
                             object:_musicPlayer];
    
    [_musicPlayer beginGeneratingPlaybackNotifications];
}

#pragma mark -  Music notification handlers

-(void)setUpMPVolumeView {
    _volumeView = [[MPVolumeView alloc] initWithFrame: CGRectMake(-100,-100,16,16)];
    _volumeView.showsRouteButton = NO;
    _volumeView.userInteractionEnabled = NO;
    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] addSubview:_volumeView];
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (![_recorder isRecording]) {
        [self resetPlayButtonWithCell];
    }
}

// When the now-playing item changes, update the media item artwork and the now-playing
- (void) handle_NowPlayingItemChanged: (id) notification {
    
    MPMediaItem *currentItem = [_musicPlayer nowPlayingItem];
    
    // Assume that there is no artwork for the media item.
    UIImage *artworkImage = _noArtworkImage;
    
    // Get the artwork from the current media item, if it has artwork.
    MPMediaItemArtwork *artwork = [currentItem valueForProperty: MPMediaItemPropertyArtwork];
    
    // Obtain a UIImage object from the MPMediaItemArtwork object
    if (artwork) {
        artworkImage = [artwork imageWithSize: CGSizeMake (30, 30)];
    }
    
    // Obtain a UIButton object and set its background to the UIImage object
    UIButton *artworkView = [[UIButton alloc] initWithFrame: CGRectMake (0, 0, 30, 30)];
    [artworkView setBackgroundImage: artworkImage forState: UIControlStateNormal];
    
    // Obtain a UIBarButtonItem object and initialize it with the UIButton object
    UIBarButtonItem *newArtworkItem = [[UIBarButtonItem alloc] initWithCustomView: artworkView];
    [self setArtworkItem: newArtworkItem];
    //    [newArtworkItem release];
    
    [_artworkItem setEnabled: NO];
    
    // Display the new media item artwork
    //  [navigationBar.topItem setRightBarButtonItem: artworkItem animated: YES];
    
    // Display the artist and song name for the now-playing media item
    [_nowPlayingLabel setText: [
                                NSString stringWithFormat: @"%@ %@ %@ %@",
                                NSLocalizedString (@"Now Playing:", @"Label for introducing the now-playing song title and artist"),
                                [currentItem valueForProperty: MPMediaItemPropertyTitle],
                                NSLocalizedString (@"by", @"Article between song name and artist name"),
                                [currentItem valueForProperty: MPMediaItemPropertyArtist]]];
    
    if (_musicPlayer.playbackState == MPMusicPlaybackStateStopped) {
        // Provide a suitable prompt to the user now that their chosen music has
        //		finished playing.
        [_nowPlayingLabel setText: [
                                    NSString stringWithFormat: @"%@",
                                    NSLocalizedString (@"Music-ended Instructions", @"Label for prompting user to play music again after it has stopped")]];
        
    }
}

// When the playback state changes, set the play/pause button in the Navigation bar
//		appropriately.
- (void)handle_PlaybackStateChanged: (id) notification {
    
    MPMusicPlaybackState playbackState = [_musicPlayer playbackState];
    
    if (playbackState == MPMusicPlaybackStatePaused) {
        
        //  navigationBar.topItem.leftBarButtonItem = playBarButton;
        
    } else if (playbackState == MPMusicPlaybackStatePlaying) {
        
        //  navigationBar.topItem.leftBarButtonItem = pauseBarButton;
        
    } else if (playbackState == MPMusicPlaybackStateStopped) {
        
        //  navigationBar.topItem.leftBarButtonItem = playBarButton;
        
        // Even though stopped, invoking 'stop' ensures that the music player will play
        //		its queue from the start.
        [_musicPlayer stop];
        
    }
}

#pragma mark - UIButtonActions------

- (IBAction)menuBtnClicked:(id)sender
{
    menuActionSheet = [[CustomActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Share" otherButtonTitles:@"Delete",nil];
    menuActionSheet.destructiveButtonIndex = 1;
    
    [menuActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (IBAction)shareBtnAction:(id)sender {
}

- (void)itemWasTouchedUpAndDidHold:(id)sender
{
    UIControl *control = sender ;
    int tag = (int)control.tag;
    //NSLog(@"tag = %d",tag);
    
    if(tag == 11)
    {
        control.hidden = YES;
        control.center = secondKnobCentre;
        secondKnob.center = thirdKnobCentre;
        thirdKnob.center = forthKnobCentre;
        forthKnob.center = forthKnobCentre;
        
        [UIView animateWithDuration:0.5
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             // set the new frame
                             control.hidden = NO;
                             control.center = firstKnobCentre;
                             secondKnob.center = secondKnobCentre;
                             thirdKnob.center = thirdKnobCentre;
                             forthKnob.hidden = YES;
                             [_deleteImageT1 setHidden:YES];
                             [_deleteBGView setHidden:YES];
                             [self.view sendSubviewToBack:_firstVolumeKnob];
                         }
                         completion:^(BOOL finished){
                             forthKnob.hidden = NO;
                             forthKnob.center = forthKnobCentre;
                             
                             if ([_recTrackTwo isEqualToString:@"-1"]) {
                                 
                                 recFlag1 = 0;
                                 recFlag2 = 0;
                                 recFlag3 = 0;
                                 recFlag4 = 0;
                                 
                                 [_rotatryT1 setHidden:YES];
                                 [_rotatryT2 setHidden:YES];
                                 [_rotatryT3 setHidden:YES];
                                 [_rotatryT4 setHidden:YES];
                                 
                                 t1Duration = @"-1";
                                 durationStringUnFormatted = @"0.00";
                                 _TotalTimeLbl.text = @"00:00";
                                 _maxRecDurationLbl.text = @"00:00";
                                 
                                 [_firstVolumeKnob setSelected:NO];
                                 [_secondVolumeKnob setSelected:NO];
                                 [_thirdVolumeKnob setSelected:NO];
                                 [_fourthVolumeKnob setSelected:NO];
                                 
                                 [_firstVolumeKnob setBackgroundImage:[UIImage imageNamed:@"one_redoutline.png"] forState:UIControlStateNormal];
                                 [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_greyoutline.png"] forState:UIControlStateNormal];
                                 [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_greyoutline.png"] forState:UIControlStateNormal];
                                 [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
                             }
                             else if ([_recTrackThree isEqualToString:@"-1"])
                             {
                                 recFlag1 = 1;
                                 recFlag2 = 0;
                                 recFlag3 = 0;
                                 recFlag4 = 0;
                                 
                                 [_rotatryT1 setHidden:NO];
                                 [_rotatryT2 setHidden:YES];
                                 [_rotatryT3 setHidden:YES];
                                 [_rotatryT4 setHidden:YES];
                                 
                                 t1Duration = t2Duration;
                                 t3Duration = @"-1";
                                 durationStringUnFormatted = t1Duration;
                                 [self updateUIDataWithDuration:durationStringUnFormatted];
                                 
                                 [_firstVolumeKnob setSelected:YES];
                                 [_secondVolumeKnob setSelected:NO];
                                 [_thirdVolumeKnob setSelected:NO];
                                 [_fourthVolumeKnob setSelected:NO];
                                 
                                 [_firstVolumeKnob setBackgroundImage:[UIImage imageNamed:@"one_darkgrey.png"] forState:UIControlStateNormal];
                                 [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_redoutline.png"] forState:UIControlStateNormal];
                                 [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_greyoutline.png"] forState:UIControlStateNormal];
                                 [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
                             }
                             else if ([_recTrackFour isEqualToString:@"-1"])
                             {
                                 recFlag1 = 1;
                                 recFlag2 = 1;
                                 recFlag3 = 0;
                                 recFlag4 = 0;
                                 
                                 [_rotatryT1 setHidden:NO];
                                 [_rotatryT2 setHidden:NO];
                                 [_rotatryT3 setHidden:YES];
                                 [_rotatryT4 setHidden:YES];
                                 
                                 t1Duration = t2Duration;
                                 t2Duration = t3Duration;
                                 t3Duration = @"-1";
                                 t4Duration = @"-1";
                                 
                                 if ([t2Duration intValue] > [t1Duration intValue]) {
                                     durationStringUnFormatted = t2Duration;
                                 }
                                 else
                                     durationStringUnFormatted = t1Duration;
                                 [self updateUIDataWithDuration:durationStringUnFormatted];
                                 
                                 [_firstVolumeKnob setSelected:YES];
                                 [_secondVolumeKnob setSelected:YES];
                                 [_thirdVolumeKnob setSelected:NO];
                                 [_fourthVolumeKnob setSelected:NO];
                                 [_firstVolumeKnob setBackgroundImage:[UIImage imageNamed:@"one_darkgrey.png"] forState:UIControlStateNormal];
                                 [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_darkgrey.png"] forState:UIControlStateNormal];
                                 [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_redoutline.png"] forState:UIControlStateNormal];
                                 [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
                             }
                             else
                             {
                                 recFlag1 = 1;
                                 recFlag2 = 1;
                                 recFlag3 = 1;
                                 recFlag4 = 0;
                                 
                                 [_rotatryT1 setHidden:NO];
                                 [_rotatryT2 setHidden:NO];
                                 [_rotatryT3 setHidden:NO];
                                 [_rotatryT4 setHidden:YES];
                                 
                                 t1Duration = t2Duration;
                                 t2Duration = t3Duration;
                                 t3Duration = t4Duration;
                                 t4Duration = @"-1";
                                 
                                 
                                 if ([t3Duration intValue] > [t2Duration intValue]) {
                                     if ([t3Duration intValue] > [t1Duration intValue])
                                     {
                                         durationStringUnFormatted = t3Duration;
                                     }
                                     else
                                         durationStringUnFormatted = t1Duration;
                                 }
                                 else if ([t2Duration intValue] > [t1Duration intValue])
                                 {
                                     durationStringUnFormatted = t2Duration;
                                 }
                                 else
                                     durationStringUnFormatted = t1Duration;
                                 
                                 [self updateUIDataWithDuration:durationStringUnFormatted];
                                 
                                 
                                 [_firstVolumeKnob setSelected:YES];
                                 [_secondVolumeKnob setSelected:YES];
                                 [_thirdVolumeKnob setSelected:YES];
                                 [_fourthVolumeKnob setSelected:NO];
                                 [_firstVolumeKnob setBackgroundImage:[UIImage imageNamed:@"one_darkgrey.png"] forState:UIControlStateNormal];
                                 [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_darkgrey.png"] forState:UIControlStateNormal];
                                 [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_darkgrey.png"] forState:UIControlStateNormal];
                                 [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_redoutline.png"] forState:UIControlStateNormal];
                             }
                             
                             [sqlManager updateSingleRecordingDataWithRecordingId:[recordID intValue] trackSequence:1 track:_recTrackTwo maxTrackDuration:durationStringUnFormatted trackDuration:t1Duration];
                             _recTrackOne = _recTrackTwo;
                             
                             [sqlManager updateSingleRecordingDataWithRecordingId:[recordID intValue] trackSequence:2 track:_recTrackThree maxTrackDuration:durationStringUnFormatted trackDuration:t2Duration];
                             _recTrackTwo = _recTrackThree;
                             
                             [sqlManager updateSingleRecordingDataWithRecordingId:[recordID intValue] trackSequence:3 track:_recTrackFour maxTrackDuration:durationStringUnFormatted trackDuration:t3Duration];
                             _recTrackThree = _recTrackFour;
                             
                             [sqlManager updateSingleRecordingDataWithRecordingId:[recordID intValue] trackSequence:4 track:@"-1" maxTrackDuration:durationStringUnFormatted trackDuration:t4Duration];
                             _recTrackFour = @"-1";
                         }
         ];
    }
    
    if(tag == 22)
    {
        control.hidden = YES;
        control.center = thirdKnobCentre;
        thirdKnob.center = forthKnobCentre;
        forthKnob.center = forthKnobCentre;
        
        [UIView animateWithDuration:0.5
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             // set the new frame
                             control.hidden = NO;
                             control.center = secondKnobCentre;
                             thirdKnob.center = thirdKnobCentre;
                             forthKnob.hidden = YES;
                             [_deleteImageT2 setHidden:YES];
                             [_deleteBGView setHidden:YES];
                             [self.view sendSubviewToBack:_secondVolumeKnob];
                         }
                         completion:^(BOOL finished){
                             forthKnob.hidden = NO;
                             forthKnob.center = forthKnobCentre;
                             
                             if ([_recTrackThree isEqualToString:@"-1"]) {
                                 recFlag2 = 0;
                                 [_rotatryT2 setHidden:YES];
                                 
                                 t2Duration = @"-1";
                                 durationStringUnFormatted = t1Duration;
                                 [self updateUIDataWithDuration:durationStringUnFormatted];
                                 
                                 [_secondVolumeKnob setSelected:NO];
                                 [_thirdVolumeKnob setSelected:NO];
                                 [_fourthVolumeKnob setSelected:NO];
                                 
                                 [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_redoutline.png"] forState:UIControlStateNormal];
                                 [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_greyoutline.png"] forState:UIControlStateNormal];
                                 [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
                                 
                             }
                             else if ([_recTrackFour isEqualToString:@"-1"])
                             {
                                 
                                 recFlag2 = 1;
                                 recFlag3 = 0;
                                 recFlag4 = 0;
                                 
                                 [_rotatryT2 setHidden:NO];
                                 [_rotatryT3 setHidden:YES];
                                 [_rotatryT4 setHidden:YES];
                                 
                                 t2Duration  = t3Duration;
                                 t3Duration = @"-1";
                                 t4Duration = @"-1";
                                 
                                 if ([t2Duration intValue] > [t1Duration intValue]) {
                                     durationStringUnFormatted = t2Duration;
                                 }
                                 else
                                     durationStringUnFormatted = t1Duration;
                                 
                                 [self updateUIDataWithDuration:durationStringUnFormatted];
                                 
                                 [_secondVolumeKnob setSelected:YES];
                                 [_thirdVolumeKnob setSelected:NO];
                                 [_fourthVolumeKnob setSelected:NO];
                                 
                                 [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_darkgrey.png"] forState:UIControlStateNormal];
                                 [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_redoutline.png"] forState:UIControlStateNormal];
                                 [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
                             }
                             else
                             {
                                 
                                 recFlag2 = 1;
                                 recFlag3 = 1;
                                 recFlag4 = 0;
                                 
                                 [_rotatryT2 setHidden:YES];
                                 [_rotatryT3 setHidden:YES];
                                 [_rotatryT4 setHidden:NO];
                                 
                                 t2Duration = t3Duration;
                                 t3Duration = t4Duration;
                                 t3Duration = @"-1";
                                 
                                 if ([t3Duration intValue] > [t2Duration intValue]) {
                                     if ([t3Duration intValue] > [t1Duration intValue])
                                     {
                                         durationStringUnFormatted = t3Duration;
                                     }
                                     else
                                         durationStringUnFormatted = t1Duration;
                                 }
                                 else if ([t2Duration intValue] > [t1Duration intValue])
                                 {
                                     durationStringUnFormatted = t2Duration;
                                 }
                                 else
                                     durationStringUnFormatted = t1Duration;
                                 
                                 [self updateUIDataWithDuration:durationStringUnFormatted];
                                 
                                 [_secondVolumeKnob setSelected:YES];
                                 [_thirdVolumeKnob setSelected:YES];
                                 [_fourthVolumeKnob setSelected:NO];
                                 
                                 [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_darkgrey.png"] forState:UIControlStateNormal];
                                 [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_darkgrey.png"] forState:UIControlStateNormal];
                                 [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_redoutline.png"] forState:UIControlStateNormal];
                             }
                             
                             [sqlManager updateSingleRecordingDataWithRecordingId:[recordID intValue] trackSequence:2 track:_recTrackThree maxTrackDuration:durationStringUnFormatted trackDuration:t2Duration];
                             _recTrackTwo = _recTrackThree;
                             
                             [sqlManager updateSingleRecordingDataWithRecordingId:[recordID intValue] trackSequence:3 track:_recTrackFour maxTrackDuration:durationStringUnFormatted trackDuration:t3Duration];
                             _recTrackThree = _recTrackFour;
                             
                             [sqlManager updateSingleRecordingDataWithRecordingId:[recordID intValue] trackSequence:4 track:@"-1" maxTrackDuration:durationStringUnFormatted trackDuration:t4Duration];
                             _recTrackFour = @"-1";
                         }
         ];
    }
    
    if(tag == 33)
    {
        control.hidden = YES;
        control.center = forthKnobCentre;
        forthKnob.center = forthKnobCentre;
        
        [UIView animateWithDuration:0.5
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             // set the new frame
                             control.hidden = NO;
                             control.center = thirdKnobCentre;
                             forthKnob.hidden = YES;
                             [_deleteImageT3 setHidden:YES];
                             [_deleteBGView setHidden:YES];
                             [self.view sendSubviewToBack:_thirdVolumeKnob];
                         }
                         completion:^(BOOL finished){
                             forthKnob.hidden = NO;
                             forthKnob.center = forthKnobCentre;
                             
                             if ([_recTrackFour isEqualToString:@"-1"]) {
                                 recFlag3 = 0;
                                 
                                 [_rotatryT3 setHidden:YES];
                                 
                                 t3Duration = @"-1";
                                 if ([t2Duration intValue] > [t1Duration intValue]) {
                                     durationStringUnFormatted = t2Duration;
                                 }
                                 else
                                     durationStringUnFormatted = t1Duration;
                                 
                                 [self updateUIDataWithDuration:durationStringUnFormatted];
                                 
                                 
                                 [_thirdVolumeKnob setSelected:NO];
                                 [_fourthVolumeKnob setSelected:NO];
                                 
                                 [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_redoutline.png"] forState:UIControlStateNormal];
                                 [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
                                 
                             }
                             else
                             {
                                 recFlag3 = 1;
                                 recFlag4 = 0;
                                 
                                 [_rotatryT3 setHidden:NO];
                                 [_rotatryT4 setHidden:YES];
                                 
                                 t3Duration = t4Duration;
                                 t4Duration = @"-1";
                                 
                                 if ([t3Duration intValue] > [t2Duration intValue]) {
                                     if ([t3Duration intValue] > [t1Duration intValue])
                                     {
                                         durationStringUnFormatted = t3Duration;
                                     }
                                     else
                                         durationStringUnFormatted = t1Duration;
                                 }
                                 else if ([t2Duration intValue] > [t1Duration intValue])
                                 {
                                     durationStringUnFormatted = t2Duration;
                                 }
                                 else
                                     durationStringUnFormatted = t1Duration;
                                 
                                 [self updateUIDataWithDuration:durationStringUnFormatted];
                                 
                                 [_thirdVolumeKnob setSelected:YES];
                                 [_fourthVolumeKnob setSelected:NO];
                                 
                                 [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_darkgrey.png"] forState:UIControlStateNormal];
                                 [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_redoutline.png"] forState:UIControlStateNormal];
                                 
                             }
                             
                             [sqlManager updateSingleRecordingDataWithRecordingId:[recordID intValue] trackSequence:3 track:_recTrackFour maxTrackDuration:durationStringUnFormatted trackDuration:t3Duration];
                             _recTrackThree = _recTrackFour;
                             
                             [sqlManager updateSingleRecordingDataWithRecordingId:[recordID intValue] trackSequence:4 track:@"-1" maxTrackDuration:durationStringUnFormatted trackDuration:t4Duration];
                             _recTrackFour = @"-1";
                             
                         }
         ];
    }
    if(tag == 44)
    {
        control.hidden = YES;
        [UIView animateWithDuration:0.5
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             // set the new frame
                             control.hidden = NO;
                             control.center = forthKnobCentre;
                             [_deleteImageT4 setHidden:YES];
                             [_deleteBGView setHidden:YES];
                             [self.view sendSubviewToBack:_fourthVolumeKnob];
                         }
                         completion:^(BOOL finished){
                             recFlag4 = 0;
                             [_rotatryT4 setHidden:YES];
                             t4Duration = @"-1";
                             if ([t3Duration intValue] > [t2Duration intValue]) {
                                 if ([t3Duration intValue] > [t1Duration intValue])
                                 {
                                     durationStringUnFormatted = t3Duration;
                                 }
                                 else
                                     durationStringUnFormatted = t1Duration;
                             }
                             else if ([t2Duration intValue] > [t1Duration intValue])
                             {
                                 durationStringUnFormatted = t2Duration;
                             }
                             else
                                 durationStringUnFormatted = t1Duration;
                             
                             [self updateUIDataWithDuration:durationStringUnFormatted];
                             
                             [sqlManager updateSingleRecordingDataWithRecordingId:[recordID intValue]  trackSequence:4 track:@"-1" maxTrackDuration:durationStringUnFormatted trackDuration:t4Duration];
                             _recTrackFour = @"-1";
                             
                             [_fourthVolumeKnob setSelected:NO];
                             [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_redoutline.png"] forState:UIControlStateNormal];
                             
                         }
         ];
    }
}

- (void)itemWasTouchedUp:(id)sender
{
    UIButton *button = sender;
    
    if (button.tag == 11 && ![_recTrackOne isEqualToString:@"-1"]) {
        if (recFlag1 == 0 )
        {
            [button setSelected:YES];
            
            recFlag1 = 1;
            if(playFlag == 1)
            {
                [self setInputParamForAudioArray:audioPlayerArray
                                  withActionType:kUserInput_Swipe
                                       withValue:tV1
                                        withName:@"track1"];
            }
        } else {
            [button setSelected:NO];
            recFlag1 = 0;
            [self setInputParamForAudioArray:audioPlayerArray
                              withActionType:kUserInput_Swipe
                                   withValue:0
                                    withName:@"track1"];
        }
    }
    if (button.tag == 22 && ![_recTrackTwo isEqualToString:@"-1"]) {
        if (recFlag2 == 0) {
            [button setSelected:YES];
            recFlag2 = 1;
            if(playFlag == 1)
            {
                [self setInputParamForAudioArray:audioPlayerArray
                                  withActionType:kUserInput_Swipe
                                       withValue:tV2
                                        withName:@"track2"];
            }
        } else {
            [button setSelected:NO];
            recFlag2 = 0;
            [self setInputParamForAudioArray:audioPlayerArray
                              withActionType:kUserInput_Swipe
                                   withValue:0
                                    withName:@"track2"];
        }
    }
    if (button.tag == 33 && ![_recTrackThree isEqualToString:@"-1"]) {
        if (recFlag3 == 0) {
            [button setSelected:YES];
            recFlag3 = 1;
            if(playFlag == 1)
            {
                [self setInputParamForAudioArray:audioPlayerArray
                                  withActionType:kUserInput_Swipe
                                       withValue:tV3
                                        withName:@"track3"];
            }
        } else {
            [button setSelected:NO];
            recFlag3 = 0;
            [self setInputParamForAudioArray:audioPlayerArray
                              withActionType:kUserInput_Swipe
                                   withValue:0
                                    withName:@"track3"];
        }
    }
    if (button.tag == 44 && ![_recTrackFour isEqualToString:@"-1"]) {
        if (recFlag4 == 0) {
            [button setSelected:YES];
            recFlag4 = 1;
            if(playFlag == 1)
            {
                [self setInputParamForAudioArray:audioPlayerArray
                                  withActionType:kUserInput_Swipe
                                       withValue:tV4
                                        withName:@"track4"];
            }
        } else {
            [button setSelected:NO];
            recFlag4 = 0;
            [self setInputParamForAudioArray:audioPlayerArray
                              withActionType:kUserInput_Swipe
                                   withValue:0
                                    withName:@"track4"];
        }
    }
}

-(IBAction)itemTouchUpInside:(id)sender {
    if (didHold) {
        didHold = NO;
        if (playFlag != 1)
            [self itemWasTouchedUpAndDidHold:sender];
    } else {
        didHold = NO;
        [self itemWasTouchedUp:sender];
    }
}

-(IBAction)closeButtonClicked:(UIButton*)sender {
    [self.delegate expandedCellWillCollapse];
}

-(IBAction)playButtonClicked:(UIButton*)sender
{
    if(stopFlag == 1){
        [audioRecorder stopAudioRecording];
        [self micShow];
    }
    
    if (playFlag == 0) {
        _playRecBtn.userInteractionEnabled = NO;
        [_playRecBtn setBackgroundImage:[UIImage imageNamed:@"stopicon.png"] forState:UIControlStateNormal];
        //[_recordingBtn setEnabled:NO];
        
        playFlag = 1;
        
        _recSlider.maximumValue = [durationStringUnFormatted floatValue];
        
        [self playSelectedRecording];
        
    }
    else if (playFlag == 1){
        [self resetPlayButtonWithCell];
    }
}

- (IBAction)recordingButtonClicked:(id)sender {

     //============== Change this =========================
    
//    if(![MainNavigationViewController checkNetworkStatus])
//        return;
//    
//    if(![MainNavigationViewController inAppPurchaseEnabled]) {
//        
//        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"In App Purchase" message:@"Do you want to buy 'Record On Top' feature ?" preferredStyle:UIAlertControllerStyleAlert];
//        
//        [alertController addAction:[UIAlertAction actionWithTitle:@"Buy" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//            [self fetchAvailableProducts];
//        }]];
//        
//        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//            return;
//        }]];
//        
//        [alertController addAction:[UIAlertAction actionWithTitle:@"Restore" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//            [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
//            [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
//        }]];
//        
//        [self presentViewController:alertController animated:YES completion:nil];
//        
//
//    } else {
    
        if (![_recTrackFour isEqualToString:@"-1"]) {
            
            self.alertController = [RAAlertController alertControllerWithTitle:@"Recording Full" message:@"Long press any recording to delete it and record a new one"
                                                                preferredStyle:RAAlertControllerStyleAlert];
            [_alertController addAction:[RAAlertAction actionWithTitle:@"Ok"
                                                                 style:RAAlertActionStyleCancel
                                                               handler:^(RAAlertAction *action) {
                                                                   //NSLog(@"...ok clicked");
                                                               }]];
            [_alertController presentInViewController:self animated:YES completion:^{
                //NSLog(@"Alert!");
            }];
            
            return;
        }
    
        [_recordingBGView setHidden:NO];
    
        micArray = [[NSArray alloc]initWithObjects:_mic1,_mic2,_mic3,_mic4,_mic5,_mic6,_mic7,_mic8,_mic9,_mic10, nil];
        
        if (stopFlag == 0) {
            [self resetPlayButtonWithCell];
            [_recordingBGView setHidden:NO];
            [_playRecBtn setUserInteractionEnabled:NO];
            [_recordingBtn setUserInteractionEnabled:NO];
            //[self.savedDetailDelegate tappedRecordButton];// delegate called
            [[NSNotificationCenter defaultCenter] postNotificationName:@"tappedRecordButton" object:nil];
            
            [_playRecBtn setSelected:YES];
            [_recordingBtn setSelected:YES];
            
            [_recSlider setThumbImage:[UIImage imageNamed:@"volumesqaure_pointer_red.png"] forState:UIControlStateNormal];
            [_recSlider setMaximumTrackImage:[UIImage imageNamed:@"volumeslider_sqaure_gred.png"] forState:UIControlStateNormal];
            [_recSlider setMinimumTrackImage:[UIImage imageNamed:@"volumeslider_sqaure_red.png"] forState:UIControlStateNormal];
            
            
            if ([_recTrackOne isEqualToString:@"-1"])
            {
                [_deleteImageT1 setImage:[UIImage imageNamed:@"one_red.png" ]];
                [_deleteImageT1 setHidden:NO ];
                [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_greyoutline.png"] forState:UIControlStateNormal];
                [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_greyoutline.png"] forState:UIControlStateNormal];
                [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
                
            }
            else if ([_recTrackTwo isEqualToString:@"-1"])
            {
                [_deleteImageT2 setImage:[UIImage imageNamed:@"two_red.png" ]];
                [_deleteImageT2 setHidden:NO ];
                [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_greyoutline.png"] forState:UIControlStateNormal];
                [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
                
            }
            else if ([_recTrackThree isEqualToString:@"-1"])
            {
                [_deleteImageT3 setImage:[UIImage imageNamed:@"three_red.png" ]];
                [_deleteImageT3 setHidden:NO ];
                [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
                
            }
            else if ([_recTrackFour isEqualToString:@"-1"])
            {
                [_deleteImageT4 setImage:[UIImage imageNamed:@"four_red.png" ]];
                [_deleteImageT4 setHidden:NO ];
                
            }
            
            stopFlag = 1;
            playFlag = 1;
            
            [self micHide];
            
            // have to give UISlider max value before SET value else it won't update its value and looks not updating.
            _recSlider.maximumValue = [durationStringUnFormatted floatValue];
            
            [self playSelectedRecording];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"tappedRecordButton" object:nil];
            
        }
        else if (stopFlag == 1) {
            [self micShow];
            [audioRecorder stopAudioRecording];
            [self resetPlayButtonWithCell];
            [self recordingFinished];
        }
    //}
}

- (IBAction)onVolumeBtnClicked:(id)sender {
    _volumeBtn.tintColor = UIColorFromRGB(FONT_BLUE_COLOR);//self.view.tintColor;
    _panBtn.tintColor = [UIColor blackColor];
    
    [_panBtn.titleLabel setFont:[UIFont fontWithName:FONT_LIGHT size:15]];
    [_volumeBtn.titleLabel setFont:[UIFont fontWithName:FONT_MEDIUM size:15]];
    mixerInputParam = kMixerParam_Vol;
    
    for (MHRotaryKnob *rotaryKnob in rotataryViewsArray)
        [self initializeRotatryViews:rotaryKnob];
}

- (IBAction)onPanBtnClicked:(id)sender {
    _panBtn.tintColor = UIColorFromRGB(FONT_BLUE_COLOR);
    _volumeBtn.tintColor = [UIColor blackColor];
    [_panBtn.titleLabel setFont:[UIFont fontWithName:FONT_MEDIUM size:15]];
    [_volumeBtn.titleLabel setFont:[UIFont fontWithName:FONT_LIGHT size:15]];
    mixerInputParam = kMixerParam_Pan;
    
    for (MHRotaryKnob *rotaryKnob in rotataryViewsArray)
        [self initializeRotatryViews:rotaryKnob];
}

- (IBAction)onTapClap1Btn:(id)sender {
    UIButton *btn = (UIButton*)sender;
    
    if (clapFlag1 == 0) {
        [btn setSelected:YES];
        clapFlag1 = 1;
        
        if(playFlag == 1)
        {
            [mixerController setInputVolume:0 value:instrV1/10.0f];
        }
    } else {
        [btn setSelected:NO];
        clapFlag1 = 0;
        [mixerController setInputVolume:0 value:0];
    }
}

- (IBAction)onTapClap2Btn:(id)sender {
    UIButton *btn = (UIButton*)sender;
    
    if (clapFlag2 == 0) {
        [btn setSelected:YES];
        clapFlag2 = 1;
        if(playFlag == 1)
        {
            [self setInputParamForAudioArray:audioPlayerArray
                              withActionType:kUserInput_Tap
                                   withValue:instrV2
                                    withName:@"clap2"];
        }
    } else {
        [btn setSelected:NO];
        clapFlag2 = 0;
        [self setInputParamForAudioArray:audioPlayerArray
                          withActionType:kUserInput_Tap
                               withValue:0
                                withName:@"clap2"];
    }
}

- (IBAction)onTapClap3Btn:(id)sender {
    UIButton *btn = (UIButton*)sender;
    
    if (clapFlag3 == 0) {
        [btn setSelected:YES];
        clapFlag3 = 1;
        if(playFlag == 1)
        {
            [self setInputParamForAudioArray:audioPlayerArray
                              withActionType:kUserInput_Tap
                                  withValue:instrV3
                                    withName:@"clap3"];
        }
    } else {
        [btn setSelected:NO];
        clapFlag3 = 0;
        [self setInputParamForAudioArray:audioPlayerArray
                          withActionType:kUserInput_Tap
                               withValue:0
                                withName:@"clap3"];
    }
}

- (IBAction)onTapClap4Btn:(id)sender {
    UIButton *btn = (UIButton*)sender;
    
    if (clapFlag4 == 0) {
        [btn setSelected:YES];
        if(playFlag == 1)
        {
            [self setInputParamForAudioArray:audioPlayerArray
                              withActionType:kUserInput_Tap
                                   withValue:instrV4
                                    withName:@"clap4"];
        }
        clapFlag4 = 1;
    } else {
        [btn setSelected:NO];
        clapFlag4 = 0;
        [self setInputParamForAudioArray:audioPlayerArray
                          withActionType:kUserInput_Tap
                               withValue:0
                                withName:@"clap4"];
    }
}

#pragma mark - Actionsheet delegate------

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        //[self deleteRecords];
        self.alertController = [RAAlertController alertControllerWithTitle:@"Delete Recording" message:@"Are you sure you want to delete Recording?"
                                                            preferredStyle:RAAlertControllerStyleAlert];
        [_alertController addAction:[RAAlertAction actionWithTitle:@"Delete"
                                                             style:RAAlertActionStyleDefault
                                                           handler:^(RAAlertAction *action) {
                                                               if(playFlag == 1) {
                                                                   [self resetPlayButtonWithCell];
                                                               }
                                                               [self deleteRecords];
                                                           }]];
        [_alertController addAction:[RAAlertAction actionWithTitle:@"Cancel"
                                                             style:RAAlertActionStyleCancel
                                                           handler:^(RAAlertAction *action) {
                                                           }]];
        [_alertController presentInViewController:self animated:YES completion:^{
            //NSLog(@"Alert!");
        }];
        
    }
    
    else if(buttonIndex == 0)
    {
        __block MBProgressHUD *hud;
        dispatch_async(dispatch_get_main_queue(), ^{
            hud =[MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.label.text = NSLocalizedString(@"Exporting...", @"");
            
            
            
        });
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if(playFlag == 1) {
                [self resetPlayButtonWithCell];
            }
            
            float tempo = [_startBPM floatValue]/[originalBPM floatValue];
            recordingMergeArray = [[NSMutableArray alloc] init];
            
            if(clapFlag1 == 1)
            {
                NSString *beatOneFile;
                if(tempo == 1.0f) {
                    beatOneFile = [MainNavigationViewController getAbsBundlePath:[clap1Path lastPathComponent]];
                } else {
                    beatOneFile = [MainNavigationViewController getAbsDocumentsPath:[clap1Path lastPathComponent]];
                }
                
                // p1 = [p1 stringByDeletingPathExtension];
                // p1 = [p1 stringByAppendingPathExtension:@"wav"];
                // [recordingMergeArray addObject:[NSString stringWithFormat:@"%@:%@", @"loopTrack",
                //                                 p1]];
                
                NSString *str = [MainNavigationViewController getAbsDocumentsPath:[clap1Path lastPathComponent]];
                
                [recordingMergeArray addObject:[NSString stringWithFormat:@"%@:%@", @"loopTrack", beatOneFile]];
            }
            
            if(clapFlag2 == 1)
            {
                NSString *beatTwoFile;
                if([[clap2Path lastPathComponent] isEqualToString:@"Sync 2.m4a"]) {       //snn
                    beatTwoFile = [MainNavigationViewController getAbsDocumentsPath:@"Click.m4a"];
                }
                else {
                    if(tempo == 1.0f) {
                        beatTwoFile = [MainNavigationViewController getAbsBundlePath:[clap2Path lastPathComponent]];
                    } else {
                        beatTwoFile = [MainNavigationViewController getAbsDocumentsPath:[clap2Path lastPathComponent]];
                    }
                }
                
                // p2 = [p2 stringByDeletingPathExtension];
                // p2 = [p2 stringByAppendingPathExtension:@"wav"];
                // [recordingMergeArray addObject:[NSString stringWithFormat:@"%@:%@", @"loopTrack",
                //                                 p2]];
                
                [recordingMergeArray addObject:[NSString stringWithFormat:@"%@:%@", @"loopTrack", beatTwoFile]];
            }
            
            if(clapFlag3 == 1)
            {
                [recordingMergeArray addObject:[NSString stringWithFormat:@"%@:%@", @"Metronome", clap3Path]];
            }
            
            if(clapFlag4 == 1)
            {
                [recordingMergeArray addObject:[NSString stringWithFormat:@"%@:%@", @"loopTrack", clap4Path]];
            }
            
            if(recFlag1 == 1)
            {
                NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[_recTrackOne lastPathComponent]];
                [recordingMergeArray addObject:[NSString stringWithFormat:@"%@:%@", @"recording", filePath]];
            }
            
            if(recFlag2 == 1)
            {
                NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[_recTrackTwo lastPathComponent]];
                [recordingMergeArray addObject:[NSString stringWithFormat:@"%@:%@", @"recording", filePath]];
            }
            
            if(recFlag3 == 1)
            {
                NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[_recTrackThree lastPathComponent]];
                [recordingMergeArray addObject:[NSString stringWithFormat:@"%@:%@", @"recording", filePath]];
            }
            
            if(recFlag4 == 1)
            {
                NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[_recTrackFour lastPathComponent]];
                [recordingMergeArray addObject:[NSString stringWithFormat:@"%@:%@", @"recording", filePath]];
            }
            
            // If mixed file not created
            if([recordingMergeArray count] == 0) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Share Failed !!"
                                                                message:@"All channels are muted !"
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
                return;
            }
            
            NSString *mergeOutputPath = [self mixAudioFiles:recordingMergeArray
                                          withTotalDuration:[durationStringUnFormatted intValue]
                                        withRecordingString:currentRythmName
                                                   andTempo:tempo];
            [hud hideAnimated:YES];
            self.shareCheckString = @"opened";
            
            TTOpenInAppActivity *openInAppActivity = [[TTOpenInAppActivity alloc] initWithView:self.view andRect:self.menuButton.frame];
            UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:mergeOutputPath]] applicationActivities:@[openInAppActivity]];
            
            if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
                // Store reference to superview (UIActionSheet) to allow dismissal
                openInAppActivity.superViewController = activityViewController;
                [self presentViewController:activityViewController animated:YES completion:NULL];
            } else {
                // Create pop up
                self.activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
                // Store reference to superview (UIPopoverController) to allow dismissal
                openInAppActivity.superViewController = self.activityPopoverController;
                // Show UIActivityViewController in popup
                [self.activityPopoverController presentPopoverFromRect:self.menuButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }

            
        });
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    //NSLog(@"btn = %ld", (long)actionSheet.cancelButtonIndex);
    //NSLog(@"btn = %ld", (long)buttonIndex);
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textField.placeholder = textField.text;
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self textFieldShouldEndEditing:textField];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (![textField.text isEqualToString:@""]) {
        currentRythmName = _songNameTxtFld.text;
        [sqlManager updateRecordingNameOfRecordID:recordID updatedName:_songNameTxtFld.text];
    }
    else
        textField.text = currentRythmName;
    
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - touch implementation

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(stopFlag == 1){
        return;
    }
    [_songNameTxtFld resignFirstResponder];
    didHold = NO;
    UITouch *t = [[event allTouches] anyObject];
    
    CGPoint p = [t locationInView:self.view];
    if ( CGRectContainsPoint(self.deleteBGView.frame, p))
    {
        //NSLog(@"deleteBGview touched");
        
        [_deleteBGView setHidden:YES];
        
        if (!_deleteImageT1.hidden) {
            [_deleteImageT1 setHidden:YES];
            [self.view sendSubviewToBack:_firstVolumeKnob];
        }
        else if (!_deleteImageT2.hidden) {
            [_deleteImageT2 setHidden:YES];
            [self.view sendSubviewToBack:_secondVolumeKnob];
        }
        else if (!_deleteImageT3.hidden) {
            [_deleteImageT3 setHidden:YES];
            [self.view sendSubviewToBack:_thirdVolumeKnob];
        }
        else if (!_deleteImageT4.hidden) {
            [_deleteImageT4 setHidden:YES];
            [self.view sendSubviewToBack:_fourthVolumeKnob];
        }
        
        //       [_deleteBGView setHidden:YES];
        //        menuActionSheet=nil;
        //[menuActionSheet dismissWithClickedButtonIndex:0 animated:YES];
    }
    
}

#pragma mark - methods

// For detecting taps outside of the alert view
-(void)tapOut:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint p = [gestureRecognizer locationInView:self.view];
    if (p.y < 0) { // They tapped outside
        [menuActionSheet dismissWithClickedButtonIndex:0 animated:YES];
    }
}

-(void) showFromTabBar:(UIView *)view {
    [menuActionSheet showInView:view];
    
    // Capture taps outside the bounds of this alert view
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOut:)];
    tap.cancelsTouchesInView = NO; // So that legit taps on the table bubble up to the tableview
    [menuActionSheet.superview addGestureRecognizer:tap];
}



- (void)initializeGestures
{
    //    tapGestureForAlertview = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    //    [_rotatryClap1 addGestureRecognizer:tapGestureForAlertview];
    
    UITapGestureRecognizer *clap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [_rotatryClap1 addGestureRecognizer:clap1];
    
    UITapGestureRecognizer *clap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [_rotatryClap2 addGestureRecognizer:clap2];
    
    UITapGestureRecognizer *clap3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [_rotatryClap3 addGestureRecognizer:clap3];
    
    UITapGestureRecognizer *clap4 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [_rotataryClap4 addGestureRecognizer:clap4];
    
    UITapGestureRecognizer *T1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [_rotatryT1 addGestureRecognizer:T1];
    
    UITapGestureRecognizer *T2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [_rotatryT2 addGestureRecognizer:T2];
    
    UITapGestureRecognizer *T3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [_rotatryT3 addGestureRecognizer:T3];
    
    UITapGestureRecognizer *T4 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [_rotatryT4 addGestureRecognizer:T4];
    
    upRecognizerInst1 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedScreen:)];
    [upRecognizerInst1 setDirection: UISwipeGestureRecognizerDirectionUp];
    
    downRecognizerInst1 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedScreen:)];
    [downRecognizerInst1 setDirection: UISwipeGestureRecognizerDirectionDown];
    
    upRecognizerInst2 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedScreen:)];
    [upRecognizerInst2 setDirection: UISwipeGestureRecognizerDirectionUp];
    
    downRecognizerInst2 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedScreen:)];
    [downRecognizerInst2 setDirection: UISwipeGestureRecognizerDirectionDown];
    
    upRecognizerInst3 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedScreen:)];
    [upRecognizerInst3 setDirection: UISwipeGestureRecognizerDirectionUp];
    
    downRecognizerInst3 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedScreen:)];
    [downRecognizerInst3 setDirection: UISwipeGestureRecognizerDirectionDown];
    
    upRecognizerInst4 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedScreen:)];
    [upRecognizerInst4 setDirection: UISwipeGestureRecognizerDirectionUp];
    
    downRecognizerInst4 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedScreen:)];
    [downRecognizerInst4 setDirection: UISwipeGestureRecognizerDirectionDown];
    
    upRecognizerRec1 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedScreen:)];
    [upRecognizerRec1 setDirection: UISwipeGestureRecognizerDirectionUp];
    
    downRecognizerRec1 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedScreen:)];
    [downRecognizerRec1 setDirection: UISwipeGestureRecognizerDirectionDown];
    
    upRecognizerRec2 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedScreen:)];
    [upRecognizerRec2 setDirection: UISwipeGestureRecognizerDirectionUp];
    
    downRecognizerRec2 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedScreen:)];
    [downRecognizerRec2 setDirection: UISwipeGestureRecognizerDirectionDown];
    
    upRecognizerRec3 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedScreen:)];
    [upRecognizerRec3 setDirection: UISwipeGestureRecognizerDirectionUp];
    
    downRecognizerRec3 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedScreen:)];
    [downRecognizerRec3 setDirection: UISwipeGestureRecognizerDirectionDown];
    
    upRecognizerRec4 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedScreen:)];
    [upRecognizerRec4 setDirection: UISwipeGestureRecognizerDirectionUp];
    
    downRecognizerRec4 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedScreen:)];
    [downRecognizerRec4 setDirection: UISwipeGestureRecognizerDirectionDown];
    
    //long press
    longPressForKnob1 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(LongPress:)];
    longPressForKnob1.minimumPressDuration = .5; //seconds
    longPressForKnob1.delegate = self;
    
    longPressForKnob2 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(LongPress:)];
    longPressForKnob2.minimumPressDuration = .5; //seconds
    longPressForKnob2.delegate = self;
    
    longPressForKnob3 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(LongPress:)];
    longPressForKnob3.minimumPressDuration = .5; //seconds
    longPressForKnob3.delegate = self;
    
    longPressForKnob4 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(LongPress:)];
    longPressForKnob4.minimumPressDuration = .5; //seconds
    longPressForKnob4.delegate = self;
    
    [_instrument1 addGestureRecognizer:upRecognizerInst1];
    [_instrument1 addGestureRecognizer:downRecognizerInst1];
    
    [_instrument2 addGestureRecognizer:upRecognizerInst2];
    [_instrument2 addGestureRecognizer:downRecognizerInst2];
    
    [_instrument3 addGestureRecognizer:upRecognizerInst3];
    [_instrument3 addGestureRecognizer:downRecognizerInst3];
    
    [_instrument4 addGestureRecognizer:upRecognizerInst4];
    [_instrument4 addGestureRecognizer:downRecognizerInst4];
    
    [_firstVolumeKnob addGestureRecognizer:upRecognizerRec1];
    [_firstVolumeKnob addGestureRecognizer:downRecognizerRec1];
    
    [_secondVolumeKnob addGestureRecognizer:upRecognizerRec2];
    [_secondVolumeKnob addGestureRecognizer:downRecognizerRec2];
    
    [_thirdVolumeKnob addGestureRecognizer:upRecognizerRec3];
    [_thirdVolumeKnob addGestureRecognizer:downRecognizerRec3];
    
    [_fourthVolumeKnob addGestureRecognizer:upRecognizerRec4];
    [_fourthVolumeKnob addGestureRecognizer:downRecognizerRec4];
    
    [_rotatryT1 addGestureRecognizer:longPressForKnob1];
    [_rotatryT2 addGestureRecognizer:longPressForKnob2];
    [_rotatryT3 addGestureRecognizer:longPressForKnob3];
    [_rotatryT4 addGestureRecognizer:longPressForKnob4];
    
    
}

//- (void)initializeRotatryViews :(NSArray *)rotatryViewArray{
//    for (MHRotaryKnob *rotaryKnob in rotatryViewArray) {
//        rotaryKnob.interactionStyle = MHRotaryKnobInteractionStyleSliderVertical;
//        rotaryKnob.scalingFactor = 1.5;
//        rotaryKnob.resetsToDefault = YES;
//        rotaryKnob.backgroundColor = [UIColor clearColor];
//        rotaryKnob.backgroundImage = [UIImage imageNamed:@""];
//        [rotaryKnob setKnobImage:[UIImage imageNamed:@"volume_circle1"] forState:UIControlStateNormal];
//        [rotaryKnob setKnobImage:[UIImage imageNamed:@"volume_circle1"] forState:UIControlStateHighlighted];
//        [rotaryKnob setKnobImage:[UIImage imageNamed:@"volume_circle1"] forState:UIControlStateDisabled];
//        rotaryKnob.knobImageCenter = CGPointMake(30.0, 30.0);
//        [rotaryKnob addTarget:self action:@selector(rotaryKnobDidChange:) forControlEvents:UIControlEventValueChanged];
//        int tag = (int)rotaryKnob.tag;
//        switch (tag) {
//            case 1:
//                if(mixerInputParam == kMixerParam_Vol)
//                    [rotaryKnob setValue:instrV1 animated:YES];
//                else
//                    [rotaryKnob setValue:instrP1 animated:YES];
//                break;
//            case 2:
//                if(mixerInputParam == kMixerParam_Vol)
//                    [rotaryKnob setValue:instrV2 animated:YES];
//                else
//                    [rotaryKnob setValue:instrP2 animated:YES];
//                break;
//            case 3:
//                if(mixerInputParam == kMixerParam_Vol)
//                    [rotaryKnob setValue:instrV3 animated:YES];
//                else
//                    [rotaryKnob setValue:instrP3 animated:YES];
//                break;
//            case 4:
//                if(mixerInputParam == kMixerParam_Vol)
//                    [rotaryKnob setValue:instrV4 animated:YES];
//                else
//                    [rotaryKnob setValue:instrP4 animated:YES];
//                break;
//            case 5:
//                if(mixerInputParam == kMixerParam_Vol)
//                    [rotaryKnob setValue:tV1 animated:YES];
//                else
//                    [rotaryKnob setValue:tP1 animated:YES];
//                break;
//            case 6:
//                if(mixerInputParam == kMixerParam_Vol)
//                    [rotaryKnob setValue:tV2 animated:YES];
//                else
//                    [rotaryKnob setValue:tP2 animated:YES];
//                break;
//            case 7:
//                if(mixerInputParam == kMixerParam_Vol)
//                    [rotaryKnob setValue:tV3 animated:YES];
//                else
//                    [rotaryKnob setValue:tP3 animated:YES];
//                break;
//            case 8:
//                if(mixerInputParam == kMixerParam_Vol)
//                    [rotaryKnob setValue:tV4 animated:YES];
//                else
//                    [rotaryKnob setValue:tP4 animated:YES];
//                break;
//                
//            default:
//                break;
//        }
//    }
//}

- (void)initializeRotatryViews:(MHRotaryKnob *)rotaryKnob {
    rotaryKnob.interactionStyle = MHRotaryKnobInteractionStyleSliderVertical;
    rotaryKnob.scalingFactor = 1.5;
    rotaryKnob.resetsToDefault = YES;
    rotaryKnob.backgroundColor = [UIColor clearColor];
    rotaryKnob.backgroundImage = [UIImage imageNamed:@""];
    
    rotaryKnob.knobImageCenter = CGPointMake(30.0, 30.0);
    [rotaryKnob addTarget:self action:@selector(rotaryKnobDidChange:) forControlEvents:UIControlEventValueChanged];
    [rotaryKnob addTarget:self action:@selector(rotaryKnobDidSwipe:) forControlEvents:UIControlEventTouchDragInside];
    
    int tag = (int)rotaryKnob.tag;
    switch (tag) {
        case 1:
            if(mixerInputParam == kMixerParam_Vol)
                [rotaryKnob setValue:instrV1 animated:YES];
            else
                [rotaryKnob setValue:instrP1 animated:YES];
            break;
        case 2:
            if(mixerInputParam == kMixerParam_Vol)
                [rotaryKnob setValue:instrV2 animated:YES];
            else
                [rotaryKnob setValue:instrP2 animated:YES];
            break;
        case 3:
            if(mixerInputParam == kMixerParam_Vol)
                [rotaryKnob setValue:instrV3 animated:YES];
            else
                [rotaryKnob setValue:instrP3 animated:YES];
            break;
        case 4:
            if(mixerInputParam == kMixerParam_Vol)
                [rotaryKnob setValue:instrV4 animated:YES];
            else
                [rotaryKnob setValue:instrP4 animated:YES];
            break;
        case 5:
            if(mixerInputParam == kMixerParam_Vol)
                [rotaryKnob setValue:tV1 animated:YES];
            else
                [rotaryKnob setValue:tP1 animated:YES];
            break;
        case 6:
            if(mixerInputParam == kMixerParam_Vol)
                [rotaryKnob setValue:tV2 animated:YES];
            else
                [rotaryKnob setValue:tP2 animated:YES];
            break;
        case 7:
            if(mixerInputParam == kMixerParam_Vol)
                [rotaryKnob setValue:tV3 animated:YES];
            else
                [rotaryKnob setValue:tP3 animated:YES];
            break;
        case 8:
            if(mixerInputParam == kMixerParam_Vol)
                [rotaryKnob setValue:tV4 animated:YES];
            else
                [rotaryKnob setValue:tP4 animated:YES];
            break;
            
        default:
            break;
    }
}

- (void)setRotaryKnobImage:(MHRotaryKnob *)rotaryKnob isSelected:(BOOL)selected {
    NSString *knobImage;
    (selected) ? knobImage = @"volume_circle_white" : knobImage = @"volume_circle_black";
    
    [rotaryKnob setKnobImage:[UIImage imageNamed:knobImage] forState:UIControlStateNormal];
    [rotaryKnob setKnobImage:[UIImage imageNamed:knobImage] forState:UIControlStateHighlighted];
    [rotaryKnob setKnobImage:[UIImage imageNamed:knobImage] forState:UIControlStateDisabled];
}

-(void)setDroneTitleColor:(UIColor *)color forState:(UIControlState)state {

    UIFont *font = [UIFont fontWithName:HELVETICA_REGULAR size:35];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:droneName
                                                                                         attributes:@{NSFontAttributeName: font}];
    if([droneName length] > 1) {
        
        [attributedString setAttributes:@{NSFontAttributeName:[UIFont fontWithName:HELVETICA_REGULAR size:22]
                                          , NSBaselineOffsetAttributeName:@15} range:NSMakeRange(1, 1)];
    }
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0,attributedString.length)];
    
    [_instrument4 setAttributedTitle:attributedString forState:UIControlStateNormal];
    [_instrument4 setAttributedTitle:attributedString forState:UIControlStateSelected];
}

//- (void)trimRequiredAudioFiles {
//    [self trimAudioFileWithInputFilePath:[MainNavigationViewController getAbsBundlePath:@"Click AccentedNew.wav"]
//                        toOutputFilePath:[MainNavigationViewController getAbsDocumentsPath:@"Click.m4a"]
//                                withFlag:NO];
//    
//    float tempo = [_startBPM floatValue]/[originalBPM floatValue];
//    [self timeStretchRhythmsAndSave:clap1Path withSecondInstr:clap2Path withTempo:tempo];
//    
//    // Trim code
//    NSString *inst1Path = [MainNavigationViewController getAbsDocumentsPath:[clap1Path lastPathComponent]];
//    inst1Path = [inst1Path stringByDeletingPathExtension];
//    inst1Path = [inst1Path stringByAppendingPathExtension:@"wav"];
//    
//    NSString *inst2Path = [MainNavigationViewController getAbsDocumentsPath:[clap2Path lastPathComponent]];
//    inst2Path = [inst2Path stringByDeletingPathExtension];
//    inst2Path = [inst2Path stringByAppendingPathExtension:@"wav"];
//    
//    [self trimAudioFileInputFilePath:inst1Path toOutputFilePath:[MainNavigationViewController getAbsDocumentsPath:[clap1Path lastPathComponent]]];
//    [self trimAudioFileInputFilePath:inst2Path toOutputFilePath:[MainNavigationViewController getAbsDocumentsPath:[clap2Path lastPathComponent]]];
//}

- (void)trimRequiredAudioFiles {
    
    [self trimAudioFileWithInputFilePath:[self getAbsoluteBundlePath:@"Click AccentedNew.wav"]
                        toOutputFilePath:[self getAbsoluteDocumentsPath:@"Click.m4a"]
                                withFlag:NO];
    
    float tempo = [_startBPM floatValue]/[originalBPM floatValue];
    [self timeStretchRhythmsAndSave:clap1Path withSecondInstr:clap2Path withTempo:tempo];
    
    // Trim code
    NSString *inst1Path = [self getAbsoluteDocumentsPath:[clap1Path lastPathComponent]];
    
    NSString *bundlePath = [self getAbsoluteBundlePath:[clap1Path lastPathComponent]];
    
    AVURLAsset *bundleAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:bundlePath]
                                                     options:nil];
    
    CMTime bundleAssetDuration = bundleAsset.duration;
    float bundleAssetDurationSeconds = CMTimeGetSeconds(bundleAssetDuration);
    
    
    inst1Path = [inst1Path stringByDeletingPathExtension];
    inst1Path = [inst1Path stringByAppendingPathExtension:@"wav"];
    
    AVURLAsset *assetAfterTimeStretching = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:inst1Path]
                                                     options:nil];
    
    CMTime assetAfterTimeStretchingDuration = assetAfterTimeStretching.duration;
    float assetAfterTimeStretchingDurationSeconds = CMTimeGetSeconds(assetAfterTimeStretchingDuration);
    
    float durationToBeRemoved = bundleAssetDurationSeconds/tempo - assetAfterTimeStretchingDurationSeconds;
    
    NSString *inst2Path = [self getAbsoluteDocumentsPath:[clap2Path lastPathComponent]];
    inst2Path = [inst2Path stringByDeletingPathExtension];
    inst2Path = [inst2Path stringByAppendingPathExtension:@"wav"];
    
    [self trimAudioFileInputFilePath:inst1Path toOutputFilePath:[self getAbsoluteDocumentsPath:[clap1Path lastPathComponent]] withStartTrimTime:durationToBeRemoved];
    [self trimAudioFileInputFilePath:inst2Path toOutputFilePath:[self getAbsoluteDocumentsPath:[clap2Path lastPathComponent]] withStartTrimTime:durationToBeRemoved];
}

- (void)timeStretchRhythmsAndSave:(NSString *)firstInstr
                  withSecondInstr:(NSString *)secondInstr
                        withTempo:(float)tempo {
    
    [timeStretcher timeStretchAndConvert:firstInstr
                          withOutputFile:[MainNavigationViewController getAbsDocumentsPath:[firstInstr lastPathComponent]]
                               withTempo:tempo];
    
    [timeStretcher timeStretchAndConvert:secondInstr
                          withOutputFile:[MainNavigationViewController getAbsDocumentsPath:[secondInstr lastPathComponent]]
                               withTempo:tempo];
}

- (IBAction)rotaryKnobDidSwipe :(MHRotaryKnob *)knob {
    [self removeRotaryKnobGestureRecognizer:knob];
}

- (void)addRotaryKnobGestureRecognizer:(MHRotaryKnob *)knob {
    if (knob.gestureRecognizers.count == 0) {
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                               action:@selector(handleSingleTap:)];
        [knob addGestureRecognizer:tapGestureRecognizer];
        if(knob.tag >=5){
            UILongPressGestureRecognizer *longPressForKnob = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(LongPress:)];
            longPressForKnob.minimumPressDuration = .5; //seconds
            longPressForKnob.delegate = self;
            [knob addGestureRecognizer:longPressForKnob];
        }
    }
}

- (void)removeRotaryKnobGestureRecognizer:(MHRotaryKnob *)knob {
    while (knob.gestureRecognizers.count) {
        [knob removeGestureRecognizer:[knob.gestureRecognizers objectAtIndex:0]];
    }
}

- (IBAction)rotaryKnobDidChange :(MHRotaryKnob *)knob
{
    [self addRotaryKnobGestureRecognizer:knob];
    
    int tag = (int)knob.tag;
    
    switch (tag) {
        case 1:
            (mixerInputParam == kMixerParam_Vol) ? instrV1 = knob.value : instrP1 = knob.value;
            
            if(clapFlag1 == 1) {
                if (instrV1 == 0)
                    [self setMixerInputParameter:0 value:1/MAX_VOL param:mixerInputParam];
                else
                    [self setMixerInputParameter:0 value:knob.value/MAX_VOL param:mixerInputParam];
            }
            break;
        case 2:
            (mixerInputParam == kMixerParam_Vol) ? instrV2 = knob.value : instrP2 = knob.value;
            
            if(clapFlag2 == 1) {
                if (instrV2 == 0)
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Swipe
                                           withValue:1/MAX_VOL
                                            withName:@"clap2"];
                else
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Swipe
                                           withValue:knob.value/MAX_VOL
                                            withName:@"clap2"];
            }
            break;
        case 3:
            (mixerInputParam == kMixerParam_Vol) ? instrV3 = knob.value : instrP3 = knob.value;
            
            if(clapFlag3 == 1) {
                if (instrV3 == 0) {
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Swipe
                                           withValue:1/MAX_VOL
                                            withName:@"clap3"];
                }
                else {
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Swipe
                                           withValue:knob.value/MAX_VOL
                                            withName:@"clap3"];
                }
            }
            break;
        case 4:
            (mixerInputParam == kMixerParam_Vol) ? instrV4 = knob.value : instrP4 = knob.value;
            
            if(clapFlag4 == 1) {
                if (instrV4 == 0)
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Swipe
                                           withValue:1/MAX_VOL
                                            withName:@"clap4"];
                else
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Swipe
                                           withValue:knob.value/MAX_VOL
                                            withName:@"clap4"];
            }
            break;
        case 5:
            (mixerInputParam == kMixerParam_Vol) ? tV1 = knob.value : tP1 = knob.value;
            
            if(recFlag1 == 1) {
                if (tV1 == 0)
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Swipe
                                           withValue:1/MAX_VOL
                                            withName:@"track1"];
                else
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Swipe
                                           withValue:knob.value/MAX_VOL
                                            withName:@"track1"];
            }
            break;
        case 6:
            (mixerInputParam == kMixerParam_Vol) ? tV2 = knob.value : tP2 = knob.value;
            
            if(recFlag2 == 1) {
                if (tV2 == 0)
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Swipe
                                           withValue:1/MAX_VOL
                                            withName:@"track2"];
                else
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Swipe
                                           withValue:knob.value/MAX_VOL
                                            withName:@"track2"];
            }
            break;
        case 7:
            (mixerInputParam == kMixerParam_Vol) ? tV3 = knob.value : tP3 = knob.value;
            
            if(recFlag3 == 1) {
                if (tV3 == 0)
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Swipe
                                           withValue:1/MAX_VOL
                                            withName:@"track3"];
                else
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Swipe
                                           withValue:knob.value/MAX_VOL
                                            withName:@"track3"];
            }
            break;
        case 8:
            (mixerInputParam == kMixerParam_Vol) ? tV4 = knob.value : tP4 = knob.value;
            
            if(recFlag4 == 1) {
                if (tV4 == 0)
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Swipe
                                           withValue:1/MAX_VOL
                                            withName:@"track4"];
                else
                    [self setInputParamForAudioArray:audioPlayerArray
                                      withActionType:kUserInput_Swipe
                                           withValue:knob.value/MAX_VOL
                                            withName:@"track4"];
            }
            break;
            
        default:
            break;
    }
}

// Set values for input parameters of mixer such as volume and pan.
- (void)setMixerInputParameter:(UInt32)inputNum
                         value:(AudioUnitParameterValue)inputValue
                         param:(int)inputParam {
    switch(inputParam) {
        case kMixerParam_Vol:
            [mixerController setInputVolume:inputNum value:inputValue];
            break;
            
        case kMixerParam_Pan:
            [mixerController setPanPosition:inputNum value:inputValue];
            break;
            
        default:
            break;
    }
}

- (void)setInputParamForAudioArray:(NSMutableArray *)array
                    withActionType:(int)action
                         withValue:(float)value
                          withName:(NSString *)name {
    [array enumerateObjectsUsingBlock:^(NSDictionary *object, NSUInteger idx,BOOL *stop){
        if ([[object valueForKey:@"recorded"] isEqualToString:name]) {
            //[mixerController setInputVolume:(UInt32)idx value:volume];
            if(action == kUserInput_Tap) {
                [self setMixerInputParameter:(UInt32)idx value:value param:kMixerParam_Vol];
            } else {
                [self setMixerInputParameter:(UInt32)idx value:value param:mixerInputParam];
            }
            *stop = YES;
        }
    }];
}

-(void)resetVolImages{
    [UIView animateWithDuration:0.2 animations:^() {
        
        _volImageInstru1.transform = CGAffineTransformIdentity;
        _volImageInstru2.transform = CGAffineTransformIdentity;
        _volImageInstru3.transform = CGAffineTransformIdentity;
        _volImageInstru4.transform = CGAffineTransformIdentity;
        _volImageT1.transform = CGAffineTransformIdentity;
        _volImageT2.transform = CGAffineTransformIdentity;
        _volImageT3.transform = CGAffineTransformIdentity;
        _volImageT4.transform = CGAffineTransformIdentity;
        
    }];
}

# pragma mark Mixing

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

- (NSString *)mixAudioFiles:(NSMutableArray*)audioFileURLArray
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
        switch (exportSession.status)
        {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"#### Failed\n");
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"### Success\n");
                break;
            case AVAssetExportSessionStatusWaiting:
                break;
            default:
                break;
        }
    }];
    
    return outputFile;
}

- (void)updateUIDataWithDuration :(NSString *)duration{
    _TotalTimeLbl.text = [self timeFormatted:[duration intValue]];
    _maxRecDurationLbl.text = [NSString stringWithFormat:@"-%@",[self timeFormatted:[duration intValue]]];
    _recSlider.maximumValue = [durationStringUnFormatted floatValue];
}


- (void)deleteRecords{
    [sqlManager updateDeleteRecordOfRecordID:recordID];
    [_myNavigationController goBackToSoundListing];
   // [self.delegate expandedCellWillCollapse];
}


- (void)setUIElements{
    _songNameTxtFld.text = currentRythmName;
    _songNameTxtFld.returnKeyType = UIReturnKeyDone;
    _songNameTxtFld.autocapitalizationType = UITextAutocapitalizationTypeWords;
    _songDetailLbl.attributedText = songDetail;
    _dateLbl.text = dateOfRecording;
    _TotalTimeLbl.text = songDuration;
    _minRecDurationLbl.text = @"00:00";
    
    [_recSlider setThumbImage:[UIImage imageNamed:@"volumesqaure_pointer_blue.png"] forState:UIControlStateNormal];
    [_recSlider setMaximumTrackImage:[UIImage imageNamed:@"volumeslider_sqaure_gred.png"] forState:UIControlStateNormal];
    [_recSlider setMinimumTrackImage:[UIImage imageNamed:@"volumeslider_sqaure_blue.png"] forState:UIControlStateNormal];
    
    _recSlider.minimumValue = 0.00;
    _recSlider.maximumValue = 0.00;
    _recSlider.continuous = YES;
    
    
    int img1 = 1, img2 = 1;
    // Set Image
    if (![rhythmRecord.rhythmInstOneImage isEqualToString:@"-1"]) {
        [_instrument1 setHidden:NO];
        [_rotatryClap1 setHidden:NO];
        [_instrument1 setImage:[UIImage imageNamed:rhythmRecord.rhythmInstOneImage] forState:UIControlStateNormal];
        [_instrument1 setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@_disabled",rhythmRecord.rhythmInstOneImage]] forState:UIControlStateSelected];
        img1 = 1;
        
    } else {
        
        [_instrument1 setHidden:YES];
        [_volImageInstru1 setHidden:YES];
        [_rotatryClap1 setHidden:YES];
        clapFlag1 = 0;
        img1 = 0;
    }
    
    if (![rhythmRecord.rhythmInstTwoImage isEqualToString:@"-1"]) {
        [_instrument2 setHidden:NO];
        [_rotatryClap2 setHidden:NO];
        [_instrument2 setImage:[UIImage imageNamed:rhythmRecord.rhythmInstTwoImage] forState:UIControlStateNormal];
        [_instrument2 setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@_disabled",rhythmRecord.rhythmInstTwoImage]] forState:UIControlStateSelected];
        img2 = 1;
        
    } else {
        
        [_instrument2 setHidden:YES];
        [_volImageInstru2 setHidden:YES];
        [_rotatryClap2 setHidden:YES];
        img2 = 0;
        clapFlag2 = 0;
    }
    
    CGRect visibleSize = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = visibleSize.size.width;
    int xDist = 0;  // for 320
    
    // If only 2 buttons are there
    if ((img1 == 0) && (img2 == 0)) {
        
        xDist = ((screenWidth - 120) / 3);
        _audioPlayerClap1 = nil;
        _audioPlayerClap2 = nil;
        _instrument3.frame = CGRectMake(xDist, _instrument3.frame.origin.y, 60, 60);
        _instrument4.frame = CGRectMake((xDist*2)+60, _instrument4.frame.origin.y, 60, 60);
        _volImageInstru3.center = _instrument3.center;
        _volImageInstru4.center = _instrument4.center;
        _rotatryClap3.center = _instrument3.center;
        _rotataryClap4.center = _instrument4.center;
        
    } else if (img1 == 0) {
        
        xDist = ((screenWidth - 180) / 4);
        _audioPlayerClap1 = nil;
        _instrument2.frame = CGRectMake(xDist, _instrument2.frame.origin.y, 60, 60);
        _instrument3.frame = CGRectMake((xDist*2)+60, _instrument3.frame.origin.y, 60, 60);
        _instrument4.frame = CGRectMake((xDist*3)+120, _instrument4.frame.origin.y, 60, 60);
        _volImageInstru2.center = _instrument2.center;
        _volImageInstru3.center = _instrument3.center;
        _volImageInstru4.center = _instrument4.center;
        _rotatryClap2.center = _instrument2.center;
        _rotatryClap3.center = _instrument3.center;
        _rotataryClap4.center = _instrument4.center;
        
    } else if (img2 == 0) {
        
        xDist = ((screenWidth - 180) / 4);
        _audioPlayerClap2 = nil;
        _instrument1.frame = CGRectMake(xDist, _instrument1.frame.origin.y, 60, 60);
        _instrument3.frame = CGRectMake((xDist*2)+60, _instrument3.frame.origin.y, 60, 60);
        _instrument4.frame = CGRectMake((xDist*3)+120, _instrument4.frame.origin.y, 60, 60);
        _volImageInstru1.center = _instrument1.center;
        _volImageInstru3.center = _instrument3.center;
        _volImageInstru4.center = _instrument4.center;
        
        _rotatryClap1.center = _instrument1.center;
        _rotatryClap3.center = _instrument3.center;
        _rotataryClap4.center = _instrument4.center;
        
    } else {
        
        xDist = ((screenWidth - 240) / 5);
        _instrument1.frame = CGRectMake(xDist, _instrument1.frame.origin.y, 60, 60);
        _instrument2.frame = CGRectMake((xDist*2)+60, _instrument2.frame.origin.y, 60, 60);
        _instrument3.frame = CGRectMake((xDist*3)+120, _instrument3.frame.origin.y, 60, 60);
        _instrument4.frame = CGRectMake((xDist*4)+182, _instrument4.frame.origin.y, 60, 60);
        _volImageInstru1.center = _instrument1.center;
        _volImageInstru2.center = _instrument2.center;
        _volImageInstru3.center = _instrument3.center;
        _volImageInstru4.center = _instrument4.center;
        
        _rotatryClap1.center = _instrument1.center;
        _rotatryClap2.center = _instrument2.center;
        _rotatryClap3.center = _instrument3.center;
        _rotataryClap4.center = _instrument4.center;
    }
    
    if ([_recTrackOne isEqualToString:@"-1"])
    {
        [_firstVolumeKnob setBackgroundImage:[UIImage imageNamed:@"one_redoutline.png"] forState:UIControlStateNormal];
        [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_greyoutline.png"] forState:UIControlStateNormal];
        [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_greyoutline.png"] forState:UIControlStateNormal];
        [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
        [_rotatryT1 setHidden:YES];
        [_rotatryT2 setHidden:YES];
        [_rotatryT3 setHidden:YES];
        [_rotatryT4 setHidden:YES];
    }
    else if ([_recTrackTwo isEqualToString:@"-1"])
    {
        [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_redoutline.png"] forState:UIControlStateNormal];
        [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_greyoutline.png"] forState:UIControlStateNormal];
        [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
        
        [_rotatryT2 setHidden:YES];
        [_rotatryT3 setHidden:YES];
        [_rotatryT4 setHidden:YES];
    }
    else if ([_recTrackThree isEqualToString:@"-1"])
    {
        [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_redoutline.png"] forState:UIControlStateNormal];
        [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
        [_rotatryT3 setHidden:YES];
        [_rotatryT4 setHidden:YES];
    }
    else if ([_recTrackFour isEqualToString:@"-1"])
    {
        [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_redoutline.png"] forState:UIControlStateNormal];
        [_rotatryT4 setHidden:YES];
    }
    
    if (![_recTrackOne isEqualToString:@"-1"])
    {
        [_firstVolumeKnob setBackgroundImage:[UIImage imageNamed:@"one_blue.png"] forState:UIControlStateSelected];
        [_firstVolumeKnob setBackgroundImage:[UIImage imageNamed:@"one_darkgrey.png"] forState:UIControlStateNormal];
        [_rotatryT1 setHidden:NO];
    }
    if (![_recTrackTwo isEqualToString:@"-1"])
    {
        [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_blue.png"] forState:UIControlStateSelected];
        [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_darkgrey.png"] forState:UIControlStateNormal];
        [_rotatryT2 setHidden:NO];
        
    }
    if (![_recTrackThree isEqualToString:@"-1"])
    {
        [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_blue.png"] forState:UIControlStateSelected];
        [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_darkgrey.png"] forState:UIControlStateNormal];
        [_rotatryT3 setHidden:NO];
    }
    if (![_recTrackFour isEqualToString:@"-1"])
    {
        [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_blue.png"] forState:UIControlStateSelected];
        [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_darkgrey.png"] forState:UIControlStateNormal];
        [_rotatryT4 setHidden:NO];
    }
    
    if([_recTrackOne isEqualToString:@"-1"])
        _maxRecDurationLbl.text = @"00:00";
    else
        _maxRecDurationLbl.text = [NSString stringWithFormat:@"-%@", songDuration];
    
    if (![droneName isEqualToString:@"-1"])
    {
        UIFont *font = [UIFont fontWithName:HELVETICA_REGULAR size:35];
        
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:droneName
                                                                                             attributes:@{NSFontAttributeName: font}];
        if([droneName length] > 1) {
        
            [attributedString setAttributes:@{NSFontAttributeName:[UIFont fontWithName:HELVETICA_REGULAR size:22]
                                              , NSBaselineOffsetAttributeName:@15} range:NSMakeRange(1, 1)];
        }
        
        [_instrument4 setAttributedTitle:attributedString forState:UIControlStateNormal];
        [_instrument4 setAttributedTitle:attributedString forState:UIControlStateSelected];
    }
    
    _instrument1.selected = clapFlag1;
    [self setRotaryKnobImage:_rotatryClap1 isSelected:_instrument1.isSelected];
    
    _instrument2.selected = clapFlag2;
    [self setRotaryKnobImage:_rotatryClap2 isSelected:_instrument2.isSelected];
    
    _instrument3.selected = clapFlag3;
    [self setRotaryKnobImage:_rotatryClap3 isSelected:_instrument3.isSelected];
    
    _instrument4.selected = clapFlag4;
    [self setRotaryKnobImage:_rotataryClap4 isSelected:_instrument4.isSelected];
    
    _firstVolumeKnob.selected = recFlag1;
    [self setRotaryKnobImage:_rotatryT1 isSelected:_firstVolumeKnob.isSelected];
    
    _secondVolumeKnob.selected = recFlag2;
    [self setRotaryKnobImage:_rotatryT2 isSelected:_secondVolumeKnob.isSelected];
    
    _thirdVolumeKnob.selected = recFlag3;
    [self setRotaryKnobImage:_rotatryT3 isSelected:_thirdVolumeKnob.isSelected];
    
    _fourthVolumeKnob.selected = recFlag4;
    [self setRotaryKnobImage:_rotatryT4 isSelected:_fourthVolumeKnob.isSelected];
}

- (void)spinVolumeKnobToVolumeLevel :(int)level knob :(UIImageView *)rotateImage{
    int roundupLevel = level;
    if (roundupLevel > 8) {
        roundupLevel = 8;
    }
    
    [rotateImage setTransform:CGAffineTransformRotate(rotateImage.transform, (360/ 11)*roundupLevel)];
}

-(void)setDataForUIElements:(int)_index RecordingData :(RecordingListData *)data{
    RecordingListData *cellData = [[RecordingListData alloc] init];
    rhythmRecord = [[RhythmClass alloc] init];
    //currentIndex = _index;
    cellData = data;
    
    if (cellData.rhythmRecord == nil || [self.shareCheckString isEqualToString:@"opened"]) {
        NSMutableArray *dataArray = [[NSMutableArray alloc] init];
        if([self.shareCheckString isEqualToString:@"opened"]) {
            songList = [sqlManager getAllRecordingData];
            if(currentIndex == [songList count]) currentIndex = 0;
            cellData = [songList objectAtIndex:currentIndex];
        }
        dataArray = [sqlManager fetchRhythmRecordsByID:[NSNumber numberWithInt:[cellData.rhythmID intValue]]];
        cellData.rhythmRecord = [dataArray objectAtIndex:0];
    }
    rhythmRecord = cellData.rhythmRecord;//[dataArray objectAtIndex:0];
    
    // set instrument ON/OFF
    clapFlag1 = [cellData.instOne intValue];
    clapFlag2 = [cellData.instTwo intValue];
    clapFlag3 = [cellData.instThree intValue];
    clapFlag4 = [cellData.instFour intValue];
    
    lag1 = [cellData.lag1 intValue];
    lag2 = [cellData.lag2 intValue];
    
    // Set Music
    beatOneMusicFile = cellData.beat1;
    beatTwoMusicFile = cellData.beat2;
    _recTrackOne = cellData.trackOne;
    _recTrackTwo = cellData.trackTwo;
    _recTrackThree = cellData.trackThree;
    _recTrackFour = cellData.trackFour;
    _startBPM = cellData.BPM;
    originalBPM = rhythmRecord.rhythmBPM;
    _droneType =  [sqlManager getDroneLocationFromName:cellData.droneType];
    droneName = cellData.droneType;
    durationStringUnFormatted = cellData.durationString;
    
    t1Duration = cellData.t1DurationString;
    t2Duration = cellData.t2DurationString;
    t3Duration = cellData.t3DurationString;
    t4Duration = cellData.t4DurationString;
    
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
    
    recordID = cellData.recordID;
    currentRythmName = cellData.recordingName;
    songDuration = [NSString stringWithFormat:@"%@",[self timeFormatted:[durationStringUnFormatted intValue]]];
    dateOfRecording = cellData.dateString;
    
    NSAttributedString *drone = [[NSAttributedString alloc] initWithString:cellData.droneType];
    
    NSString *audioInfo = [NSString stringWithFormat:@"%@ %@ bpm ", rhythmRecord.rhythmName, [cellData.BPM stringValue]];
    
    songDetail = [[NSMutableAttributedString alloc] initWithString:audioInfo];
    
    if([cellData.droneType length] > 1) {
        UIFont *font = [UIFont fontWithName:FONT_LIGHT size:10];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:cellData.droneType
                                                                                             attributes:@{NSFontAttributeName: font}];
        [attributedString setAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue" size:8]
                                          , NSBaselineOffsetAttributeName:@5} range:NSMakeRange(1, 1)];
        
        [songDetail appendAttributedString:attributedString];
    } else {
        [songDetail appendAttributedString:drone];
    }
    
    NSArray *listItems = [beatOneMusicFile componentsSeparatedByString:@"/"];
    NSString *lastWordString = [NSString stringWithFormat:@"%@", listItems.lastObject];
    
    clap1Path = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], lastWordString];
    
    listItems = [beatTwoMusicFile componentsSeparatedByString:@"/"];
    lastWordString = [NSString stringWithFormat:@"%@", listItems.lastObject];
    
    clap2Path = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], lastWordString ];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    clap3Path = [documentsDirectory stringByAppendingPathComponent:@"/Click.m4a"];
    
    //clap4Path = [NSString stringWithFormat:@"%@/C.wav", [[NSBundle mainBundle] resourcePath]];
    clap4Path = [self locationOfFileWithName:[NSString stringWithFormat:@"%@.m4a", _droneType]];
    firstKnob = _firstVolumeKnob;
    secondKnob = _secondVolumeKnob;
    thirdKnob = _thirdVolumeKnob;
    forthKnob = _fourthVolumeKnob;
    
    firstKnobCentre = firstKnob.center;
    secondKnobCentre = secondKnob.center;
    thirdKnobCentre = thirdKnob.center;
    forthKnobCentre = forthKnob.center;
    
    recFlag1 = [cellData.t1Flag intValue];
    recFlag2 = [cellData.t2Flag intValue];
    recFlag3 = [cellData.t3Flag intValue];
    recFlag4 = [cellData.t4Flag intValue];
}

- (void)setRowIndex:(int)rowIndex {
    currentIndex = rowIndex;
}

- (void)swipedScreen:(UISwipeGestureRecognizer*)swipeGestureEffect {
    UIButton *button = (UIButton *)swipeGestureEffect.view;
    
    if(swipeGestureEffect.direction == UISwipeGestureRecognizerDirectionUp) {
        // Swipe Up
        [self rotateImageViewClockWiseWithButtonTag:(int)button.tag];
        
    } else if (swipeGestureEffect.direction == UISwipeGestureRecognizerDirectionDown) {
        // Swipe Down
        [self rotateImageViewAnticlockWiseWithButtonTag:(int)button.tag];
    }
}

- (void)rotateImageViewClockWiseWithButtonTag :(int)tag{
    //    switch (tag) {
    //        case 1:
    //            VolumeKnobLevelCount = instrV1;
    //            [self spinKnobClockWiseAndModifiedValueOfPassedReferences:&instrV1 imageView:_volImageInstru1];
    //            if (instrV1 == 0)
    //                instrV1 = 1;
    //            [mixerController setInputVolume:0 value:instrV1/10.0f];
    //            break;
    //
    //        case 2:
    //            VolumeKnobLevelCount = instrV2;
    //            [self spinKnobClockWiseAndModifiedValueOfPassedReferences:&instrV2 imageView:_volImageInstru2];
    //            if (instrV2 == 0)
    //                instrV2 = 1;
    //            [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:instrV2 withName:@"clap2"];
    //
    //            break;
    //        case 3:
    //            VolumeKnobLevelCount = instrV3;
    //            [self spinKnobClockWiseAndModifiedValueOfPassedReferences:&instrV3 imageView:_volImageInstru3];
    //            if (instrV3 == 0)
    //                instrV3 = 1;
    //            [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:instrV3 withName:@"clap3"];
    //
    //            break;
    //        case 4:
    //            VolumeKnobLevelCount = instrV4;
    //            [self spinKnobClockWiseAndModifiedValueOfPassedReferences:&instrV4 imageView:_volImageInstru4];
    //            if (instrV4 == 0)
    //                instrV4 = 1;
    //            [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:instrV4 withName:@"clap4"];
    //
    //            break;
    //        case 11:
    //            VolumeKnobLevelCount = tV1;
    //            [self spinKnobClockWiseAndModifiedValueOfPassedReferences:&tV1 imageView:_volImageT1];
    //
    //        if (tV1 == 0)
    //            tV1 = 1;
    //            [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:tV1 withName:@"track1"];
    //
    //            break;
    //        case 22:
    //            VolumeKnobLevelCount = tV2;
    //            [self spinKnobClockWiseAndModifiedValueOfPassedReferences:&tV2 imageView:_volImageT2];
    //            if (tV2 == 0)
    //                tV2 = 1;
    //            [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:tV2 withName:@"track2"];
    //
    //            break;
    //        case 33:
    //            VolumeKnobLevelCount = tV3;
    //            [self spinKnobClockWiseAndModifiedValueOfPassedReferences:&tV3 imageView:_volImageT3];
    //            if (tV3 == 0)
    //                tV3 = 1;
    //            [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:tV3 withName:@"track3"];
    //            break;
    //        case 44:
    //            VolumeKnobLevelCount = tV4;
    //            [self spinKnobClockWiseAndModifiedValueOfPassedReferences:&tV4 imageView:_volImageT4];
    //            if (tV4 == 0)
    //                tV4 = 1;
    //            [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:tV4 withName:@"track4"];
    //
    //            break;
    //
    //        default:
    //            break;
    //    }
    
}

- (void)rotateImageViewAnticlockWiseWithButtonTag:(int)tag{
    
    //    switch (tag) {
    //        case 1:
    //            VolumeKnobLevelCount = instrV1;
    //            [self spinKnobAntiClockWiseAndModifiedValueOfPassedReferences:&instrV1 imageView:_volImageInstru1];
    //            if (instrV1 == 0)
    //                [mixerController setInputVolume:0 value:1/10.0f];
    //            else
    //                [mixerController setInputVolume:0 value:instrV1/10.0f];
    //            break;
    //        case 2:
    //            VolumeKnobLevelCount = instrV2;
    //            [self spinKnobAntiClockWiseAndModifiedValueOfPassedReferences:&instrV2 imageView:_volImageInstru2];
    //            if (instrV2 == 0)
    //                [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:1 withName:@"clap2"];
    //            else
    //                [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:instrV2 withName:@"clap2"];
    //
    //            break;
    //        case 3:
    //            VolumeKnobLevelCount = instrV3;
    //            [self spinKnobAntiClockWiseAndModifiedValueOfPassedReferences:&instrV3 imageView:_volImageInstru3];
    //            if (instrV3 == 0)
    //                [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:1 withName:@"clap3"];
    //            else
    //                [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:instrV3 withName:@"clap3"];
    //
    //            break;
    //        case 4:
    //            VolumeKnobLevelCount = instrV4;
    //            [self spinKnobAntiClockWiseAndModifiedValueOfPassedReferences:&instrV4 imageView:_volImageInstru4];
    //            if (instrV4 == 0)
    //                [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:1 withName:@"clap4"];
    //            else
    //                [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:instrV4 withName:@"clap4"];
    //
    //            break;
    //        case 11:
    //            VolumeKnobLevelCount = tV1;
    //            [self spinKnobAntiClockWiseAndModifiedValueOfPassedReferences:&tV1 imageView:_volImageT1];
    //            if (tV1 == 0)
    //                [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:1 withName:@"track1"];
    //            else
    //                [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:tV1 withName:@"track1"];
    //
    //            break;
    //        case 22:
    //            VolumeKnobLevelCount = tV2;
    //            [self spinKnobAntiClockWiseAndModifiedValueOfPassedReferences:&tV2 imageView:_volImageT2];
    //            if (tV2 == 0)
    //                [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:1 withName:@"track2"];
    //            else
    //                [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:tV2 withName:@"track2"];
    //
    //            break;
    //        case 33:
    //            VolumeKnobLevelCount = tV3;
    //            [self spinKnobAntiClockWiseAndModifiedValueOfPassedReferences:&tV3 imageView:_volImageT3];
    //            if (tV3 == 0)
    //                [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:1 withName:@"track3"];
    //            else
    //                [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:tV3 withName:@"track3"];
    //
    //            break;
    //        case 44:
    //            VolumeKnobLevelCount = tV4;
    //            [self spinKnobAntiClockWiseAndModifiedValueOfPassedReferences:&tV4 imageView:_volImageT4];
    //            if (tV4 == 0)
    //                [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:1 withName:@"track4"];
    //            else
    //                [self setInputVolumeForAudioArray:audioPlayerArray withVoulme:tV4 withName:@"track4"];
    //
    //            break;
    //
    //        default:
    //            break;
    //    }
}

- (void)spinKnobClockWiseAndModifiedValueOfPassedReferences:(int *)volume
                                                 imageView :(UIImageView *)rotateImage{
    if (VolumeKnobLevelCount < 8) {
        [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [rotateImage setTransform:CGAffineTransformRotate(rotateImage.transform, (M_PI/4))];
            
        }completion:^(BOOL finished){
            if (finished) {
                VolumeKnobLevelCount ++;
                *volume = VolumeKnobLevelCount;
            }
        }];
    }
    else{
        *volume = 10;
    }
}

- (void)spinKnobAntiClockWiseAndModifiedValueOfPassedReferences:(int *)volume
                                                     imageView :(UIImageView *)rotateImage{
    if (VolumeKnobLevelCount > 0) {
        
        if (VolumeKnobLevelCount == 10 || VolumeKnobLevelCount == 9) {
            VolumeKnobLevelCount = 8;
        }
        
        [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [rotateImage setTransform:CGAffineTransformRotate(rotateImage.transform, -(M_PI/4))];
        }completion:^(BOOL finished){
            if (finished) {
                VolumeKnobLevelCount --;
                *volume = VolumeKnobLevelCount;
            }
        }];
    }
    else{
        VolumeKnobLevelCount = 0;
    }
}

- (void)resetPlayButtonWithCell{
    [self stopSelectedRhythms];
    playFlag = 0;
    stopFlag = 0;
    seconds = 0.0f;
    [self calculateMicGain:0];
    _recSlider.value = 0.00;
    [self.savedDetailDelegate recordingDone];
    [_recSlider setThumbImage:[UIImage imageNamed:@"volumesqaure_pointer_blue.png"] forState:UIControlStateNormal];
    [_recSlider setMaximumTrackImage:[UIImage imageNamed:@"volumeslider_sqaure_gred.png"] forState:UIControlStateNormal];
    [_recSlider setMinimumTrackImage:[UIImage imageNamed:@"volumeslider_sqaure_blue.png"] forState:UIControlStateNormal];
    _recSlider.minimumValue = 0.00;
    
    [_playRecBtn setBackgroundImage:[UIImage imageNamed:@"PlayIcon"] forState:UIControlStateNormal];
    [_recordingBtn setEnabled:YES];
    [_playRecBtn setEnabled:YES];
    [_recordingBtn setSelected:NO];
    [_playRecBtn setSelected:NO];
    _minRecDurationLbl.text = @"00:00";
    if ([_recTrackOne isEqualToString:@"-1"]) {
        _maxRecDurationLbl.text = @"00:00";
    }
    else
        _maxRecDurationLbl.text = [NSString stringWithFormat:@"-%@",[self timeFormatted:[durationStringUnFormatted intValue]]];
    
    _recordingTimeLabel.text = @"00:00";
    
    [_recordingBGView setHidden:YES];
    [_deleteBGView setHidden:YES];
    [_deleteImageT1 setHidden:YES ];
    [_deleteImageT2 setHidden:YES ];
    [_deleteImageT3 setHidden:YES ];
    [_deleteImageT4 setHidden:YES ];
    
    [_deleteImageT1 setImage:[UIImage imageNamed:@"closebutton.png"]];
    [_deleteImageT2 setImage:[UIImage imageNamed:@"closebutton.png"]];
    [_deleteImageT3 setImage:[UIImage imageNamed:@"closebutton.png"]];
    [_deleteImageT4 setImage:[UIImage imageNamed:@"closebutton.png"]];
    
    if ([_recTrackOne isEqualToString:@"-1"]){
        [_firstVolumeKnob setBackgroundImage:[UIImage imageNamed:@"one_redoutline.png"] forState:UIControlStateNormal];
        recFlag1 = 0;
        
    }
    else if ([_recTrackTwo isEqualToString:@"-1"]){
        [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_redoutline.png"] forState:UIControlStateNormal];
        recFlag2 = 0;
        
    }
    else if ([_recTrackThree isEqualToString:@"-1"]){
        [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_redoutline.png"] forState:UIControlStateNormal];
        recFlag3 = 0;
        
    }
    else if ([_recTrackFour isEqualToString:@"-1"]){
        [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_redoutline.png"] forState:UIControlStateNormal];
        recFlag4 = 0;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"recordingDone" object:nil];
    
}

- (void) updateMicGain:(NSNotification *) notification {
    NSDictionary *micGainDct = notification.object;
    endresult = [micGainDct[@"micGainValue"] intValue];
    
    if(endresult > 0 && endresult <= 9){
        [self calculateMicGain:0];
    }
    else if(endresult > 9 && endresult <= 10){
        [self calculateMicGain:1];
    }
    else if(endresult > 10 && endresult <= 100){
        [self calculateMicGain:endresult/10 + 1];
    }
}

- (void) calculateMicGain:(int) gain {
    
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
                [img setImage:[UIImage imageNamed:@"green-strip.png"]];
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

- (void)createFileWithName:(NSString *)fileName{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    // 1st, This funcion could allow you to create a file with initial contents.
    // 2nd, You could specify the attributes of values for the owner, group, and permissions.
    // Here we use nil, which means we use default values for these attibutes.
    // 3rd, it will return YES if NSFileManager create it successfully or it exists already.
    if ([manager createFileAtPath:filePath contents:nil attributes:nil]) {
        //NSLog(@"Created the File Successfully.");
    } else {
        //NSLog(@"Failed to Create the File");
    }
}

- (void)renameFileWithName:(NSString *)srcName toName:(NSString *)dstName{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePathSrc = [documentsDirectory stringByAppendingPathComponent:srcName];
    NSString *filePathDst = [documentsDirectory stringByAppendingPathComponent:dstName];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePathSrc]) {
        NSError *error = nil;
        [manager moveItemAtPath:filePathSrc toPath:filePathDst error:&error];
        if (error) {
            //NSLog(@"There is an Error: %@", error);
        }
        else
            newPath = filePathDst;
    } else {
        //NSLog(@"File %@ doesn't exists", srcName);
    }
}


-(BOOL)renameFileName:(NSString*)oldname withNewName:(NSString*)newname{
    documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *oldPath = [documentDir stringByAppendingPathComponent:oldname];
    newPath = [documentDir stringByAppendingPathComponent:newname];
    
    NSFileManager *fileMan = [NSFileManager defaultManager];
    NSError *error = nil;
    //NSLog(@"file exist :%d", [fileMan fileExistsAtPath:oldname]);
    if (![fileMan moveItemAtPath:oldPath toPath:newPath error:&error])
    {
        //NSLog(@"Failed to move '%@' to '%@': %@", oldPath, newPath, [error localizedDescription]);
        return false;
    }
    [self trimAudioFileWithInputFilePath:newPath toOutputFilePath:newPath withFlag:YES];
    return true;
}

- (NSString *) timeStamp {
    return [NSString stringWithFormat:@"%ld",(long int)[[NSDate date] timeIntervalSince1970]];
}

float roundUp (float value, int digits) {
    
    int mod = pow(10, digits);
    
    float roundedUp = value;
    if (mod != 0) {
        roundedUp = ceilf(value * mod) / mod;
    }
    
    return roundedUp;
}

- (double)processAudio:(float)totalFileDuration withFilePathURL:(NSURL *)filePathURL{
    NSMutableData *data = [NSMutableData dataWithContentsOfURL:filePathURL];
    NSMutableData *Wave1= [NSMutableData dataWithData:[data subdataWithRange:NSMakeRange(44, [data length] - 44)]];
    uint8_t * bytePtr = (uint8_t  * )[Wave1 bytes] ;
    NSInteger totalData = [Wave1 length] / sizeof(uint8_t);
    int endRange = 0;
    for (int i = 0 ; i < totalData; i ++){
        if (bytePtr[i] == 0) {
            endRange = i;
        }else
            break;
    }
    
    double silentAudioDuration =((endRange/(float)totalData)*totalFileDuration)*10;
    return silentAudioDuration;
}

- (void)trimAudioFileWithInputFilePath:(NSString *)inputPath
                      toOutputFilePath:(NSString *)outputPath
                              withFlag:(BOOL)isRecordedFile {
    // Path of your source audio file
    NSString *strInputFilePath = inputPath;
    NSURL *audioFileInput = [NSURL fileURLWithPath:strInputFilePath];
    
    // Path of trimmed file.
    float startTrimTime;
    float endTrimTime;
    NSString *strOutputFilePath;
    
    if(isRecordedFile) {
        strOutputFilePath = [outputPath stringByDeletingPathExtension];
        strOutputFilePath = [strOutputFilePath stringByAppendingString:@".m4a"];
    } else {
        strOutputFilePath = outputPath;
    }
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
    
    if(isRecordedFile) {
        // Start time from which you want the audio file to be saved.
        if([MainNavigationViewController isIPhoneOlderThanVersion6])
            startTrimTime = 0.117;
        else
            startTrimTime = 0.15;
        // End time till which you want the audio file to be saved.
        // For eg. your file's length.
        endTrimTime = audioDurationSeconds;
        recordingDuration = audioDurationSeconds-startTrimTime;
    } else {
        startTrimTime = 0.0;
        float tempoRatio = [_startBPM floatValue]/60.0f;
        endTrimTime = 1.0f/tempoRatio;
    }
    
    CMTime startTime = CMTimeMake((int)(floor(startTrimTime * 44100)), 44100);
    CMTime stopTime = CMTimeMake((int)(ceil(endTrimTime * 44100)), 44100);
    CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime);
    
    exportSession.outputURL = audioFileOutput;
    exportSession.outputFileType = AVFileTypeAppleM4A;
    exportSession.timeRange = exportTimeRange;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^
     {
         if (AVAssetExportSessionStatusCompleted == exportSession.status)
         {
             if(isRecordedFile) {
                 NSFileManager *fileManager = [NSFileManager defaultManager];
                 if ([fileManager fileExistsAtPath:inputPath]) {
                     [fileManager removeItemAtPath:inputPath error:nil];
                 }
             }
         }
         else if (AVAssetExportSessionStatusFailed == exportSession.status)
         {
             // NSLog(@"failed");
         }
     }];
}

- (void)trimAudioFileInputFilePath:(NSString *)inputPath
                  toOutputFilePath:(NSString *)outputPath
                 withStartTrimTime:(float)startTrimTime {
    
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
    
    //float tempo = [_startBPM floatValue]/[originalBPM floatValue];
    
    //startTrimTime = 0.0525/tempo;
    
    //startTrimTime = 0.0480/tempo;        //snn
    
    //[self processAudio:audioDurationSeconds withFilePathURL:audioFileInput];
    // End time till which you want the audio file to be saved.
    // For eg. your file's length.
    
    // snair
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
    
    CMTime startTime = CMTimeMake((int)(floor(startTrimTime * 44100)), 44100);
    CMTime stopTime = CMTimeMake((int)(ceil(endTrimTime * 44100)), 44100);
    CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime);
    
    exportSession.outputURL = audioFileOutput;
    exportSession.outputFileType = AVFileTypeAppleM4A;
    exportSession.timeRange = exportTimeRange;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^
     {
         if (AVAssetExportSessionStatusCompleted == exportSession.status)
         {
             //NSLog(@"Success!");
             //             sound = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:newPath] error:nil];
             //             NSLog(@"Duration = %f",sound.duration);
             
         }
         else if (AVAssetExportSessionStatusFailed == exportSession.status)
         {
             //NSLog(@"failed");
         }
     }];
}

-(void)recordingFinished{
    int value = [[userDefaults objectForKey:@"recodingid"] intValue];
    
    currentMusicFileName = [NSString stringWithFormat:@"music %d",++value];
    
    [userDefaults setObject:[NSString stringWithFormat:@"%d",value] forKey:@"recodingid"];
    [userDefaults synchronize];
    
    time_t     now = time(0);
    struct tm  tstruct;
    char       date[80];
    char       time[80];
    tstruct = *localtime(&now);
    strftime(date, sizeof(date), "%d/%m/%Y", &tstruct);
    strftime(time, sizeof(time), "%X", &tstruct);
    
    currentMusicFileName=[currentMusicFileName stringByAppendingString:@".wav"];
    
    NSString *str = [NSString stringWithFormat:@"Recording_%@_%@.wav",recordID,[self timeStamp]];
    [self renameFileName:@"MyAudioMemo.wav" withNewName:str];
    
    NSString *songDurationToSave;
    
    if (recordingDuration >= [durationStringUnFormatted floatValue]) {
        songDurationToSave = [NSString stringWithFormat:@"%f",recordingDuration];
        _TotalTimeLbl.text = [self timeFormatted:[songDurationToSave intValue]];
        durationStringUnFormatted = songDurationToSave;
        _maxRecDurationLbl.text = [NSString stringWithFormat:@"-%@",[self timeFormatted:[songDurationToSave floatValue]] ];
    }
    else {
        songDurationToSave = durationStringUnFormatted;
    }
    
    if ([_recTrackOne isEqualToString:@"-1"]) {
        
        [sqlManager updateSingleRecordingDataWithRecordingId:[recordID intValue] trackSequence:1 track:newPath maxTrackDuration:songDurationToSave trackDuration:[NSString stringWithFormat:@"%f",recordingDuration]];
        
        _recTrackOne = newPath;
        recFlag1 = 1;
        tV1 = 100;
        tP1 = 50;
        [_rotatryT1 setValue:100 animated:NO];
        t1Duration = [NSString stringWithFormat:@"%f",recordingDuration];
        
        [_firstVolumeKnob setSelected:YES];
        [_rotatryT1 setHidden:NO];
        [_firstVolumeKnob setBackgroundImage:[UIImage imageNamed:@"one_darkgrey.png"] forState:UIControlStateNormal];
        [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_redoutline.png"] forState:UIControlStateNormal];
        [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_greyoutline.png"] forState:UIControlStateNormal];
        [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
    }
    else if ([_recTrackTwo isEqualToString:@"-1"]) {
        
        [sqlManager updateSingleRecordingDataWithRecordingId:[recordID intValue]  trackSequence:2 track:newPath maxTrackDuration:songDurationToSave trackDuration:[NSString stringWithFormat:@"%f",recordingDuration]];
        _recTrackTwo = newPath;
        recFlag2 = 1;
        tV2 = 100;
        tP2 = 50;
        [_rotatryT2 setValue:100 animated:NO];
        t2Duration = [NSString stringWithFormat:@"%f",recordingDuration];
        
        [_secondVolumeKnob setSelected:YES];
        [_rotatryT2 setHidden:NO];
        [_secondVolumeKnob setBackgroundImage:[UIImage imageNamed:@"two_darkgrey.png"] forState:UIControlStateNormal];
        [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_redoutline.png"] forState:UIControlStateNormal];
        [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_greyoutline.png"] forState:UIControlStateNormal];
    }
    else if ([_recTrackThree isEqualToString:@"-1"]) {
        
        t3Duration = [NSString stringWithFormat:@"%f",recordingDuration];
        
        [sqlManager updateSingleRecordingDataWithRecordingId:[recordID intValue]  trackSequence:3 track:newPath maxTrackDuration:songDurationToSave trackDuration:[NSString stringWithFormat:@"%f",recordingDuration]];
        _recTrackThree = newPath;
        recFlag3 = 1;
        tV3 = 100;
        tP3 = 50;
        [_rotatryT3 setValue:100 animated:NO];
        [_thirdVolumeKnob setSelected:YES];
        [_rotatryT3 setHidden:NO];
        
        [_thirdVolumeKnob setBackgroundImage:[UIImage imageNamed:@"three_darkgrey.png"] forState:UIControlStateNormal];
        [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_redoutline.png"] forState:UIControlStateNormal];
        
    }
    else if ([_recTrackFour isEqualToString:@"-1"]) {
        
        [sqlManager updateSingleRecordingDataWithRecordingId:[recordID intValue]  trackSequence:4 track:newPath maxTrackDuration:songDurationToSave trackDuration:[NSString stringWithFormat:@"%f",recordingDuration]];
        _recTrackFour = newPath;
        recFlag4 = 1;
        tV4 = 100;
        tP4 = 50;
        [_rotatryT4 setValue:100 animated:YES];
        t4Duration = [NSString stringWithFormat:@"%f",recordingDuration];
        
        [_fourthVolumeKnob setSelected:YES];
        [_rotatryT4 setHidden:NO];
        [_fourthVolumeKnob setBackgroundImage:[UIImage imageNamed:@"four_darkgrey.png"] forState:UIControlStateNormal];
    }
}

-(void)onPlayOrRecordTimer:(NSTimer *)timerNotification {
    
    //    //    seconds++;
    //    //    if(seconds == 60)
    //    //    {
    //    //        seconds = 0;
    //    //        minutes++;
    //    //    }
    //
    //    //NSString* duration = [NSString stringWithFormat:@"%.2d:%.2d", minutes, seconds];
    //    NSString* duration;
    //    if ([_recorder isRecording]) {
    //        duration = [self timeFormatted:_recorder.currentTime];
    //    } else
    //    {
    //
    //        if((int)_recAudioPlayer1.duration == [durationStringUnFormatted intValue])
    //            duration = [self timeFormatted:_recAudioPlayer1.currentTime];
    //        else if ((int)_recAudioPlayer2.duration == [durationStringUnFormatted intValue])
    //            duration = [self timeFormatted:_recAudioPlayer2.currentTime];
    //        else if ((int)_recAudioPlayer3.duration == [durationStringUnFormatted intValue])
    //            duration = [self timeFormatted:_recAudioPlayer3.currentTime];
    //        else if ((int)_recAudioPlayer4.duration == [durationStringUnFormatted intValue])
    //            duration = [self timeFormatted:_recAudioPlayer4.currentTime];
    //    }
    //
    //    // record timer value change
    //    _recordTimerText = duration;
    //    if ([_recTrackOne isEqualToString:@"-1"]) {
    //        _recordingTimeLabel.text = @"00:00";
    //    }
    //    else
    //    _recordingTimeLabel.text = _recordTimerText;
    //    [self setVolumeInputOutput];
}

- (void)restartMixer {
    if([_playRecBtn isUserInteractionEnabled])  {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:@"AUDIOROUTECHANGE"
                                                      object:nil];
        
        //[_session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
        
        if(playFlag == 1) {
            [self stopAudioFiles];
            [self resetPlayButtonWithCell];
        }
        
        if ([audioRecorder isRecording]) {
            
            [audioRecorder stopAudioRecording];
            [self resetPlayButtonWithCell];
            //[self recordingFinished ];
        }
        
        [_session setPreferredInput:_myPort error:nil];
        
        if(playFlag == 1) {   // make changes here
            _playRecBtn.userInteractionEnabled = NO;
            [_playRecBtn setBackgroundImage:[UIImage imageNamed:@"stopicon.png"] forState:UIControlStateNormal];
            [_recordingBtn setEnabled:NO];
            
            _recSlider.maximumValue = [durationStringUnFormatted floatValue];

            [self performSelector:@selector(playSelectedRecording) withObject:self afterDelay:1.0];
        }
    }
}

-(void)setVolumeInputOutput{
    currentOutputs = _session.currentRoute.outputs;
    for( _output in currentOutputs ){
        if([_output.portType isEqualToString:AVAudioSessionPortHeadphones]){
            //cout << "                      AVAudioSessionPortHeadphones                          ";
            //[_session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
            ////////[_session setPreferredInput:_myPort error:nil];
            //NSLog(@"Headphones\n");
            [self restartMixer];
            break;
        }
        else if([_output.portType isEqualToString:AVAudioSessionPortBuiltInSpeaker]){
            //cout << "                      AVAudioSessionPortBuiltInSpeaker                          ";
            //NSLog(@"Speaker\n");
            [self restartMixer];
            break;
        }
        else if([_output.portType isEqualToString:AVAudioSessionPortBuiltInReceiver]){
            //cout << "                      AVAudioSessionPortBuiltInReceiver                          ";
            // [_session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
            break;
        }
    }
}

- (void)stopSelectedRhythms {
    
    if (_clap3Timer != nil) {
        [_clap3Timer invalidate];
        _clap3Timer = nil;
        
        _audioPlayerClap3.currentTime = 0;
        [_audioPlayerClap3 stop];
        _audioPlayerClap3 = nil;
    }
    if (_updateSliderTimer != nil) {
        [_updateSliderTimer invalidate];
        _updateSliderTimer = nil;
    }
    
    if (_playTimer != nil) {
        [_playTimer invalidate];
        _playTimer = nil;
    }
    
    [audioPlayerArray removeAllObjects];
    [self stopAudioFiles];
}

-(void)updateSlider:(NSTimer *)timer {
    // Update the slider about the music time
    if (stopFlag == 1) {
        NSString *maxDuration = [self timeFormatted:seconds];
        [_recorder updateMeters];
        _minRecDurationLbl.text = @"00:00";
        _maxRecDurationLbl.text = maxDuration;
        _recordingTimeLabel.text = maxDuration;
        [_recSlider setValue:seconds animated:YES];
    }
    else {
        if ([_recTrackOne isEqualToString:@"-1"]) {
            _maxRecDurationLbl.text =  @"00:00";
            _recordingTimeLabel.text = @"00:00";
            return ;
        }
        
        NSString *maxDuration = [self timeFormatted:[durationStringUnFormatted floatValue] - seconds];
        [self configureSliderValues:@{@"MINDURATION":[self timeFormatted:seconds],@"MAXDURATION":maxDuration}];
        _recSlider.value = seconds;
        
        if ([maxDuration isEqualToString:@"00:00"]) {
            _maxRecDurationLbl.text =  @"-00:01";
        }
        
        if ([durationStringUnFormatted floatValue] - seconds < 0.0) {
            [self resetPlayButtonWithCell];
        }
    }
    seconds += 0.1f;
}

-(void)configureSliderValues:(NSDictionary *)options{
    _minRecDurationLbl.text = [options valueForKey:@"MINDURATION"];
    _recordingTimeLabel.text = [options valueForKey:@"MINDURATION"];
    _maxRecDurationLbl.text =  [NSString stringWithFormat:@"-%@",[options valueForKey:@"MAXDURATION"]];
}

- (NSString *)timeFormatted:(int)totalSeconds{
    int second = totalSeconds % 60;
    int minute = (totalSeconds / 60) % 60;
    
    return [NSString stringWithFormat:@"%02d:%02d",minute, second];
}

- (void)playMemos:(NSString *)memo{
    _audioPlayerClap4 = nil;
    
    _audioPlayerClap4 = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@.m4a", [[NSBundle mainBundle] resourcePath], memo]] error:nil];
    _audioPlayerClap4.numberOfLoops = -1;
    _audioPlayerClap4.enableRate = true;
    _audioPlayerClap4.rate = [_startBPM floatValue]/[originalBPM floatValue];
}

- (NSString*)locationOfFileWithName:(NSString*)fileName{
    NSArray* array = [fileName componentsSeparatedByString:@"/"];
    NSString *beatFilePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], array.lastObject];
    
    //    beatFilePath = [beatFilePath stringByReplacingOccurrencesOfString:@"m4a"
    //                                                           withString:@"wav"];
    return beatFilePath;
}

-(void)startRecord{
    [audioRecorder startAudioRecording:@"MyAudioMemo.wav"];
}

-(void)startMixer{
    [mixerController startAUGraph];
}

-(void)startAUGraphVC {
    _updateSliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                          target:self selector:@selector(updateSlider:) userInfo:nil repeats:YES];
    [_updateSliderTimer fire];
    
    if (stopFlag == 1) {
        [self startMixer];
        
        [audioRecorder startRecording];
    }
    else
        [self startMixer];
    
    _playRecBtn.userInteractionEnabled = YES;
    if(stopFlag == 1)
        [self performSelector:@selector(enableRecordingButton) withObject:self afterDelay:1.0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChanged:) name:@"AUDIOROUTECHANGE" object:nil];
}

- (void) enableRecordingButton {
    _recordingBtn.userInteractionEnabled = YES;
}

- (NSDictionary*)getTheDictionaryWithFileLocation:(NSString*)locaiton
                                           volume:(NSString*)volume
                                              pan:(NSString*)pan
                                              bpm:(NSNumber*)rhythmBpmValue
                                      andStartBPM:(NSNumber*)rhythmStartBPMValue
                                         fileType:(NSString*)type
                                 withRecordString:(NSString*)recordedString{
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

- (void)stopAudioFiles {
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"enablePagingNotification"
    //                                                    object:@"YES"];
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;

    [mixerController stopAUGraph:YES];
}


- (void) playSelectedRecording{
    NSString *fileLocation;
    NSString *volume;
    NSString *pan;
    NSDictionary *dct;
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"enablePagingNotification"
    //                                                    object:@"NO"];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
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
    
    fileLocation = [MainNavigationViewController getAbsDocumentsPath:@"Click.m4a"];
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
    
    //[self setInputVolumeForAudioArray:audioPlayerArray withVoulme:0 withName:@"clap3"];
    if(stopFlag == 1) {
        [audioRecorder startAudioRecording:@"MyAudioMemo.wav"];
        
        if([self getSelectedMicrophone] == kUserInput_BuiltIn) {
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
    
    [self performSelector:@selector(startAUGraphVC) withObject:self afterDelay:1.0];
    
}

- (void) LongPress:(UILongPressGestureRecognizer *)gesture{
    NSLog(@" long press pressed");
    NSLog(@"Play Flag Value = =%d",playFlag);
    if (playFlag != 1) {
        
        UIButton *button = (UIButton *)gesture.view;
        
        if ((button.tag == 5 && [_recTrackOne isEqualToString:@"-1"]) || (button.tag == 6 && [_recTrackTwo isEqualToString:@"-1"]) || (button.tag == 7 && [_recTrackThree isEqualToString:@"-1"]) || (button.tag == 8 && [_recTrackFour isEqualToString:@"-1"])) {
            return;
        }
        //[_deleteBGView setHidden:NO];
        
        if (button.tag == 5) {
            [_deleteImageT1 setHidden:NO];
            [self.view bringSubviewToFront:_firstVolumeKnob];
            [self.view bringSubviewToFront:_deleteImageT1];
            //[_firstVolumeKnob setHidden:YES];
        }
        else if(button.tag == 6){
            [_deleteImageT2 setHidden:NO];
            [self.view bringSubviewToFront:_secondVolumeKnob];
            [self.view bringSubviewToFront:_deleteImageT2];
        }
        else if(button.tag == 7){
            [_deleteImageT3 setHidden:NO];
            [self.view bringSubviewToFront:_thirdVolumeKnob];
            [self.view bringSubviewToFront:_deleteImageT3];
        }
        else{
            [_deleteImageT4 setHidden:NO];
            [self.view bringSubviewToFront:_fourthVolumeKnob];
            [self.view bringSubviewToFront:_deleteImageT4];
        }
        
        didHold = YES;
    }
}

- (IBAction) imageMoved:(id) sender withEvent:(UIEvent *) event{
    UIControl *control = sender ;
    int tag = (int)control.tag;
    
    UITouch *t = [[event allTouches] anyObject];
    CGPoint pPrev = [t previousLocationInView:control];
    CGPoint p = [t locationInView:control];
    
    CGPoint center = control.center;
    center.x += p.x - pPrev.x;
    center.y += p.y - pPrev.y;
    control.center = center;
    
    if(CGRectContainsPoint(control.frame, trashButton.center)){
        if(t.phase == UITouchPhaseEnded){
            if(tag == 1){
                control.hidden = YES;
                control.center = secondKnobCentre;
                secondKnob.center = thirdKnobCentre;
                thirdKnob.center = forthKnobCentre;
                forthKnob.center = forthKnobCentre;
                
                [UIView animateWithDuration:0.5
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     // set the new frame
                                     control.hidden = NO;
                                     control.center = firstKnobCentre;
                                     secondKnob.center = secondKnobCentre;
                                     thirdKnob.center = thirdKnobCentre;
                                     forthKnob.hidden = YES;
                                     //control.center = forthKnobCentre;
                                     
                                 }
                                 completion:^(BOOL finished){
                                     forthKnob.hidden = NO;
                                     forthKnob.center = forthKnobCentre;
                                 }
                 ];
            }
            
            if(tag == 2){
                control.hidden = YES;
                control.center = thirdKnobCentre;
                thirdKnob.center = forthKnobCentre;
                forthKnob.center = forthKnobCentre;
                
                
                [UIView animateWithDuration:0.5
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     // set the new frame
                                     control.hidden = NO;
                                     control.center = secondKnobCentre;
                                     thirdKnob.center = thirdKnobCentre;
                                     forthKnob.hidden = YES;
                                     
                                     
                                 }
                                 completion:^(BOOL finished){
                                     forthKnob.hidden = NO;
                                     forthKnob.center = forthKnobCentre;
                                 }
                 ];
            }
            
            if(tag == 3){
                control.hidden = YES;
                control.center = forthKnobCentre;
                forthKnob.center = forthKnobCentre;
                
                [UIView animateWithDuration:0.5
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     // set the new frame
                                     control.hidden = NO;
                                     control.center = thirdKnobCentre;
                                     forthKnob.hidden = YES;
                                 }
                                 completion:^(BOOL finished){
                                     
                                     forthKnob.hidden = NO;
                                     forthKnob.center = forthKnobCentre;
                                 }
                 ];
            }
            
            if(tag == 4){
                control.hidden = YES;
                control.center = forthKnobCentre;
                forthKnob.center = forthKnobCentre;
                
                [UIView animateWithDuration:0.5
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     // set the new frame
                                     control.hidden = NO;
                                     
                                 }
                                 completion:^(BOOL finished){
                                     //NSLog(@"Done!");
                                     
                                 }
                 ];
            }
            
        }
    }
    else{
        if(t.phase == UITouchPhaseEnded){
            if (control.tag == 1) {
                control.hidden = NO;
                control.center = firstKnobCentre;
            }
            if (control.tag == 2) {
                control.hidden = NO;
                control.center = secondKnobCentre;
            }
            if (control.tag == 3) {
                control.hidden = NO;
                control.center = thirdKnobCentre;
            }
            if (control.tag == 4) {
                control.hidden = NO;
                control.center = forthKnobCentre;
            }
        }
    }
}

//#pragma mark - In App Purchase.
///////In App Purchase.
//
//-(void)fetchAvailableProducts {
//    [waitAlertView show];
//
//    NSSet *productIdentifiers = [NSSet
//                                 setWithObjects:PRODUCT_ID, nil];
//    productsRequest = [[SKProductsRequest alloc]
//                       initWithProductIdentifiers:productIdentifiers];
//    productsRequest.delegate = self;
//    [productsRequest start];
//}
//
//- (BOOL)canMakePurchases{
//    return [SKPaymentQueue canMakePayments];
//}
//
//- (void)purchaseMyProduct:(SKProduct*)product{
//    if ([self canMakePurchases]) {
//        SKPayment *payment = [SKPayment paymentWithProduct:product];
//        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
//        [[SKPaymentQueue defaultQueue] addPayment:payment];
//    }
//    else{
//        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:
//                                  @"Purchases are disabled in your device" message:nil delegate:
//                                  self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
//        [alertView show];
//    }
//}
//
//-(void)paymentQueue:(SKPaymentQueue *)queue
//updatedTransactions:(NSArray *)transactions {
//    for (SKPaymentTransaction *transaction in transactions) {
//        switch (transaction.transactionState) {
//            case SKPaymentTransactionStatePurchasing:
//                //NSLog(@"Purchasing");
//                 [waitAlertView show];
//                break;
//                
//            case SKPaymentTransactionStatePurchased:
//                if ([transaction.payment.productIdentifier
//                     isEqualToString:PRODUCT_ID]) {
//                    //NSLog(@"Purchased ");
//                    [waitAlertView dismissWithClickedButtonIndex:0 animated:YES];
//                    [MainNavigationViewController setPurchaseInfo:PRODUCT_PURCHASED];
//                    self.recordingBtn.alpha =  1.0;
//                }
//                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
//                break;
//                
//            case SKPaymentTransactionStateRestored:
//            {
//                //NSLog(@"Restored ");
//                isPurchaseRestored = YES;
//                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
//            }
//                break;
//                
//            case SKPaymentTransactionStateFailed:
//                //NSLog(@"Purchase failed");
//                [MainNavigationViewController setPurchaseInfo:PRODUCT_NOT_PURCHASED];   // change this
//                [waitAlertView dismissWithClickedButtonIndex:0 animated:YES];
//                break;
//            default:
//                break;
//        }
//    }
//}
//
//-(void)productsRequest:(SKProductsRequest *)request
//    didReceiveResponse:(SKProductsResponse *)response{
//    SKProduct *validProduct = nil;
//    int count = (int)[response.products count];
//    if (count>0) {
//        validProducts = response.products;
//        validProduct = [response.products objectAtIndex:0];
//        if ([validProduct.productIdentifier
//             isEqualToString:PRODUCT_ID]) {
//            [self purchaseMyProduct:validProduct];
//        }
//    } else {
//        UIAlertView *tmp = [[UIAlertView alloc]
//                            initWithTitle:@"Not Available"
//                            message:@"No products to purchase"
//                            delegate:self
//                            cancelButtonTitle:nil
//                            otherButtonTitles:@"Ok", nil];
//        [tmp show];
//    }
//}
//
//-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
//    
//    if(isPurchaseRestored) {
//        UIAlertView *tmp = [[UIAlertView alloc]
//                            initWithTitle:@"Restored Purchase"
//                            message:@"Your in app purshase has been restored"
//                            delegate:self
//                            cancelButtonTitle:nil
//                            otherButtonTitles:@"Ok", nil];
//        [tmp show];
//        [MainNavigationViewController setPurchaseInfo:PRODUCT_PURCHASED];
//        self.recordingBtn.alpha =  1.0;
//    }
//}
//
//-(void)paymentQueueRestoreCompletedTransactionsFailedWithError:(NSError *)error {
//    //[self fetchAvailableProducts];
//}
//


@end
