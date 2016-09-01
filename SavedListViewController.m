
//
//  SavedListViewController.m
//  FlamencoRhythm
//
//  Created by Mayank Mathur on 04/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import "SavedListViewController.h"
#import "MainNavigationViewController.h"
#import "protypeTableCell.h"
#import "RecordingListData.h"
#import "AppDelegate.h"
#import "RhythmClass.h"
#import "SessionCell.h"
#import "Constants.h"
#import "PureLayout.h"


#define NUM_TOP_ITEMS 20
#define NUM_SUBITEMS 6


@interface SavedListViewController () <MainNavigationViewControllerDelegate>
{
  RhythmClass *rhythmRecord;
}

@property (strong,nonatomic) SavedListDetailViewController *expander;
@property (nonatomic) CGRect chosenCellFrame;

@end
@implementation SavedListViewController
@synthesize recordingTableView;
static NSString *cellIdentifier = @"CELL";
- (id)init {
    self = [super init];
    
    if (self) {
        
    }
    return self;
}

#pragma mark - View management

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //    songList = [[NSMutableArray alloc] initWithObjects:@"Tangos (100 BPM A#)",@"My Second Song",@"My Third Song",@"My Forth Song",@"Thriller Remix",@"MC Hammer"@"Save The World",@"Get Down",@"Get Up",@"Good Morning", nil];
    
//    if(songList != nil)
//        [_expander updateRecordingDb];
    
    songList = [[NSMutableArray alloc] init];
    songList = [sqlManager getAllRecordingData];
   
    //[self removeAdBannerView];   //sn
    [self refreshTableView];
    [self setTableBackGroundView];
   /* [_songTableView reloadData];
   
        if ([_selctRow isEqualToString:@"yes"]) {
            _selctRow = @"no";
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//            [self.songTableView selectRowAtIndexPath:indexPath
//                                            animated:YES
//                                      scrollPosition:UITableViewScrollPositionNone];
            
                [self tableView:self.songTableView didSelectRowAtIndexPath:indexPath];
            
            
        }
    [self setNeedsStatusBarAppearanceUpdate];
   
    if ([self.expander.shareCheckString isEqualToString:@"comeback"]) {
        [self addChildViewController:self.expander];
        self.expander.view.frame = self.view.bounds;
        self.expander.collapseButton.alpha = 1;
        [self.view addSubview:self.expander.view];
        [self.expander didMoveToParentViewController:self];
        
    }
    
    [self removeAdBannerView];*/
    // [self.view bringSubviewToFront:_bannerView];
    //_bannerView.frame = CGRectMake(_bannerView.frame.origin.x, self.view.frame.size.height-_bannerView.frame.size.height-50, _bannerView.frame.size.width, _bannerView.frame.size.height);
    
    //[self.view bringSubviewToFront:iAdBannerView];  //sn
}

