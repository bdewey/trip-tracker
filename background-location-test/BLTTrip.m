//
//  BLTTrip.m
//  background-location-test
//
//  Created by Brian Dewey on 4/3/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "BLTLocation.h"
#import "BLTTrip.h"

@implementation BLTTrip

- (instancetype)initWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
                        locations:(NSArray *)locations
{
  self = [super init];
  if (self != nil) {
    _startDate = startDate;
    _endDate = endDate;
    NSUInteger countOfCoordinates = locations.count;
    CLLocationCoordinate2D *coordinates = calloc(countOfCoordinates, sizeof(CLLocationCoordinate2D));
    CLLocation *priorLocation = nil;
    for (NSUInteger i = 0; i < countOfCoordinates; i++) {
      BLTLocation *managedLocationObject = locations[i];
      CLLocation *location = managedLocationObject.location;
      coordinates[i] = location.coordinate;
      _distance += [priorLocation distanceFromLocation:location];
      priorLocation = location;
    }
    _route = [MKPolyline polylineWithCoordinates:coordinates count:countOfCoordinates];
  }
  return self;
}

@end
