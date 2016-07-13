//
//  SavedListDetailViewController.h
//  FlamencoRhythm
//
//  Created by Ashish Gore on 21/05/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <AVFoundation/AVFoundation.h>
#include <MediaPlayer/MPVolumeView.h>
#include <MediaPlayer/MPMusicPlayerController.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVAudioPlayer.h>
#import "DBManager.h"
//#import <StoreKit/StoreKit.h>
#import "RhythmClass.h"
#import "RecordingListData.h"
#import "TTOpenInAppActivity.h"
#import "CustomActionSheet.h"


// Add new instance variable

@class MainNavigationViewController;

@protocol ExpandedCellDelegate <NSObject>

-(void)expandedCellWillCollapse;

@end

@protocol savedListViewProtocol <NSObject>

- (void)tappedRecordButton;
- (void) recordingDone;

@end


//@interface SavedListDetailViewController : UIViewController<UIGestureRecognizerDelegate,AVAudioPlayerDelegate,UIActionSheetDelegate,UITextFieldDelegate,SKProductsRequestDelegate,SKPaymentTransactionObserver>

@interface SavedListDetailViewController : UIViewController<UIGestureRecognizerDelegate,AVAudioPlayerDelegate,UIActionSheetDelegate,UITextFieldDelegate>
{
    NSArray *topItems;
    NSArray *currentOutputs;
    NSArray *micArray;
    NSMutableArray *audioPlayerArray;
    NSMutableArray *subItems; // array of arrays
    NSMutableArray *songList;
    NSMutableArray *recordingMergeArray;
    
    CustomActionSheet *menuActionSheet;
    
    NSUserDefaults *userDefaults;
    
    BOOL recordButtonEnabled;
    BOOL increaseChildRowHieght;
    BOOL dragEnabled;
    BOOL didHold;
    BOOL clapFlag1, clapFlag2, clapFlag3, clapFlag4;
    BOOL recFlag1, recFlag2, recFlag3, recFlag4;
    BOOL isChildCheck;
    
    
    int currentIndex;
    int buttonCount;
    int parentSelectedCount;
    int playBtnCount;
    int playFlag, stopFlag;
    int micCounter, endresult;
    float seconds, minutes;
    int VolumeKnobLevelCount;
    int instrV1, instrV2, instrV3, instrV4, tV1, tV2, tV3, tV4;
    int instrP1, instrP2, instrP3, instrP4, tP1, tP2, tP3, tP4;
    int lag1,lag2;
    NSString *duration,*droneName;
    
    
    double peakPowerForChannel;
    
    UIButton *trashButton;
    UIButton *firstKnob;
    UIButton *secondKnob;
    UIButton *thirdKnob;
    UIButton *forthKnob;
    
    CGPoint firstKnobCentre;
    CGPoint secondKnobCentre;
    CGPoint thirdKnobCentre;
    CGPoint forthKnobCentre;
    
    NSIndexPath *previousIndexPath;
    
    UITapGestureRecognizer *tapGestureForAlertview;
    
    UISwipeGestureRecognizer *upRecognizerInst1;
    UISwipeGestureRecognizer *downRecognizerInst1;
    UISwipeGestureRecognizer *upRecognizerInst2;
    UISwipeGestureRecognizer *downRecognizerInst2;
    UISwipeGestureRecognizer *upRecognizerInst3;
    UISwipeGestureRecognizer *downRecognizerInst3;
    UISwipeGestureRecognizer *upRecognizerInst4;
    UISwipeGestureRecognizer *downRecognizerInst4;
    UISwipeGestureRecognizer *upRecognizerRec1;
    UISwipeGestureRecognizer *downRecognizerRec1;
    UISwipeGestureRecognizer *upRecognizerRec2;
    UISwipeGestureRecognizer *downRecognizerRec2;
    UISwipeGestureRecognizer *upRecognizerRec3;
    UISwipeGestureRecognizer *downRecognizerRec3;
    UISwipeGestureRecognizer *upRecognizerRec4;
    UISwipeGestureRecognizer *downRecognizerRec4;
    
    
    UILongPressGestureRecognizer *longPressForKnob1;
    UILongPressGestureRecognizer *longPressForKnob2;
    UILongPressGestureRecognizer *longPressForKnob3;
    UILongPressGestureRecognizer *longPressForKnob4;
    
