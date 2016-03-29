//
//  TimeStretching.h
//  FlamencoRhythm
//
//  Created by Sajiv Nair on 24/11/15.
//  Copyright © 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#ifndef TimeStretcher_h
#define TimeStretcher_h


#endif /* TimeStretcher_h */
#include "TPAACAudioConverter.h"


@interface TimeStretcher : NSObject <TPAACAudioConverterDelegate> {
}

-(id)init;


-(void)timeStretchAndConvert:(NSString *)inputFile
              withOutputFile:(NSString *)outputFile
                   withTempo:(float)tempo;

-(void)audioConvertFileFormat:(NSString *)inputFile
               withOutputFile:(NSString *)outputFile;

@end
