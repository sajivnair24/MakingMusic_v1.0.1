//
//  protypeTableCell.h
//  FlamencoRhythm
//
//  Created by Ashish Gore on 04/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface protypeTableCell : UITableViewCell
{
    //int tapCount;
}
@property (nonatomic) int tapCount;
@property (strong, nonatomic) IBOutlet UILabel *songNameLbl;
@property (strong, nonatomic) IBOutlet UILabel *dateLbl;
@property (strong, nonatomic) IBOutlet UILabel *TotalTimeLbl;
@property (strong, nonatomic) IBOutlet UILabel *songDetailLbl;




@end
