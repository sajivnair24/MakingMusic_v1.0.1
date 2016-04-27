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

@synthesize pageController;

- (void)viewDidLoad {
    [super viewDidLoad];
    flagVolume = 0;
    _musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleVolumeChanged:)
                               name:@"AVSystemController_SystemVolumeDidChangeNotification"
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(enablePaging:)
                               name:@"enablePagingNotification"
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(audioRouteChangeListenerCallback:)
                               name:AVAudioSessionRouteChangeNotification
                             object:nil];
    
    //[self registerForMediaPlayerNotifications];
    [_musicPlayer beginGeneratingPlaybackNotifications];
    headphonePlugged = [self areHeadphonesPluggedIn];
    
    self.pageController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
    self.pageController.dataSource = self;
    
    //    ViewController *firstVC = [self.storyboard instantiateViewControllerWithIdentifier:@"firstVC"];
    secondVC= [self.storyboard instantiateViewControllerWithIdentifier:@"secondVC"];
    thirdVC = [self.storyboard instantiateViewControllerWithIdentifier:@"thirdVCold"];
    
    [self setSecondDetailVC];
    
    
    //    firstVC.myNavigationController = self;
    secondVC.myNavigationController = self;
    thirdVC.myNavigationController = self;
    savedDetailVC.myNavigationController = self;
    thirdVC.selctRow = @"no";
    
    savedDetailVC.savedDetailDelegate = self;
    secondVC.recordDelegate = self;
    
    viewControllerArray = @[thirdVC,secondVC,savedDetailVC];
    
    NSArray *viewControllers = @[thirdVC];
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    // Change the size of page view controller
    self.pageController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 50);
    
    [self addNavigationController];
    [self addFooterSeprator];
    [self setUpVolumeSlide];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(isRecordingStart:)
                                                 name:@"tappedRecordButton" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(isRecordingDone:)
                                                 name:@"recordingDone" object:nil];
    [self setUpMPVolumeView];
    self.pageController.dataSource = nil;
    [self addFooterBackGround];
}
-(void)setSecondDetailVC{
    
    if (IS_IPHONE_4s) {
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"4sStoryboard" bundle:[NSBundle mainBundle]];
        
        savedDetailVC = [sb instantiateViewControllerWithIdentifier:@"Expander4s"];
    }
    else{
        savedDetailVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Expander"];
    }
     savedDetailVC.myNavigationController = self;
}
-(void)setUpMPVolumeView {
    volumeView = [[MPVolumeView alloc] initWithFrame: CGRectMake(-100,-100,16,16)];
    volumeView.showsRouteButton = NO;
    volumeView.userInteractionEnabled = NO;
    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] addSubview:volumeView];
}

