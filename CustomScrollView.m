//
//  CustomScrollView.m
//  FlamencoRhythm
//
//  Created by Mayank Mathur on 11/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import "CustomScrollView.h"

@implementation CustomScrollView

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    //NSLog(@"Scroll Touch Began");
    // If not dragging, send event to next responder
    if (!self.dragging){
        [self.nextResponder touchesBegan: touches withEvent:event];
    }
    else{
        [super touchesBegan: touches withEvent: event];
    }
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
     //NSLog(@"Scroll Touch Move");
    [self.nextResponder touchesMoved: touches withEvent:event];

/*    // If not dragging, send event to next responder
    if (!self.dragging){
        [self.nextResponder touchesMoved: touches withEvent:event];
    }
    else{
        [super touchesMoved: touches withEvent: event];
    }
  */
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
     //NSLog(@"Scroll Touch End");
    // If not dragging, send event to next responder
    if (!self.dragging){
        [self.nextResponder touchesEnded: touches withEvent:event];
    }
    else{
        [super touchesEnded: touches withEvent: event];
    }
}

@end
