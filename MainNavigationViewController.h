//
//  MainNavigationViewController.h
//  FlamencoRhythm
//
//  Created by Mayank Mathur on 04/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <MediaPlayer/MPVolumeView.h>
#include <MediaPlayer/MPMusicPlayerController.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SavedListDetailViewController.h"


@class AppDelegate;

@protocol MainNavigationViewControllerDelegate <NSObject>
@optional
- (void)volumeChanged:(CGFloat)value;
- (void)tappedChromaticButton;
@end

@interface MainNavigationViewController : UIViewController <UIPageViewControllerDelegate,UIPageViewControllerDataSource,UIScrollViewDelegate>{
    NSArray *viewControllerArray;
    
    AppDelegate *appDelegate;
    
   
    
}
@property (strong, nonatomic) IBOutlet UIView *footerFadedBackground; /***Nirma***/
@property (strong, nonatomic) IBOutlet UIImageView *footerImageView;

//@property (nonatomic, strong) NSMutableArray *viewControllerArray;
@property (nonatomic, weak) id<MainNavigationViewControllerDelegate> navDelegate;
//@property (nonatomic, strong) UIView *selectionBar;
//@property (nonatomic, strong)UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong)UIPageViewController *pageController;
//@property (nonatomic, strong)UIView *navigationView;
//@property (nonatomic, strong)NSArray *buttonText;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UISlider *volumeSlider;
@property (strong, nonatomic)  MPMusicPlayerController *musicPlayer;
@property (strong, nonatomic) IBOutlet UIButton *tunerBtn;
@property (strong, nonatomic) IBOutlet UIImageView *tunerBlackImage;

@property (nonatomic, assign) id<MainNavigationViewControllerDelegate> delegate;

-(void)viewToPresent:(int)_index withDictionary:(NSDictionary*)_dict;
- (IBAction)OnChangeVolumeSlider:(id)sender;
- (IBAction)onTapChromaticTuner:(id)sender;
+ (BOOL)isIPhoneOlderThanVersion6;
+ (BOOL)checkNetworkStatus;
+ (void)setPurchaseInfo:(NSString *)status;
+ (BOOL)inAppPurchaseEnabled;
+ (void)trimClickFile:(int)currentBpm;
+ (NSString *)getAbsoluteBundlePath:(NSString *)fileName;
+ (NSString *)getAbsoluteDocumentsPath:(NSString *)fileName;

//navigation funcations
-(void)openRecordingView;
-(void)goBackToSoundListing;
-(void)openDetailRecordingView:(RecordingListData *)recordingData;
@end
