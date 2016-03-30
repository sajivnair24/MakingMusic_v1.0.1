//
//  MainNavigationViewController.m
//  FlamencoRhythm
//
//  Created by Mayank Mathur on 04/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import "MainNavigationViewController.h"
#import "RecordViewController.h"
#import "SavedListViewController.h"
#import "FrequencyViewController.h"
#import "RecordViewController.h"
#import "AppDelegate.h"
#import "Reachability.h"
#import "PureLayout.h"
#import <sys/sysctl.h>
#import "Constants.h"

@interface MainNavigationViewController ()<RecordViewProtocol,savedListViewProtocol> {
    UIScrollView *pageScrollView;
    NSInteger currentPageIndex;
    SavedListViewController *thirdVC;
    RecordViewController *secondVC;
    SavedListDetailViewController *savedDetailVC;
    int volumeSliderValue;
    MPVolumeView* volumeView;
    int flagVolume;
}

@end

@implementation MainNavigationViewController

//@synthesize viewControllerArray;
//@synthesize selectionBar;
//@synthesize panGestureRecognizer;
@synthesize pageController;
//@synthesize navigationView;
//@synthesize buttonText;

- (void)viewDidLoad {
    [super viewDidLoad];
    flagVolume = 0;
    _musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    //    [notificationCenter addObserver:self
    //                           selector:@selector(handleVolumeChanged:)
    //                               name:MPMusicPlayerControllerVolumeDidChangeNotification
    //                             object:_musicPlayer];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleVolumeChanged:)
                               name:@"AVSystemController_SystemVolumeDidChangeNotification"
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(enablePaging:)
                               name:@"enablePagingNotification"
                             object:nil];
    
    //[self registerForMediaPlayerNotifications];
    [_musicPlayer beginGeneratingPlaybackNotifications];
    
    self.pageController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
    self.pageController.dataSource = self;
    
    //    ViewController *firstVC = [self.storyboard instantiateViewControllerWithIdentifier:@"firstVC"];
    secondVC= [self.storyboard instantiateViewControllerWithIdentifier:@"secondVC"];
    thirdVC = [self.storyboard instantiateViewControllerWithIdentifier:@"thirdVCold"];
    
    savedDetailVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Expander"];
    
    //    firstVC.myNavigationController = self;
    secondVC.myNavigationController = self;
    thirdVC.myNavigationController = self;
    savedDetailVC.myNavigationController = self;
    thirdVC.selctRow = @"no";
    
    savedDetailVC.savedDetailDelegate = self;
    secondVC.recordDelegate = self;
    
    //    viewControllerArray = @[firstVC,secondVC,thirdVC];
    viewControllerArray = @[thirdVC,secondVC,savedDetailVC];
    
    //    ProductDetailViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[thirdVC];
    //NSArray *viewControllers = @[secondVC];
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    // Change the size of page view controller
    self.pageController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 50);
    
    [self.view addSubview:pageController.view];
    [self addChildViewController:pageController];
    [self.pageController didMoveToParentViewController:self];
    
    [self setUpVolumeSlide];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(isRecordingStart:)
                                                 name:@"tappedRecordButton" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(isRecordingDone:)
                                                 name:@"recordingDone" object:nil];
    // volume view to control device volume
    volumeView = [[MPVolumeView alloc] init];
    self.pageController.dataSource = nil;
    [self addFooterBackGround];
}
-(void)addFooterBackGround{
    [_tunerBlackImage setImage:[UIImage imageNamed:@"magnet"]];
    _footerFadedBackground = [[UIView alloc]initWithFrame:CGRectMake(0,457, self.view.frame.size.width,  150)];
    _footerFadedBackground.backgroundColor = [UIColor blackColor];
    _footerFadedBackground.alpha = 0.0;
    [self.view addSubview:_footerFadedBackground];

}
- (void)isRecordingStart:(NSNotification *)note {
    [self tappedRecordButton];
    //NSLog(@"Received Notification - Someone seems to have logged in");
}
- (void)isRecordingDone:(NSNotification *)note {
    [self recordingDone];
    //NSLog(@"Received Notification - Someone seems to have logged in");
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)callChromo{
    AVAudioPlayer *testPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@", [[NSBundle mainBundle] pathForResource:@"Sync 1" ofType:@"m4a"]]] error:nil];
    [testPlayer play];
}

/*-(UIStatusBarStyle)preferredStatusBarStyle{
    //NSLog(@"cur %ld",(long)currentPageIndex);
    if (currentPageIndex == 0) {
        return UIStatusBarStyleDefault;
    }else
        return UIStatusBarStyleLightContent;
}*/

