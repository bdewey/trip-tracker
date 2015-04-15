//
//  BLTLocationHelpers.m
//  background-location-test
//
//  Created by Brian Dewey on 4/15/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "BLTLocation.h"
#import "BLTLocationHelpers.h"


@implementation BLTLocationHelpers

+ (CLLocation *)locationFromManagedLocation:(BLTLocation *)managedLocation
{
  CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(managedLocation.latitude, managedLocation.longitude);
  NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:managedLocation.timestamp];
  return [[CLLocation alloc] initWithCoordinate:coordinate
                                       altitude:managedLocation.altitude
                             horizontalAccuracy:managedLocation.horizontalAccuracy
                               verticalAccuracy:managedLocation.verticalAccuracy
                                         course:managedLocation.course
                                          speed:managedLocation.speed
                                      timestamp:timestamp];
}

@end
