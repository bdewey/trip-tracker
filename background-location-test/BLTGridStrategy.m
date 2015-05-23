//
//  BLTGridStrategy.m
//  background-location-test
//
//  Created by Brian Dewey on 5/13/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "BLTGridStrategy.h"
#import "BLTLocation.h"
#import "BLTPlaceVisit.h"

static MKMapPoint kInvalidMapPoint;

NS_INLINE double BLTBucketizedValue(double mapPointValue,
                                    CLLocationDistance metersPerMapPoint,
                                    CLLocationDistance distancePerBucket)
{
  return round(mapPointValue * metersPerMapPoint * distancePerBucket) / (metersPerMapPoint * distancePerBucket);
}

@implementation BLTGridStrategy
{
  MKMapPoint _currentMapPoint;
  NSTimeInterval _enteredTimestamp;
  NSTimeInterval _leftTimestamp;
  NSMutableData *_coordinates;
  NSUInteger _countOfCoordinates;
  BLTPlaceVisit *_inProgressPlace;
  NSMutableArray *_placeVisits;
}

+ (void)load
{
  kInvalidMapPoint = MKMapPointMake(-1, -1);
}

- (instancetype)initWithBucketDistance:(CLLocationDistance)bucketDistance minimumDuration:(NSTimeInterval)minimumDuration
{
  self = [super init];
  if (self != nil) {
    _bucketDistance = bucketDistance;
    _minimumDuration = minimumDuration;
    _currentMapPoint = kInvalidMapPoint;
    _coordinates = [[NSMutableData alloc] init];
    _placeVisits = [[NSMutableArray alloc] init];
    _countOfCoordinates = 0;
  }
  return self;
}

- (void)addLocation:(BLTLocation *)managedLocation
{
  CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(managedLocation.latitude, managedLocation.longitude);
  MKMapPoint bucketizedMapPoint = [self _bucketizedMapPointForCoordinate:coordinate];
  if (!MKMapPointEqualToPoint(_currentMapPoint, bucketizedMapPoint)) {
    if (!MKMapPointEqualToPoint(_currentMapPoint, kInvalidMapPoint)) {
      // How long we've been in the current grid.
      NSTimeInterval duration = _leftTimestamp - _enteredTimestamp;
      if (duration > _minimumDuration) {
        BLTPlaceVisit *placeVisit = [[BLTPlaceVisit alloc] initWithStartDate:[NSDate dateWithTimeIntervalSinceReferenceDate:_enteredTimestamp]
                                                                     endDate:[NSDate dateWithTimeIntervalSinceReferenceDate:_leftTimestamp]
                                                          countOfCoordinates:_countOfCoordinates
                                                              coordinateData:_coordinates];
        if ([placeVisit distanceFromLocationSegment:_inProgressPlace] <= _bucketDistance * 10) {
          _inProgressPlace = [BLTPlaceVisit locationSegmentByMergingSegment:_inProgressPlace withSegment:placeVisit];
        } else {
          if (_inProgressPlace != nil) {
            [_placeVisits addObject:_inProgressPlace];
          }
          _inProgressPlace = placeVisit;
        }
      }
    }
    _currentMapPoint = bucketizedMapPoint;
    _enteredTimestamp = managedLocation.timestamp;
    _countOfCoordinates = 0;
    _coordinates = [[NSMutableData alloc] init];
  }
  _leftTimestamp = managedLocation.timestamp;
  _countOfCoordinates++;
  [_coordinates appendBytes:&coordinate length:sizeof(CLLocationCoordinate2D)];
}

- (NSArray *)placeVisits
{
  return [_placeVisits copy];
}

- (MKMapPoint)_bucketizedMapPointForCoordinate:(CLLocationCoordinate2D)coordinate
{
  CLLocationDegrees nearestDegreeLatitude = round(coordinate.latitude);
  CLLocationDistance metersPerMapPoint = MKMetersPerMapPointAtLatitude(nearestDegreeLatitude);
  MKMapPoint mapPoint = MKMapPointForCoordinate(coordinate);
  return MKMapPointMake(BLTBucketizedValue(mapPoint.x, metersPerMapPoint, _bucketDistance),
                        BLTBucketizedValue(mapPoint.y, metersPerMapPoint, _bucketDistance));
}

@end