-(void)addFooterSeprator{
    UIView *seprator = [[UIView alloc]init];
    [_footerImageView addSubview:seprator];
    seprator.backgroundColor = UIColorFromRGB(GRAY_COLOR);
    [seprator autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [seprator autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [seprator autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0.5];
    [seprator autoSetDimension:ALDimensionHeight toSize:0.5];
    
}

-(void)addNavigationController{
    navigationController = [[UINavigationController alloc]initWithRootViewController:thirdVC];
    [self.view addSubview:navigationController.view];
    [self addChildViewController:navigationController];
    navigationController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 50);
    navigationController.navigationBarHidden = YES;
    [navigationController.interactivePopGestureRecognizer setDelegate:self];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if ([navigationController.viewControllers count]>1) {
        return YES;
    }
    return NO;
}

-(void)addFooterBackGround{
    [_tunerBlackImage setImage:[UIImage imageNamed:@"tuner_blue"]];
    [_tunerBlackImage setHidden:NO];
    
    int posY = 457;
    if (IS_IPHONE_4s) {
        posY = 430;
    }
    _footerFadedBackground = [[UIView alloc]initWithFrame:CGRectMake(0,posY, self.view.frame.size.width,  150)];
    _footerFadedBackground.backgroundColor = [UIColor blackColor];
    _footerFadedBackground.alpha = 0.0;
    [self.view addSubview:_footerFadedBackground];
}

- (void)isRecordingStart:(NSNotification *)note {
    [self tappedRecordButton];
}

- (void)isRecordingDone:(NSNotification *)note {
    [self recordingDone];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)callChromo{
    AVAudioPlayer *testPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@", [[NSBundle mainBundle] pathForResource:@"Sync 1" ofType:@"m4a"]]] error:nil];
    [testPlayer play];
}

-(void)viewToPresent:(int)_index withDictionary:(NSDictionary*)_dict{
    
    NSArray *viewControllers = @[[viewControllerArray objectAtIndex:_index]];
    // For third View Controller
    if (_index == 1) {
        thirdVC.selctRow = @"yes";
    }
    
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
}

-(void)goBackToSoundListing{
    [navigationController popViewControllerAnimated:YES];
}

-(void)openRecordingView{
    secondVC= [self.storyboard instantiateViewControllerWithIdentifier:@"secondVC"];
    secondVC.myNavigationController = self;
    [navigationController pushViewController:secondVC animated:YES];
}

-(void)openDetailRecordingView:(RecordingListData *)recordingData {
    [self setSecondDetailVC];
   
    savedDetailVC.recordingData = recordingData ;
    [navigationController pushViewController:savedDetailVC animated:YES];
}

-(void)updateCurrentPageIndex:(int)newIndex {
    currentPageIndex = newIndex;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Record View delegate methods

-(void)tappedRecordButton {
    [self.tunerBtn setUserInteractionEnabled:NO];
    [_tunerBlackImage setImage:[UIImage imageNamed:@"tuner_grey"]];
}

- (void) recordingDone {
    [self.tunerBtn setUserInteractionEnabled:YES];
    [_tunerBlackImage setImage:[UIImage imageNamed:@"tuner_blue"]];
}

#pragma mark - slider Setup & Action
- (void)setUpVolumeSlide {
    float vol = [[AVAudioSession sharedInstance] outputVolume];
    [_volumeSlider setValue:vol*10];

    [_volumeSlider setMinimumTrackTintColor:[UIColor grayColor]];
    [_volumeSlider setMaximumTrackTintColor:[UIColor lightGrayColor]];
    
    [_volumeSlider setThumbImage:[UIImage imageNamed:@"sliderThumb.png"] forState:UIControlStateNormal];
}

- (IBAction)OnChangeVolumeSlider:(id)sender{
    
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    [volumeViewSlider setValue:[_volumeSlider value]/10.0 animated:NO];
    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    [self.delegate volumeChanged:[_volumeSlider value]/10.0];
}

- (void)handleVolumeChanged:(id)notification {
    
    if(flagVolume != 0){
    float volume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"]
                    floatValue];
          [self.delegate volumeChanged:volume];
    [_volumeSlider setValue:volume*10];
  
        if(flagVolume == 1){
            flagVolume = 2;
        }
    }
    else if(flagVolume == 0){
        flagVolume = 1;
    }
}

- (IBAction)onTapChromaticTuner:(id)sender {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"stopAudioPlayerNotification"
                                                        object:nil];
    
    FrequencyViewController *productDetailsView =[self.storyboard instantiateViewControllerWithIdentifier:@"frequencyVC"];
    productDetailsView.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:productDetailsView animated:YES completion:nil];
}

- (BOOL)areHeadphonesPluggedIn {
    NSArray *availableOutputs = [[AVAudioSession sharedInstance] currentRoute].outputs;
    for (AVAudioSessionPortDescription *portDescription in availableOutputs) {
        if ([portDescription.portType isEqualToString:AVAudioSessionPortHeadphones]) {
            return YES;
        }
    }
    return NO;
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

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"Headphone/Line plugged in");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HIDEMICSWITCH"
                                                                object:@"NO"];
            headphonePlugged = YES;
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"Headphone/Line was pulled. Stopping player....");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"HIDEMICSWITCH"
                                                                object:@"YES"];
            headphonePlugged = NO;
            break;
    }
}

+ (BOOL)isHeadphonePlugged {
    return headphonePlugged;
}

+ (void)setSelectedInputMic:(int)inputMic {
    selectedInputMic = inputMic;
}

+ (int)getSelectedInputMic {
    return selectedInputMic;
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
    NSURL *audioFileInput = [NSURL fileURLWithPath:[self getAbsBundlePath:@"Click AccentedNew.wav"]];
    NSURL *audioFileOutput = [NSURL fileURLWithPath:[self getAbsDocumentsPath:@"Click.m4a"]];
    
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

+ (NSString *)getAbsBundlePath:(NSString *)fileName {
    return [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], fileName];
}

+ (NSString *)getAbsDocumentsPath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName];
}

@end