//This stuff here is customizeable: buttons, views, etc
////////////////////////////////////////////////////////////
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%//
//%%%%%%%%%%%%%%%%%    CUSTOMIZEABLE    %%%%%%%%%%%%%%%%%%//
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%//
//

//%%% color of the status bar
//- (UIStatusBarStyle)preferredStatusBarStyle{
//    return UIStatusBarStyleLightContent;
//
//     //   return UIStatusBarStyleDefault;
//}

-(void)viewToPresent:(int)_index withDictionary:(NSDictionary*)_dict{
    
    NSArray *viewControllers = @[[viewControllerArray objectAtIndex:_index]];
    // For third View Controller
    if (_index == 1) {
        thirdVC.selctRow = @"yes";
    }
    
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
}

-(void)goBackToSoundListing{
     NSArray *viewControllers = @[[viewControllerArray objectAtIndex:0]];
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:nil];
}
-(void)openRecordingView{
    NSArray *viewControllers = @[[viewControllerArray objectAtIndex:1]];
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
}
-(void)openDetailRecordingView:(RecordingListData *)recordingData{
    savedDetailVC.recordingData = recordingData ;
   // [savedDetailVC setDataForUIElements:0 RecordingData:recordingData];
    NSArray *viewControllers = @[[viewControllerArray objectAtIndex:2]];
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
   // [self viewToPresent:2 withDictionary:nil];
    
}
-(void)updateCurrentPageIndex:(int)newIndex
{
    currentPageIndex = newIndex;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Record View delegate methods

-(void)tappedRecordButton{
    [self.tunerBtn setUserInteractionEnabled:NO];
    [self.tunerBlackImage setHidden:NO];
}

- (void) recordingDone{
    [self.tunerBtn setUserInteractionEnabled:YES];
    [self.tunerBlackImage setHidden:YES];
}
#pragma mark - slider Setup & Action
- (void)setUpVolumeSlide {
//    _volumeSlider.value = 5;
    float vol = [[AVAudioSession sharedInstance] outputVolume];
    [_volumeSlider setValue:vol*10];

    [_volumeSlider setMinimumTrackTintColor:[UIColor grayColor]];
    [_volumeSlider setMaximumTrackTintColor:[UIColor lightGrayColor]];
    
    //[_volumeSlider setMaximumTrackTintColor:[UIColor blackColor]];
   // [_volumeSlider setMaximumTrackImage:[UIImage imageNamed:@"slidertrackLatestBlack.png"] forState:UIControlStateNormal];
    //[_volumeSlider setMinimumTrackImage:[UIImage imageNamed:@"sliderprogressLatest.png"] forState:UIControlStateNormal];
    [_volumeSlider setThumbImage:[UIImage imageNamed:@"sliderThumb.png"] forState:UIControlStateNormal];
}
- (IBAction)OnChangeVolumeSlider:(id)sender{
    
    //find the volumeSlider
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    [volumeViewSlider setValue:[_volumeSlider value]/10.0 animated:NO];
    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    //    [_volumeSlider setValue:_musicPlayer.volume * 10];
    [self.delegate volumeChanged:[_volumeSlider value]/10.0];
    //    _musicPlayer.volume = _volumeSlider.value/10.0f;
}

- (void)handleVolumeChanged:(id)notification {
    
    if(flagVolume != 0){
    float volume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"]
                    floatValue];
    //    //NSLog(@"the volume change action: %f",volume);
          [self.delegate volumeChanged:volume];
    [_volumeSlider setValue:volume*10];
  
    //    [_volumeSlider setValue:_musicPlayer.volume * 10];
        if(flagVolume == 1){
            flagVolume = 2;
        }


    }
    else if(flagVolume == 0){
        flagVolume = 1;
    }
    
    
}

- (IBAction)onTapChromaticTuner:(id)sender {
    FrequencyViewController *productDetailsView =[self.storyboard instantiateViewControllerWithIdentifier:@"frequencyVC"];
    [self presentViewController:productDetailsView animated:YES completion:nil];
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfController:viewController];;
    
    if ((index == 0) || (index == NSNotFound)) {
        currentPageIndex = index;
        return nil;
    }
    index--;
    
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfController:viewController];;
    
    if (index == NSNotFound) {
        currentPageIndex = index;
        return nil;
    }
    
    index++;
    if (index == 2) {
        currentPageIndex = index;
        return nil;
    }
    if (index == 1) {
        currentPageIndex = index;
        secondVC.bpmDefaultFlag = 1;
    }
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index
{
    if ((index == -1) || (index >= 2)) {
        return nil;
    }
    currentPageIndex = index;
    return [viewControllerArray objectAtIndex:index];;
}

