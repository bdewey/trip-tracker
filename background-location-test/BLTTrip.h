//
//  BLTTrip.h
//  background-location-test
//
//  Created by Brian Dewey on 4/3/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class BLTStatisticsSummary;
@class MKPolyline;

#import "BLTLocationSegment.h"

@interface BLTTrip : BLTLocationSegment <NSSecureCoding>

@property (nonatomic, readonly, assign) CLLocationDistance distance;
@property (nonatomic, readonly, assign) CLLocationDistance altitudeGain;
@property (nonatomic, readonly, strong) BLTStatisticsSummary *locationSpeedSummary;
@property (nonatomic, readonly, strong) BLTStatisticsSummary *locationAccelerationSummary;

- (instancetype)initWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
                        locations:(NSArray *)locations;

- (BOOL)isEqualToTrip:(BLTTrip *)trip;

@end
