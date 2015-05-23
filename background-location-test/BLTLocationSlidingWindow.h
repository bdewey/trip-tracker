//
//  BLTLocationSlidingWindow.h
//  background-location-test
//
//  Created by Brian Dewey on 5/12/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "BLTPlaceDetectionStrategy.h"

@class BLTPlaceVisit;

@interface BLTLocationSlidingWindow : NSObject <BLTPlaceDetectionStrategy>

@property (nonatomic, readonly, assign) CLLocationDistance thresholdDistance;
@property (nonatomic, readonly, assign) NSTimeInterval thresholdInterval;

- (instancetype)initWithThresholdDistance:(CLLocationDistance)thresholdDistance
                        thresholdInterval:(NSTimeInterval)thresholdInterval NS_DESIGNATED_INITIALIZER;

@end

