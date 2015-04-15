//
//  BLTMotionActivity.h
//  background-location-test
//
//  Created by Brian Dewey on 4/15/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface BLTMotionActivity : NSManagedObject

@property (nonatomic) BOOL automotive;
@property (nonatomic) int16_t confidence;
@property (nonatomic) BOOL cycling;
@property (nonatomic) BOOL running;
@property (nonatomic) NSTimeInterval startDate;
@property (nonatomic) BOOL stationary;
@property (nonatomic) BOOL walking;
@property (nonatomic) BOOL unknown;

@end
