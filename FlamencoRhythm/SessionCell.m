//
//  SessionCell.m
//  FlamencoRhythm
//
//  Created by Nirma on 04/03/16.
//  Copyright © 2016 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import "SessionCell.h"
#import "PureLayout.h"
#import "Constants.h"
#define DIFFERENCE_FROM_PLAY_BUTTON 0
@implementation SessionCell
@synthesize songNameLbl,dateLbl,TotalTimeLbl,songDetailLbl,tapCount,seprator,playButton,sessionSelectButton;;
- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        songNameLbl = [[UILabel alloc]init];
        dateLbl = [[UILabel alloc]init];
        TotalTimeLbl = [[UILabel alloc]init];
        songDetailLbl = [[UILabel alloc]init];
        playButton  = [[UIButton alloc]init];
        seprator  = [[UIView alloc]init];
        
        [self.contentView addSubview:playButton];
        [self.contentView addSubview:songNameLbl];
        [self.contentView addSubview:dateLbl];
        [self.contentView addSubview:TotalTimeLbl];
        [self.contentView addSubview:seprator];
         [self.contentView addSubview:songDetailLbl];
        UIImage *playImage = [UIImage imageNamed:@"play.png"];
        //NSLog(@"imageSize w=%f ,h=%f",playImage.size.width,playImage.size.height);
        [playButton setImage:playImage forState:UIControlStateNormal];
        [playButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:DIFFERENCE_FROM_PLAY_BUTTON];
        [playButton autoSetDimensionsToSize:CGSizeMake(42, 48)];
        // [playButton autoSetDimensionsToSize:playImage.size];
        [playButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
       // playButton.backgroundColor = [UIColor redColor];
        
        [songNameLbl autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:playButton withOffset:DIFFERENCE_FROM_PLAY_BUTTON];
        [songNameLbl autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
        [songNameLbl autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:10];
        
        [dateLbl autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:playButton withOffset:DIFFERENCE_FROM_PLAY_BUTTON];
        [dateLbl autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:12];
        
        [TotalTimeLbl autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:dateLbl withOffset:15];
        [TotalTimeLbl autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:12];
        
        [songDetailLbl autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:12];
        [songDetailLbl autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:10];
        //[songDetailLbl autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:TotalTimeLbl withOffset:5];
        [songDetailLbl autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeWidth ofView:self.contentView withMultiplier:0.48];
        
        [seprator autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
        [seprator autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [seprator autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:playButton withOffset:DIFFERENCE_FROM_PLAY_BUTTON];
        [seprator autoSetDimension:ALDimensionHeight toSize:0.5];
        
        seprator.backgroundColor = UIColorFromRGB(GRAY_COLOR);
        songDetailLbl.textAlignment = NSTextAlignmentRight;
        
        [songNameLbl setFont:[UIFont fontWithName:FONT_REGULAR size:15]];
        [dateLbl setFont:[UIFont fontWithName:FONT_LIGHT size:10]];
        [TotalTimeLbl setFont:[UIFont fontWithName:FONT_LIGHT size:10]];
        [songDetailLbl setFont:[UIFont fontWithName:FONT_LIGHT size:10]];
        
        TotalTimeLbl.textColor = dateLbl.textColor = songDetailLbl.textColor = [UIColor grayColor];
    }
    return self;
}
@end
