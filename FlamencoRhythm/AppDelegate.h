//
//  AppDelegate.h
//  FlamencoRhythm
//
//  Created by Mayank Mathur on 04/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainNavigationViewController.h"
#import "SoundPlayManger.h"
@class RecordViewController;
@class SavedListViewController;
@class  RhythmClass;

@interface AppDelegate : UIResponder <UIApplicationDelegate,SoundManagerDelegate>{
    SoundPlayManger *soundManager;
    int totalNumberOfWaveFiles;
    int convertedWavFilesNumber;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MainNavigationViewController *myNavigationController;
@property (strong, nonatomic) RhythmClass *latestRhythmClass;
@property (strong, nonatomic) RecordViewController *secondVC;
@property (strong, nonatomic) SavedListViewController *thirdVC;

@end