    NSString *beatOneMusicFile, *beatTwoMusicFile, *rythmName;
    NSString *currentRythmName,*songDuration,*dateOfRecording,*durationStringUnFormatted,*t1Duration,*t2Duration,*t3Duration,*t4Duration;
    NSMutableAttributedString *songDetail;
    
    NSString *currentMusicFileName;
    NSString *newPath, *clap1Path,*clap2Path,*clap3Path,*clap4Path;
    NSString *documentDir;
    
    NSNumber *recordID,*originalBPM;
    
    NSTimeInterval currentTime;
    
    AVAudioPlayer * sound;
    
    DBManager *sqlManager;
    RhythmClass *rhythmRecord;
    float recordingDuration;
    
//    ///In App Purchase
//    SKProductsRequest *productsRequest;
//    NSArray *validProducts;
   

}

@property (weak,nonatomic) id <ExpandedCellDelegate> delegate;
@property (nonatomic, assign) id<savedListViewProtocol> savedDetailDelegate;
@property (strong, nonatomic) MainNavigationViewController *myNavigationController;


// UIOutlets
@property (strong, nonatomic) IBOutlet UITextField *songNameTxtFld;
@property (strong, nonatomic) IBOutlet UILabel *dateLbl;
@property (strong, nonatomic) IBOutlet UILabel *TotalTimeLbl;
@property (strong, nonatomic) IBOutlet UILabel *songDetailLbl;
@property (strong, nonatomic) IBOutlet UILabel *maxRecDurationLbl;
@property (strong, nonatomic) IBOutlet UILabel *minRecDurationLbl;
@property (strong, nonatomic) IBOutlet UILabel *recordingTimeLabel;


@property (weak, nonatomic)   IBOutlet UIView *cell;
@property (strong, nonatomic) IBOutlet UIView *recorderView;
@property (strong, nonatomic) IBOutlet UIView *deleteBGView;
@property (strong, nonatomic) IBOutlet UIView *recordingBGView;


@property (strong, nonatomic) IBOutlet UIImageView *mic1;
@property (strong, nonatomic) IBOutlet UIImageView *mic2;
@property (strong, nonatomic) IBOutlet UIImageView *mic3;
@property (strong, nonatomic) IBOutlet UIImageView *mic4;
@property (strong, nonatomic) IBOutlet UIImageView *mic5;
@property (strong, nonatomic) IBOutlet UIImageView *mic6;
@property (strong, nonatomic) IBOutlet UIImageView *mic7;
@property (strong, nonatomic) IBOutlet UIImageView *mic8;
@property (strong, nonatomic) IBOutlet UIImageView *mic9;
@property (strong, nonatomic) IBOutlet UIImageView *mic10;
@property (strong, nonatomic) IBOutlet UIImageView *volImageInstru1;
@property (strong, nonatomic) IBOutlet UIImageView *volImageInstru2;
@property (strong, nonatomic) IBOutlet UIImageView *volImageInstru3;
@property (strong, nonatomic) IBOutlet UIImageView *volImageInstru4;
@property (strong, nonatomic) IBOutlet UIImageView *volImageT1;
@property (strong, nonatomic) IBOutlet UIImageView *volImageT2;
@property (strong, nonatomic) IBOutlet UIImageView *volImageT3;
@property (strong, nonatomic) IBOutlet UIImageView *volImageT4;
@property (strong, nonatomic) IBOutlet UIImageView *deleteImageT1;
@property (strong, nonatomic) IBOutlet UIImageView *deleteImageT2;
@property (strong, nonatomic) IBOutlet UIImageView *deleteImageT3;
@property (strong, nonatomic) IBOutlet UIImageView *deleteImageT4;