-(void)addRecordingTableView{
    soundPlayer = [[SoundPlayManger alloc]init];
    soundPlayer.delegate = self;
    recordingTableView = [[UITableView alloc]init];
    UIView *headerView = [self getHeaderView];
    
    [self.view addSubview:headerView];
    [headerView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [headerView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [headerView autoSetDimension:ALDimensionHeight toSize:95];
    [headerView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.view addSubview:recordingTableView];
    
    UIView *sepratorLine = [[UIView alloc]init];
    [self.view addSubview:sepratorLine];
    sepratorLine.backgroundColor = UIColorFromRGB(GRAY_COLOR);
    [sepratorLine autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [sepratorLine autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [sepratorLine autoSetDimension:ALDimensionHeight toSize:0.5];
    [sepratorLine autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:headerView withOffset:0];
    
    [self.recordingTableView registerClass:[SessionCell class] forCellReuseIdentifier:cellIdentifier];
    [recordingTableView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [recordingTableView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [recordingTableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:sepratorLine withOffset:0];
    //[recordingTableView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:iAdBannerView];
    [recordingTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    recordingTableView.delegate = self;
    recordingTableView.dataSource = self;
    recordingTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    recordingTableView.rowHeight = 60;
    [recordingTableView reloadData];
   // [recordingTableView setEditing:YES];
}

-(void)soundStopped {
    for (int i = 0; i<[songList count]; i++) {
        RecordingListData *cellData = [songList objectAtIndex:i];
        cellData.isSoundPlaying = NO;
    }
    [self refreshTableView];
}

-(UIView*)getHeaderView{
    UIView *backgroundView = [[UIView alloc]init];
    UIButton *btn = [[UIButton alloc]init];
    btn.backgroundColor = UIColorFromRGB(NAVIGATION_COLOR);
    [btn setTitle:@"New Session" forState:UIControlStateNormal];
    [backgroundView addSubview:btn];
    [btn autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [btn autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [btn autoSetDimension:ALDimensionHeight toSize:75];
    [btn autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20];
    [btn.titleLabel setFont:[UIFont fontWithName:FONT_LIGHT size:40]];
    [btn setTitleColor:UIColorFromRGB(FONT_BLUE_COLOR) forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(openNewSession:) forControlEvents:UIControlEventTouchUpInside];
    backgroundView.backgroundColor = UIColorFromRGB(NAVIGATION_COLOR);
    return backgroundView;
}

//-(void)addIAdBannerView{    //sn
//    iAdBannerView = [[ADBannerView alloc]init];
//    [self.view addSubview:iAdBannerView];
//    [iAdBannerView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//    [iAdBannerView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//    iAdBannerViewHeightConstraint = [iAdBannerView autoSetDimension:ALDimensionHeight toSize:50];
//    [iAdBannerView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//    //iAdBannerView.backgroundColor = [UIColor blackColor];
//}

-(void)openNewSession:(id)sender{
    [soundPlayer stopAllSound];
    [self.myNavigationController openRecordingView];
    //[self.myNavigationController viewToPresent:1 withDictionary:@[]];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    sqlManager = [[DBManager alloc] init];
    //[self removeAdBannerView];   //sn
    //[self addIAdBannerView];     //sn
    [self addRecordingTableView];
    [self printAllFonts];
    [self addTableBackGroundView];
    //[_bannerView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:50];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopAudioPlayer:)
                                                 name:@"stopAudioPlayerNotification"
                                               object:nil];
   
}

-(void)addTableBackGroundView{
    tableBackGroundView = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,40)];
    tableBackGroundView.text = @"Tap New Session to start";
    tableBackGroundView.textAlignment = NSTextAlignmentCenter;
    [tableBackGroundView setFont:[UIFont fontWithName:FONT_REGULAR size:16]];
    tableBackGroundView.textColor = [UIColor grayColor];
}

-(void)printAllFonts {
    for (NSString *familyName in [UIFont familyNames]){
        //NSLog(@"Family name: %@", familyName);
        for (NSString *fontName in [UIFont fontNamesForFamilyName:familyName]) {
            //NSLog(@"--Font name: %@", fontName);
        }
    }
}

-(void)setDataToUIElements:(int)_index {
    
    RecordingListData *cellData = [[RecordingListData alloc] init];
    rhythmRecord = [[RhythmClass alloc] init];
    
    cellData = [songList objectAtIndex:_index];
    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
    dataArray = [sqlManager fetchRhythmRecordsByID:[NSNumber numberWithInt:[cellData.rhythmID intValue]]];
    rhythmRecord = [dataArray objectAtIndex:0];
    
    currentRythmName = cellData.recordingName;
    songDuration = [NSString stringWithFormat:@"%@",[self timeFormatted:[cellData.durationString floatValue]]];
    dateOfRecording = cellData.dateString;
        
    //songDetail = [NSString stringWithFormat:@"%@ %@ bpm %@",rhythmRecord.rhythmName,cellData.BPM,cellData.droneType];
}

- (NSString *)timeFormatted:(int)totalSeconds
{
    
    int second = totalSeconds % 60;
    int minute = (totalSeconds / 60) % 60;
    //int hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02d:%02d",minute, second];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    return [songList count] + ((currentExpandedIndex > -1) ? [[subItems objectAtIndex:currentExpandedIndex] count] : 0);
    return [songList count];
    //return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
   SessionCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[SessionCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        //[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
    }
    RecordingListData *cellData = [[RecordingListData alloc] init];
    rhythmRecord = [[RhythmClass alloc] init];
    
    cellData = [songList objectAtIndex:indexPath.row];
    if (cellData.rhythmRecord == nil) {
        NSMutableArray *dataArray = [[NSMutableArray alloc] init];
        dataArray = [sqlManager fetchRhythmRecordsByID:[NSNumber numberWithInt:[cellData.rhythmID intValue]]];
        cellData.rhythmRecord = [dataArray objectAtIndex:0];
        

    }
    rhythmRecord = cellData.rhythmRecord;
    currentRythmName = cellData.recordingName;
    songDuration = [NSString stringWithFormat:@"%@",[self timeFormatted:[cellData.durationString floatValue]]];
    dateOfRecording = cellData.dateString;
    
    NSAttributedString *drone = [[NSAttributedString alloc] initWithString:cellData.droneType];
    
    NSString *audioInfo = [NSString stringWithFormat:@"%@ %@ bpm ", rhythmRecord.rhythmName, [cellData.BPM stringValue]];
    
    songDetail = [[NSMutableAttributedString alloc] initWithString:audioInfo];

    if([cellData.droneType length] > 1) {
        UIFont *font = [UIFont fontWithName:FONT_LIGHT size:10];;//[UIFont fontWithName:@"HelveticaNeue" size:10];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:cellData.droneType
                                                                                             attributes:@{NSFontAttributeName: font}];
        [attributedString setAttributes:@{NSFontAttributeName:[UIFont fontWithName:HELVETICA_REGULAR size:8]
                                          , NSBaselineOffsetAttributeName:@5} range:NSMakeRange(1, 1)];
        
        [songDetail appendAttributedString:attributedString];
    } else {
        [songDetail appendAttributedString:drone];
    }

    cell.songNameLbl.text = currentRythmName;
    [cell.TotalTimeLbl setText:songDuration];
    cell.dateLbl.text = dateOfRecording;
    cell.songDetailLbl.attributedText = songDetail;
    
    [self setPlayButtonImage:cell.playButton State:cellData];
    [cell.playButton addTarget:self action:@selector(playSound:) forControlEvents:UIControlEventTouchUpInside];
    [cell.sessionSelectButton addTarget:self action:@selector(openRecordingDeatils:) forControlEvents:UIControlEventTouchUpInside];
    cell.playButton.tag = indexPath.row;
    cell.sessionSelectButton.tag = indexPath.row;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

-(void)setPlayButtonImage:(UIButton *)playButton State:( RecordingListData *)cellData{
    NSString *imageName = @"play.png";
    if (cellData.isSoundPlaying) {
        imageName = @"pause.png";
    }
    [playButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

-(void)playSound:(id)sender{
    //NSLog(@"play Sound");
    UIButton *playButton = (UIButton*)sender;
    RecordingListData *cellData = [songList objectAtIndex:playButton.tag];
    for (int i = 0; i<[songList count]; i++) {
        RecordingListData *cellData = [songList objectAtIndex:i];
        if (i != playButton.tag) {
            cellData.isSoundPlaying = NO;
        }
    }
    if (cellData.isSoundPlaying) {
        cellData.isSoundPlaying = NO;
       [soundPlayer stopAllSound];
    }
    else {
        cellData.isSoundPlaying = YES;
        [soundPlayer playSelectedRecording:cellData];
    }
    [self refreshTableView];
    //[self setPlayButtonImage:playButton State:cellData];
}

-(void)refreshTableView{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.recordingTableView reloadData];
    });
}

#pragma mark - Table view delegate
- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewRowAction *shareAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Share" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        // maybe show an action sheet with more options
        [self shareSoundTrackAtIndexPath:indexPath.row];
    }];
    
    shareAction.backgroundColor = UIColorFromRGB(GRAY_COLOR);
    
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Delete"  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        [self deleteSoundTrackAtIndex:indexPath];
        //[self.tableview deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    
    deleteAction.backgroundColor = UIColorFromRGB(DELETE_BUTTON_COLOR);
    return @[deleteAction, shareAction];
}

-(void)deleteSoundTrackAtIndex:(NSIndexPath *)indexPath {
    [soundPlayer stopAllSound];

    RecordingListData *cellData = [songList objectAtIndex:indexPath.row];
    
    [songList removeObjectAtIndex:indexPath.row];
    [self.recordingTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self setTableBackGroundView];

    [self performSelector:@selector(stopAudio) withObject:self afterDelay:0.5];
    
    [sqlManager updateDeleteRecordOfRecordID:cellData.recordID];
}

-(void)stopAudio {
    [self soundStopped];
}

- (void)stopAudioPlayer:(NSNotification *)notification {
    [soundPlayer stopAllSound];
    [self soundStopped];
}

-(void)setTableBackGroundView {
    if ([songList count]>0) {
        self.recordingTableView.backgroundView = nil;
    }
    else{
        self.recordingTableView.backgroundView = tableBackGroundView;
    }
}

-(void)shareSoundTrackAtIndexPath:(int)index{
    __block MBProgressHUD *hud;
    __block NSString *mergeOutputPath = @"";
    dispatch_async(dispatch_get_main_queue(), ^{
        hud =[MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.label.text = NSLocalizedString(@"Exporting...", @"");

       

    });
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        // Do something...
        [self soundStopped];
        
        RecordingListData *cellData = [songList objectAtIndex:index];
        
        mergeOutputPath = [soundPlayer loadFilesForMixingAndSharing:cellData];
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if([mergeOutputPath isEqualToString:@""])
            return;
        
        
        
        TTOpenInAppActivity *openInAppActivity = [[TTOpenInAppActivity alloc] initWithView:self.view andRect:self.view.frame];
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:mergeOutputPath]] applicationActivities:@[openInAppActivity]];
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
            // Store reference to superview (UIActionSheet) to allow dismissal
            openInAppActivity.superViewController = activityViewController;
            // Show UIActivityViewController
            [self presentViewController:activityViewController animated:YES completion:NULL];
        } else {
            // Create pop up
            self.activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
            // Store reference to superview (UIPopoverController) to allow dismissal
            openInAppActivity.superViewController = self.activityPopoverController;
            // Show UIActivityViewController in popup
            [self.activityPopoverController presentPopoverFromRect:self.view.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            //            [self.activityPopoverController presentPopoverFromRect:((UIButton *)sender).frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }

    });
    
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //cell.textLabel.backgroundColor = [UIColor clearColor];
    //cell.contentView.backgroundColor = [UIColor colorWithHue:.1 + .07*indexPath.row saturation:1 brightness:1 alpha:1];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [soundPlayer stopAllSound];
    [self.myNavigationController openDetailRecordingView:[songList objectAtIndex:indexPath.row] atIndex:indexPath.row];
    //[self.myNavigationController viewToPresent:2 withDictionary:@[]];
   /* if (! self.expander) {
        if (IS_IPHONE_4s) {
            
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"4sStoryboard" bundle:[NSBundle mainBundle]];
            
            self.expander = [sb instantiateViewControllerWithIdentifier:@"Expander4s"];
        }
        else
            self.expander = [self.storyboard instantiateViewControllerWithIdentifier:@"Expander"];
        
        self.expander.delegate = self;
    }
    [self addChildViewController:self.expander];
    self.expander.view.frame = [self.songTableView rectForRowAtIndexPath:indexPath];
    self.expander.view.center = CGPointMake(self.expander.view.center.x, self.expander.view.center.y - self.songTableView.contentOffset.y); // adjusts for the offset of the cell when you select it
    self.chosenCellFrame = self.expander.view.frame;
    //self.expander.view.backgroundColor = [UIColor colorWithHue:.1 + .07*indexPath.row saturation:1 brightness:1 alpha:1];
    //UILabel *label = (UILabel *)[self.expander.cell viewWithTag:1];
    //label.text = self.theData[indexPath.row];
    [self.expander setDataForUIElements:(int)indexPath.row RecordingData:[songList objectAtIndex:indexPath.row]];
    [self.view addSubview:self.expander.view];
    [self.view bringSubviewToFront:self.expander.view];
    
    [UIView animateWithDuration:0.3 animations:^{
        //self.expander.view.frame = self.songTableView.frame;
        self.expander.view.frame = self.view.bounds;
        self.expander.collapseButton.alpha = 1;
    } completion:^(BOOL finished) {
        //        [self.bannerView removeFromSuperview];
        //        [self.admobBannerView removeFromSuperview];
        
        [self.view sendSubviewToBack:self.admobBannerView];
        
        [self.expander didMoveToParentViewController:self];
    }];*/
}

