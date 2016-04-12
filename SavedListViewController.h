//
//  SavedListViewController.h
//  FlamencoRhythm
//
//  Created by Mayank Mathur on 04/03/15.
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
#import <iAd/iAd.h>
#import "GADBannerView.h"
#import "SavedListDetailViewController.h"
#import "SoundPlayManger.h"
#define IS_IPHONE_4s ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )480 ) < DBL_EPSILON )
@class MainNavigationViewController;

@interface SavedListViewController : UIViewController <UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate,AVAudioPlayerDelegate,ADBannerViewDelegate,GADBannerViewDelegate,ExpandedCellDelegate,SoundManagerDelegate>
{
     // array of arrays
    NSMutableArray *songList;
   
    NSString *currentRythmName,*songDuration,*dateOfRecording,*durationStringUnFormatted;
    NSMutableAttributedString *songDetail;
   
    BOOL bannerStatus;
    DBManager *sqlManager;
    
    /********Nirma********/
    SoundPlayManger *soundPlayer;
    ADBannerView *iAdBannerView;
    UILabel *tableBackGroundView;
    NSLayoutConstraint *iAdBannerViewHeightConstraint;
    /********Nirma********/
    
}
@property (strong, nonatomic) UITableView *recordingTableView;
@property (strong, nonatomic) IBOutlet UITableView *songTableView;

@property (strong, nonatomic) NSString *selctRow;

@property (strong, nonatomic) MainNavigationViewController *myNavigationController;
@property (nonatomic, strong) UIPopoverController *activityPopoverController;

@property (weak, nonatomic) IBOutlet ADBannerView *bannerView;
@property (nonatomic, strong) GADBannerView *admobBannerView;

//- (IBAction)shareBtnAction:(id)sender;
//- (IBAction)OnChangeVolumeSlider:(id)sender;



@end
