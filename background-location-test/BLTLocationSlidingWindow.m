//
//  BLTLocationSlidingWindow.m
//  background-location-test
//
//  Created by Brian Dewey on 5/12/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "BLTLocation.h"
#import "BLTLocationSlidingWindow.h"
#import "BLTPlaceVisit.h"

@interface _LocationWithBuffer : NSObject

@property (nonatomic, readonly, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, assign) NSTimeInterval timestamp;
@property (nonatomic, readonly, assign) MKMapRect buffer;

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate timestamp:(NSTimeInterval)timestamp bufferDistance:(CLLocationDistance)bufferDistance;

@end

@implementation _LocationWithBuffer

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate timestamp:(NSTimeInterval)timestamp bufferDistance:(CLLocationDistance)bufferDistance
{
  self = [super init];
  if (self != nil) {
    _coordinate = coordinate;
    _timestamp = timestamp;
    MKMapPoint mapPoint = MKMapPointForCoordinate(_coordinate);
    double mapPointsPerMeter = MKMapPointsPerMeterAtLatitude(_coordinate.latitude);
    double bufferInMapPoints = bufferDistance * mapPointsPerMeter;
    _buffer = MKMapRectMake(mapPoint.x - bufferInMapPoints, mapPoint.y - bufferInMapPoints, 2 * bufferInMapPoints, 2 * bufferInMapPoints);
  }
  return self;
}

@end

@implementation BLTLocationSlidingWindow
{
  NSMutableArray *_pointWindow;
  MKMapRect _overlappingRectFromPoints;
  NSMutableArray *_placeVisits;
}

- (instancetype)initWithThresholdDistance:(CLLocationDistance)thresholdDistance
                        thresholdInterval:(NSTimeInterval)thresholdInterval
{
  self = [super init];
  if (self != nil) {
    _thresholdDistance = thresholdDistance;
    _thresholdInterval = thresholdInterval;
    _pointWindow = [[NSMutableArray alloc] init];
    _overlappingRectFromPoints = MKMapRectWorld;
    _placeVisits = [[NSMutableArray alloc] init];
  }
  return self;
}

- (NSArray *)placeVisits
{
  return [_placeVisits copy];
}

- (void)addLocation:(BLTLocation *)managedLocation
{
  _LocationWithBuffer *location = [[_LocationWithBuffer alloc] initWithCoordinate:CLLocationCoordinate2DMake(managedLocation.latitude, managedLocation.longitude)
                                                                        timestamp:managedLocation.timestamp
                                                                   bufferDistance:MAX(managedLocation.horizontalAccuracy, _thresholdDistance)];
  MKMapRect intersection = MKMapRectIntersection(_overlappingRectFromPoints, location.buffer);
  if (!MKMapRectEqualToRect(intersection, MKMapRectNull)) {
    [_pointWindow addObject:location];
    _overlappingRectFromPoints = intersection;
  } else {
//    MKMapRect previousIntersection = MKMapRectWorld;
//    MKMapRect currentIntersection = location.buffer;
//    NSUInteger firstIndexToExclude;
//    for (firstIndexToExclude = _pointWindow.count - 1; firstIndexToExclude > 0; firstIndexToExclude--) {
//      _LocationWithBuffer *currentLocation = _pointWindow[firstIndexToExclude];
//      currentIntersection = MKMapRectIntersection(previousIntersection, currentLocation.buffer);
//      if (MKMapRectEqualToRect(currentIntersection, MKMapRectNull)) {
//        break;
//      }
//      previousIntersection = currentIntersection;
//    }
//    _overlappingRectFromPoints = previousIntersection;
    NSArray *removedPoints = _pointWindow;
    _pointWindow = [[NSMutableArray alloc] initWithObjects:location, nil];
    
    _LocationWithBuffer *firstLocation = [removedPoints firstObject];
    _LocationWithBuffer *lastLocation = [removedPoints lastObject];
    NSTimeInterval elapsed = lastLocation.timestamp - firstLocation.timestamp;
    if (elapsed >= _thresholdInterval) {
      NSUInteger countOfCoordinates = removedPoints.count;
      NSMutableData *coordinateData = [[NSMutableData alloc] initWithLength:countOfCoordinates * sizeof(CLLocationCoordinate2D)];
      CLLocationCoordinate2D *coordinatePtr = coordinateData.mutableBytes;
      for (NSUInteger i = 0; i < countOfCoordinates; i++) {
        coordinatePtr[i] = ((_LocationWithBuffer *)removedPoints[i]).coordinate;
      }
      BLTPlaceVisit *placeVisit = [[BLTPlaceVisit alloc] initWithStartDate:[NSDate dateWithTimeIntervalSinceReferenceDate:firstLocation.timestamp]
                                                                   endDate:[NSDate dateWithTimeIntervalSinceReferenceDate:lastLocation.timestamp]
                                                        countOfCoordinates:countOfCoordinates
                                                            coordinateData:coordinateData];
      [_placeVisits addObject:placeVisit];
    }
  }
}

@end