-(void)openRecordingDeatils:(id)sender{
    UIButton *btn = (UIButton*)sender;
    [self openSessionDetails:btn.tag];
}

-(void)openSessionDetails:(int)sessionIndex{
    [self.myNavigationController openDetailRecordingView:[songList objectAtIndex:sessionIndex] atIndex:sessionIndex];
}

-(void)expandedCellWillCollapse {
    [self.expander willMoveToParentViewController:nil];
    
    self.expander.view.frame = self.chosenCellFrame;
    self.expander.collapseButton.alpha = 0;
    self.expander.closeButtonClicked = YES;
    [self.expander.view removeFromSuperview];
    [self.expander removeFromParentViewController];
    [songList removeAllObjects];
    songList = [sqlManager getAllRecordingData];
    RecordingListData *cellData = [[RecordingListData alloc] init];
    
    [_songTableView reloadData];
    
    //[self.view bringSubviewToFront:_admobBannerView];    //sn
    //[self removeAdBannerView];
    
}

-(void)removeAdBannerView {
//    if([MainNavigationViewController inAppPurchaseEnabled]) {
//        [self.bannerView removeFromSuperview];
//        [self.admobBannerView removeFromSuperview];
//        [iAdBannerView removeFromSuperview];
//        //_songTableView.frame  =  CGRectMake(70, 70, _songTableView.frame.size.width, _songTableView.frame.size.height);
//    }
}

//#pragma mark - IAd & Admob Delegate methods
//- (void)bannerViewWillLoadAd:(ADBannerView *)banner{
//    DLog(@"banner ad loaded");
//    iAdBannerViewHeightConstraint.constant = 50;
//}
//-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
//    DLog(@"did FailTo ReceiveAd With Error");
//    iAdBannerViewHeightConstraint.constant = 1;
//}
////-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
////    
////    [self.bannerView removeFromSuperview];
////    _admobBannerView = [[GADBannerView alloc]
////                        initWithFrame:CGRectMake(0.0,20.0,
////                                                 self.view.frame.size.width,
////                                                 50)];
////    
////    // 3
////    self.admobBannerView.adUnitID = @"ca-app-pub-4385871422548542/4655620110";
////    self.admobBannerView.rootViewController = self;
////    self.admobBannerView.delegate = self;
////    
////    // 4
////    [self.view addSubview:self.admobBannerView];
////    [self.view bringSubviewToFront:self.expander.view];
////    [self.admobBannerView loadRequest:[GADRequest request]];
////    bannerStatus = YES;
////}
//
//- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
//    //[self.admobBannerView removeFromSuperview];
//    //[self.view addSubview:_bannerView];
//}
//

@end
