//
//  BLTLocationSlidingWindow.m
//  background-location-test
//
//  Created by Brian Dewey on 4/12/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import "BLTLocationSlidingWindow.h"

@implementation BLTLocationSlidingWindow
{
  NSMutableArray *_locations;
}

- (instancetype)initWithDesiredTimeInterval:(NSTimeInterval)desiredTimeInterval
{
  self = [super init];
  if (self != nil) {
    _desiredTimeInterval = desiredTimeInterval;
    _locations = [[NSMutableArray alloc] init];
  }
  return self;
}

- (NSString *)description
{
  NSDictionary *properties = @{
                               @"countOfLocations": @(self.countOfLocations),
                               @"actualTimeInterval": @(_actualTimeInterval),
                               @"distance": @(self.distance),
                               };
  return [NSString stringWithFormat:@"%@ %@", [super description], properties];
}

- (void)addLocation:(CLLocation *)location
{
  if (location.horizontalAccuracy >= 100) {
    // Not accurate enough.
    return;
  }
  NSTimeInterval gap = [location.timestamp timeIntervalSinceDate:self.lastLocation.timestamp];
  if (gap >= _desiredTimeInterval) {
    // discontinuity
    [_locations removeAllObjects];
  }
  [_locations addObject:location];
  NSInteger countOfElementsToRemove = 0;
  while (countOfElementsToRemove < _locations.count) {
    CLLocation *startLocation = _locations[countOfElementsToRemove];
    NSTimeInterval proposedTimeInterval = [location.timestamp timeIntervalSinceDate:startLocation.timestamp];
    if (proposedTimeInterval <= _desiredTimeInterval) {
      break;
    }
    _actualTimeInterval = proposedTimeInterval;
    countOfElementsToRemove++;
  }
  countOfElementsToRemove = MAX(0, countOfElementsToRemove - 1);
  [_locations removeObjectsInRange:NSMakeRange(0, countOfElementsToRemove)];
}

- (NSUInteger)countOfLocations
{
  return _locations.count;
}

- (CLLocation *)firstLocation
{
  return _locations.firstObject;
}

- (CLLocation *)lastLocation
{
  return _locations.lastObject;
}

- (CLLocationDistance)distance
{
  CLLocation *firstLocation = _locations.firstObject;
  CLLocation *lastLocation = _locations.lastObject;
  
  return [firstLocation distanceFromLocation:lastLocation];
}

@end
