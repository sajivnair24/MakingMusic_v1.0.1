//
//  RecordViewController.h
//  FlamencoRhythm
//
//  Created by Mayank Mathur on 04/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iCarousel.h"
#include <AVFoundation/AVFoundation.h>
#include <MediaPlayer/MPVolumeView.h>
#include <MediaPlayer/MPMusicPlayerController.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import "DropDown.h"
#import "AppDelegate.h"

@class MainNavigationViewController;
@class DBManager;
@class RhythmClass;

@protocol RecordViewProtocol <NSObject>

- (void)tappedRecordButton;
- (void) recordingDone;
@end

@interface RecordViewController : UIViewController<UIAlertViewDelegate,UIGestureRecognizerDelegate,iCarouselDataSource, iCarouselDelegate,AVAudioPlayerDelegate,DropDownDelegate>{
    // Music File
    
    NSArray *currentOutputs;
    IBOutlet UIImageView *mic1;
    IBOutlet UIImageView *mic2;
    IBOutlet UIImageView *mic3;
    IBOutlet UIImageView *mic4;
    IBOutlet UIImageView *mic5;
    IBOutlet UIImageView *mic6;
    IBOutlet UIImageView *mic7;
    IBOutlet UIImageView *mic8;
    IBOutlet UIImageView *mic9;
    IBOutlet UIImageView *mic10;
    NSArray *micArray;
    
    IBOutlet UIImageView *circle1;
    IBOutlet UIImageView *circle2;
    IBOutlet UIImageView *circle3;
    IBOutlet UIImageView *circle4;
    IBOutlet UIImageView *circle5;
    IBOutlet UIImageView *circle6;
    IBOutlet UIImageView *circle7;
    IBOutlet UIImageView *circle8;
    IBOutlet UIImageView *circle9;
    IBOutlet UIImageView *circle10;
    IBOutlet UIImageView *circle11;
    IBOutlet UIImageView *circle12;
    // End here
    AVAudioPlayer * sound;
    
    int beatCount;
    int isStopped;
    
    NSUserDefaults *userDefaults;
    int carouselFirtValue;
    float tempoVal;     //sn
    float recordingDuration;
    
    /***Nirma***/
    UISlider *bpmSlider;
    UIView *bpmSliderBackGround;
    UIVisualEffectView *visualEffectView;
    UIButton *clap3ImageView;
    UIView *footerFadedBackground;
    /***Nirma***/
}

@property (nonatomic, assign) id<RecordViewProtocol> recordDelegate;
@property (strong, nonatomic) IBOutlet UIView *dropDownBgView;

@property (strong, nonatomic) IBOutlet UIView *elementsView;
@property (nonatomic, strong) IBOutlet iCarousel *carousel;
@property (strong, nonatomic) IBOutlet UIButton *playBtn;
@property (strong, nonatomic) IBOutlet UIButton *stopBtn;
@property (strong, nonatomic) IBOutlet UISlider *volumeSlider;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *micGainFirstLeading;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *Instrument1_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *Instrument2_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *Instrument3_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *Bpm_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *Intrument4_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *drone_Layout;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *beat1Circle_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *beat2Circle_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *beat3Circle_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *beat4Circle_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *beat5Circle_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *beat6Circle_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *beat7Circle_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *beat8Circle_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *beat9Circle_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *beat10Circle_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *beat11Circle_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *beat12Circle_Layout;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleImageViewLayout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *carausalBgLayout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *carauselLayout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *blackView_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *instrumentView_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *micView_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *beatsView_Layout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *recordView_Layout;

@property (strong, nonatomic) IBOutlet UIView *recordView;
@property (strong, nonatomic) IBOutlet UIView *bpmView;
@property (strong, nonatomic) IBOutlet UIView *micView;
@property (strong, nonatomic) IBOutlet UIView *beatsView;
@property (strong, nonatomic) IBOutlet UILabel *playTimerBtn;
@property (strong, nonatomic) IBOutlet UILabel *playStopBtn;
@property (strong, nonatomic) IBOutlet UIView *instrumentView;

@property (weak, nonatomic) IBOutlet UIButton *dronBtn;
@property (weak, nonatomic) IBOutlet UIPickerView *dronePickerView;
@property (weak, nonatomic) IBOutlet UIPickerView *bpmPickerView;
@property (strong, nonatomic) IBOutlet UIView *topPickerView;
@property (weak, nonatomic) IBOutlet UIView *bottomPickerView;
@property (strong, nonatomic) NSDictionary *genreIdDict;
@property (readwrite, nonatomic) int genreIdSelected;
@property (readwrite, nonatomic) int bpmDefaultFlag;

// Sajiv Functionality Elements
@property (strong, nonatomic) IBOutlet UILabel *bpmTxt;
@property (strong, nonatomic) IBOutlet UILabel *recordTimerText;
@property (strong, nonatomic)  NSTimer *playTimer, *recordTimer,*recImgTimer;
@property (strong, nonatomic)  NSString *bpmString;
@property (strong, nonatomic)  AVAudioSession *session;
@property (strong, nonatomic)  AVAudioSessionPortDescription *input;
@property (strong, nonatomic)  AVAudioSessionPortDescription *output;
@property (strong, nonatomic)  AVAudioSessionPortDescription *myPort;
@property (strong, nonatomic)  MPVolumeView *volumeView;
@property (strong, nonatomic)  MPMusicPlayerController *musicPlayer;

- (float) bpmForSelectedRythm:(NSString*)_rythm;
- (void) calculateMicGain:(int) gain;

@property (strong, nonatomic) MainNavigationViewController *myNavigationController;
// Ends here

@property (nonatomic, retain)	AVAudioPlayer			*appSoundPlayer;
@property (nonatomic, retain)	UIImage					*noArtworkImage;
@property (nonatomic, retain)	UIBarButtonItem			*artworkItem;
@property (nonatomic, retain)	UILabel					*nowPlayingLabel;
@property (strong, nonatomic) IBOutlet UIButton *instBtn1;
@property (strong, nonatomic) IBOutlet UIButton *instBtn2;
@property (strong, nonatomic) IBOutlet UIButton *instBtn3;
@property (strong, nonatomic) NSString *droneType;
@property (weak, nonatomic) IBOutlet UIButton *dropDownBtn;
@property (weak, nonatomic) IBOutlet UILabel *dropDownLbl;
@property (weak, nonatomic) IBOutlet UIView *bpmPickderBackView;
@property (weak, nonatomic) IBOutlet UIView *dronePickerBackView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImage;
@property (weak, nonatomic) IBOutlet UIImageView *genreBGView;
@property (weak, nonatomic) IBOutlet UILabel *micDropDownLbl;
@property (weak, nonatomic) IBOutlet UIView *controlsView;


- (IBAction)onTapClap1Btn:(id)sender;
- (IBAction)onTapClap2Btn:(id)sender;
- (IBAction)onTapClap3Btn:(id)sender;
- (IBAction)onTapClap4Btn:(id)sender;
- (IBAction)onTapPlayBtn:(id)sender;
- (IBAction)onTapStopBtn:(id)sender;

- (IBAction)onChangeBPM:(id)sender;
-(void)setDataToUIElements:(int)_cnt;

@end