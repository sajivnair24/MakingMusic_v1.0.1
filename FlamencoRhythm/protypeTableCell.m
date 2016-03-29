//
//  protypeTableCell.m
//  FlamencoRhythm
//
//  Created by Ashish Gore on 04/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import "protypeTableCell.h"

@implementation protypeTableCell

- (void)awakeFromNib {
    // Initialization code
  
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
//     UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:self.selectedBackgroundView.frame];
    if(selected)
    {
//        
//        [selectedBackgroundView setBackgroundColor:[UIColor whiteColor]]; // set color here
//        [self setSelectedBackgroundView:selectedBackgroundView];
//        
//        self.songNameLbl.textColor = [UIColor blackColor];
//        self.dateLbl.textColor = [UIColor blackColor];
//        self.TotalTimeLbl.textColor = [UIColor blackColor];
//        self.songDetailLbl.textColor = [UIColor blackColor];
//        //self.closeBtn.hidden = NO;
     
    }
    else
    {
        self.songNameLbl.textColor = [UIColor whiteColor];
        self.dateLbl.textColor = [UIColor whiteColor];
        self.TotalTimeLbl.textColor = [UIColor whiteColor];
        self.songDetailLbl.textColor = [UIColor whiteColor];
       // self.closeBtn.hidden = YES;
    }
    
}

@end
