//
//  GenreClass.h
//  FlamencoRhythm
//
//  Created by Mayank Mathur on 18/03/15.
//  Copyright (c) 2015 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GenreClass : NSObject{
    
}

@property (nonatomic, strong) NSNumber *genreId;
@property (nonatomic, strong) NSString *genreName;
@property (nonatomic, strong) NSNumber *genreIsDeleted;
@property (nonatomic, strong) NSNumber *genrePosition;

@end
