//
//  BLTGridStrategy.h
//  background-location-test
//
//  Created by Brian Dewey on 5/13/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "BLTPlaceDetectionStrategy.h"

@interface BLTGridStrategy : NSObject <BLTPlaceDetectionStrategy>

@property (nonatomic, readonly, assign) CLLocationDistance bucketDistance;
@property (nonatomic, readonly, assign) NSTimeInterval minimumDuration;

- (instancetype)initWithBucketDistance:(CLLocationDistance)bucketDistance
                       minimumDuration:(NSTimeInterval)minimumDuration NS_DESIGNATED_INITIALIZER;

@end