-(NSInteger)indexOfController:(UIViewController *)viewController
{
    for (int i = 0; i<[viewControllerArray count]; i++) {
        if (viewController == [viewControllerArray objectAtIndex:i])
        {
            return i;
        }
    }
    return NSNotFound;
}

- (void) enablePaging:(NSNotification *)notification {
    NSString *enablePaging = [notification object];
    if([enablePaging isEqualToString:@"NO"]) {
        pageController.dataSource = nil;
    } else {
       // pageController.dataSource = self;
    }
}

+ (NSString *)platformType:(NSString *)platform
{
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5c (GSM)";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5c (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5s (GSM)";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5s (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    return platform;
}

+ (BOOL)isIPhoneOlderThanVersion6 {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char*)malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    
    NSString *deviceType = [self platformType:platform];
    if ([deviceType isEqualToString:@"iPhone 5c (GSM)"]      ||
        [deviceType isEqualToString:@"iPhone 5c (GSM+CDMA)"] ||
        [deviceType isEqualToString:@"iPhone 5s (GSM)"]      ||
        [deviceType isEqualToString:@"iPhone 5s (GSM+CDMA)"] ||
        [deviceType isEqualToString:@"iPhone 5s (GSM)"]      ||
        [deviceType isEqualToString:@"iPhone 5 (GSM)"]       ||
        [deviceType isEqualToString:@"iPhone 5 (GSM+CDMA)"]) {
        free(machine);
        return YES;
    }
    
    free(machine);
    return NO;
}

+ (BOOL) checkNetworkStatus {
    // check if we've got network connectivity
    BOOL isConnected = NO;
    Reachability *myNetwork = [Reachability reachabilityWithHostname:@"google.com"];
    NetworkStatus myStatus = [myNetwork currentReachabilityStatus];
    
    switch (myStatus) {
        case NotReachable:
          {
            UIAlertView *networkAlert = [[UIAlertView alloc]
                                         initWithTitle:@"No Internet Access"
                                         message:@"Your phone is not connected to internet"
                                         delegate:self
                                         cancelButtonTitle:nil
                                         otherButtonTitles:@"Ok", nil];
            [networkAlert show];
            
            NSLog(@"There's no internet connection at all. Display error message now.");
          }
            break;
            
        case ReachableViaWWAN:
            NSLog(@"We have a 3G connection");
            isConnected = YES;
            break;
            
        case ReachableViaWiFi:
            NSLog(@"We have WiFi.");
            isConnected = YES;
            break;
            
        default:
            break;
    }
    return isConnected;
}

+ (void)setPurchaseInfo:(NSString *)status {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:status forKey:@"inAppPurchase"];
}

+ (BOOL)inAppPurchaseEnabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *purshaseStatus = [defaults objectForKey:@"inAppPurchase"];
    
//#if !IN_APP_PURCHASE_ENABLE
//    return YES;
//#endif
    
    if([purshaseStatus isEqualToString:@"not purchased"] || purshaseStatus == nil) {
        return NO;
    } else {
        return YES;
    }
}

+ (void)trimClickFile:(int)currentBpm {
    
    // Path of your source audio file
    NSURL *audioFileInput = [NSURL fileURLWithPath:[self getAbsoluteBundlePath:@"Click AccentedNew.wav"]];
    NSURL *audioFileOutput = [NSURL fileURLWithPath:[self getAbsoluteDocumentsPath:@"Click.m4a"]];
    
    [[NSFileManager defaultManager] removeItemAtURL:audioFileOutput error:NULL];
    AVAsset *asset = [AVAsset assetWithURL:audioFileInput];
    
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    
    float startTrimTime = 0.0;
    float tempoRatio = currentBpm/60.0f;
    float endTrimTime = 1.0f/tempoRatio;
    
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
             //NSLog(@"Succccceeeee\n");
         }
         else if (AVAssetExportSessionStatusFailed == exportSession.status)
         {
             // NSLog(@"failed");
         }
     }];
}

+ (NSString *)getAbsoluteBundlePath:(NSString *)fileName {
    return [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], fileName];
}

+ (NSString *)getAbsoluteDocumentsPath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName];
}

@end