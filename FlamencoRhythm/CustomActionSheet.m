//
//  CustomActionSheet.m
//  FlamencoRhythm
//
//  Created by Ashish Gore on 16/09/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import "CustomActionSheet.h"

@implementation CustomActionSheet

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

// For detecting taps outside of the alert view

-(void)tapOut:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint p = [gestureRecognizer locationInView:self];
    if (p.y < 0)
    { // They tapped outside
        [self dismissWithClickedButtonIndex:0 animated:YES];
    }
}


- (void)showInView:(UIView *)view
{
    [super showInView:view];
    // Capture taps outside the bounds of this alert view
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOut:)];
    tap.cancelsTouchesInView = NO; // So that legit taps on the table bubble up to the tableview
    [self.superview addGestureRecognizer:tap];
    
}

@end
