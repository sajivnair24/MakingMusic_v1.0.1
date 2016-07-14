//
//  AppDelegate.m
//  FlamencoRhythm
//
//  Created by Mayank Mathur on 04/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import "AppDelegate.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
//#import <NewRelicAgent/NewRelic.h>
#import "RecordViewController.h"
#import "SavedListViewController.h"
#import "RhythmClass.h"
#import "TestFairy.h"
#import "iRate.h"
@interface AppDelegate (){
    
}

@end

@implementation AppDelegate
@synthesize myNavigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Fabric with:@[[Crashlytics class]]];
    
    //[NewRelicAgent startWithApplicationToken:@"AAfbaba86e6cc8bd1629508c721015e2bb26f27170"];

    // Override point for customization after application launch.
    _latestRhythmClass = [[RhythmClass alloc]init];
  
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    myNavigationController = [mainStoryboard instantiateViewControllerWithIdentifier:@"navigationVC"];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    self.window.rootViewController = myNavigationController;
    [TestFairy begin:@"06f08cccd13056e2504baab36a50f47a699efcd0"];//sdk app token
    [self setIRateConfig];
    return YES;
}
-(void)setIRateConfig{
    //[iRate sharedInstance].appStoreID = 966466277;//please provide app store id
    
    [iRate sharedInstance].eventsUntilPrompt = 12;
    
    //disable minimum day limit and reminder periods
    [iRate sharedInstance].daysUntilPrompt = 0;
    [iRate sharedInstance].remindPeriod = 0;
   
    //enable preview mode
    //for testing purpose only
    [iRate sharedInstance].previewMode = YES;
    [iRate sharedInstance].onlyPromptIfLatestVersion = NO;
}
#pragma mark iRate delegate methods

- (void)iRateUserDidRequestReminderToRateApp
{
    //reset event count after every 5 (for demo purposes)
    [iRate sharedInstance].eventCount = 0;
}
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
