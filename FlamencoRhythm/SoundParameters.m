//
//  SoundParameters.m
//  Making Music
//
//  Created by Nirma on 07/09/16.
//  Copyright © 2016 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import "SoundParameters.h"

@implementation SoundParameters

-(id)init{
    self = [super init];
    if (self) {
        self.soundPan = 0;
        self.soundVolume = 1;
    }
    return self;
}
@end
