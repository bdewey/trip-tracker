//
//  BLTTrip.m
//  background-location-test
//
//  Created by Brian Dewey on 4/3/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "BLTLocation.h"
#import "BLTStatisticsSummary.h"
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
    _locationSpeedSummary = [[BLTStatisticsSummary alloc] init];
    _locationAccelerationSummary = [[BLTStatisticsSummary alloc] init];
    for (NSUInteger i = 0; i < countOfCoordinates; i++) {
      BLTLocation *managedLocationObject = locations[i];
      CLLocation *location = managedLocationObject.location;
      coordinates[i] = location.coordinate;
      if (location.speed > 0) {
        [_locationSpeedSummary addObservation:location.speed];
        if (priorLocation != nil) {
          _distance += [priorLocation distanceFromLocation:location];
          CLLocationDistance altitudeDelta = location.altitude - priorLocation.altitude;
          if (altitudeDelta > 0) {
            _altitudeGain += altitudeDelta;
          }
          CLLocationSpeed speedDelta = location.speed - priorLocation.speed;
          NSTimeInterval timeDelta = [location.timestamp timeIntervalSinceDate:priorLocation.timestamp];
          [_locationAccelerationSummary addObservation:speedDelta/timeDelta];
        }
        priorLocation = location;
      }
    }
    _route = [MKPolyline polylineWithCoordinates:coordinates count:countOfCoordinates];
    free(coordinates);
  }
  return self;
}

- (NSString *)description
{
  NSDictionary *properties = @{
                               @"start": _startDate,
                               @"end": _endDate,
                               @"speed": _locationSpeedSummary,
                               @"acceleration": _locationAccelerationSummary,
                               };
  return [NSString stringWithFormat:@"%@ %@", [super description], properties];
}

@end
