//
//  BLTLocationSlidingWindow.h
//  background-location-test
//
//  Created by Brian Dewey on 4/12/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface BLTLocationSlidingWindow : NSObject

@property (nonatomic, readonly, assign) NSTimeInterval desiredTimeInterval;
@property (nonatomic, readonly, assign) NSTimeInterval actualTimeInterval;
@property (nonatomic, readonly, assign) NSUInteger countOfLocations;
@property (nonatomic, readonly, assign) CLLocationDistance distance;

@property (nonatomic, readonly, strong) CLLocation *firstLocation;
@property (nonatomic, readonly, strong) CLLocation *lastLocation;

- (instancetype)initWithDesiredTimeInterval:(NSTimeInterval)desiredTimeInterval NS_DESIGNATED_INITIALIZER;

- (void)addLocation:(CLLocation *)location;

@end
