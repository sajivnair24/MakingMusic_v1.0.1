//
//  AppDelegate.h
//  FlamencoRhythm
//
//  Created by Mayank Mathur on 04/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainNavigationViewController.h"

@class RecordViewController;
@class SavedListViewController;
@class  RhythmClass;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MainNavigationViewController *myNavigationController;
@property (strong, nonatomic) RhythmClass *latestRhythmClass;
@property (strong, nonatomic) RecordViewController *secondVC;
@property (strong, nonatomic) SavedListViewController *thirdVC;

@end

