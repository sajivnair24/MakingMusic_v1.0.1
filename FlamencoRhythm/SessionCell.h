//
//  SessionCell.h
//  FlamencoRhythm
//
//  Created by Nirma on 04/03/16.
//  Copyright © 2016 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SessionCell : UITableViewCell
@property (nonatomic) int tapCount;
@property (strong, nonatomic)  UILabel *songNameLbl;
@property (strong, nonatomic)  UILabel *dateLbl;
@property (strong, nonatomic)  UILabel *TotalTimeLbl;
@property (strong, nonatomic)  UILabel *songDetailLbl;
@property (strong , nonatomic) UIButton *playButton;
@property (strong, nonatomic) UIView *seprator;
@property (strong , nonatomic) UIButton *sessionSelectButton;

@end
