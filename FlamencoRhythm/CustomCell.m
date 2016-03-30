//
//  CustomCell.m
//  iCloud
//
//  Created by intelliswift on 02/04/15.
//  Copyright (c) 2015 intelliswift. All rights reserved.
//

#import "CustomCell.h"
#import "Constants.h"

//@"HelveticaNeue-Light"
@implementation CustomCell

- (void)awakeFromNib {
    // Initialization code
}
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        CGRect rect = [[UIScreen mainScreen] bounds];
        rect.size.height = 20;
        _rhythmLabel = [[UILabel alloc] initWithFrame:rect];
        _rhythmLabel.font = [UIFont fontWithName:FONT_MEDIUM size:15];
        _rhythmLabel.textColor = [UIColor blackColor];
        _rhythmLabel.backgroundColor = [UIColor clearColor];
        _rhythmLabel.textAlignment = NSTextAlignmentCenter;
       // [self.contentView addSubview:_rhythmLabel];
        
        _rhythmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _rhythmButton.frame = CGRectMake((rect.size.width-140)/2, 16, 140, 20);
        [_rhythmButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        [_rhythmButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_rhythmButton setBackgroundColor:[UIColor clearColor]];
        
        [_rhythmButton.titleLabel setFont:[UIFont fontWithName:FONT_REGULAR size:15]];
        //[_rhythmButton setTitle:@"Hello" forState:UIControlStateNormal];
        [self.contentView addSubview:_rhythmButton];
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