@property (weak, nonatomic)   IBOutlet UIButton *collapseButton;
@property (strong, nonatomic) IBOutlet UIButton *firstVolumeKnob;
@property (strong, nonatomic) IBOutlet UIButton *secondVolumeKnob;
@property (strong, nonatomic) IBOutlet UIButton *thirdVolumeKnob;
@property (strong, nonatomic) IBOutlet UIButton *fourthVolumeKnob;
@property (strong, nonatomic) IBOutlet UIButton *playRecBtn;
@property (strong, nonatomic) IBOutlet UIButton *instrument1;
@property (strong, nonatomic) IBOutlet UIButton *instrument2;
@property (strong, nonatomic) IBOutlet UIButton *instrument3;
@property (strong, nonatomic) IBOutlet UIButton *instrument4;
@property (strong, nonatomic) IBOutlet UIButton *recordingBtn;
@property (strong, nonatomic) IBOutlet UIButton *menuButton;
@property (strong, nonatomic) IBOutlet UIButton *volumeBtn;
@property (strong, nonatomic) IBOutlet UIButton *panBtn;

@property (strong, nonatomic) IBOutlet UISlider *recSlider;


// End UIOutlets

@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (nonatomic) BOOL closeButtonClicked;

@property (strong, nonatomic)  AVAudioSession *session;
@property (strong, nonatomic)  AVAudioSessionPortDescription *input;
@property (strong, nonatomic)  AVAudioSessionPortDescription *output;
@property (strong, nonatomic)  AVAudioSessionPortDescription *myPort;

@property (strong, nonatomic) NSMutableDictionary *musicFileDict;

@property (strong, nonatomic)  MPMusicPlayerController *musicPlayer;
@property (nonatomic, retain)	UIImage					*noArtworkImage;
@property (nonatomic, retain)	UIBarButtonItem			*artworkItem;
@property (nonatomic, retain)	UILabel					*nowPlayingLabel;

@property (strong, nonatomic)  AVAudioPlayer *audioPlayerClap1;
@property (strong, nonatomic)  AVAudioPlayer *audioPlayerClap2;
@property (strong, nonatomic)  AVAudioPlayer *audioPlayerClap3;
@property (strong, nonatomic)  AVAudioPlayer *audioPlayerClap4;

@property (strong, nonatomic)  AVAudioPlayer *recAudioPlayer1;
@property (strong, nonatomic)  AVAudioPlayer *recAudioPlayer2;
@property (strong, nonatomic)  AVAudioPlayer *recAudioPlayer3;
@property (strong, nonatomic)  AVAudioPlayer *recAudioPlayer4;

@property (strong, nonatomic)  AVAudioRecorder *recorder;

@property (strong, nonatomic)  MPVolumeView *volumeView;

@property (strong, nonatomic) NSString *droneType;
@property (strong, nonatomic) NSString *recTrackOne,*recTrackTwo,*recTrackThree,*recTrackFour;
@property (strong, nonatomic) NSString *selctRow;
@property (strong, nonatomic) NSString *recordTimerText;

@property (strong, nonatomic) NSNumber *startBPM;

@property (strong, nonatomic)  NSTimer *recordTimer,*recordPlayingTimer;
@property (strong, nonatomic)  NSTimer *updateSliderTimer;
@property (strong, nonatomic) NSTimer *playTimer,*clap3Timer;;

@property (nonatomic, retain)     NSString *shareCheckString;

@property (weak, nonatomic) IBOutlet UIImageView *cellTopSeprator;
@property(nonatomic ,strong)RecordingListData *recordingData;

- (void)setDataForUIElements:(int)_index RecordingData :(RecordingListData *)data;

- (void)timeStretchRhythmsAndSave:(NSString *)firstInstr
                  withSecondInstr:(NSString *)secondInstr
                        withTempo:(float)tempo;
- (void)trimAudioFileInputFilePath:(NSString *)inputPath
                  toOutputFilePath:(NSString *)outputPath;

- (NSString *)mixAudioFiles:(NSMutableArray*)audioFileURLArray
          withTotalDuration:(float)totalAudioDuration
        withRecordingString:(NSString *)recordingString
                   andTempo:(float)tempo;

- (void)setRowIndex:(int)rowIndex;

//- (void)updateRecordingDb;

//////In App purchase
//- (void)fetchAvailableProducts;
//- (BOOL)canMakePurchases;
//- (void)purchaseMyProduct:(SKProduct*)product;


@end
