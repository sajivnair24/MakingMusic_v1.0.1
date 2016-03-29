//
//  DropDown.h
//  iCloud
//
//  Created by intelliswift on 31/03/15.
//  Copyright (c) 2015 intelliswift. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GenreClass.h"

@class DBManager;

IB_DESIGNABLE;

@protocol DropDownDelegate <NSObject>

-(void)closeDropDown;
-(void)dropDownSelectedCell:(NSDictionary*)dct;
-(void)dropDownSameCellSelected;

@end

@interface DropDown : UIView <UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate> {
    UITableView *table;
    UIButton *closeButton;
    NSMutableArray *rhythmArray;
    NSMutableDictionary *rhythmDct;
    UIImageView *tableViewBackground;
    DBManager *dbObj;
    int currentIndexPath;
    UILabel *heading;
}

@property (nonatomic, assign) id<DropDownDelegate> delegate;
@property (nonatomic, retain) NSString *selectedString;
//@property (nonatomic, retain) NSMutableArray *rhythmArray;

-(id)initWithFrame:(CGRect)frame
           heading:(NSString *)headingText;

-(void)reloadTableView;

@end
