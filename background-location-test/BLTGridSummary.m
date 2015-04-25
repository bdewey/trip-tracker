//
//  BLTGridSummary.m
//  background-location-test
//
//  Created by Brian Dewey on 4/25/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import "BLTGridSummary.h"

NS_INLINE double BLTBucketizedValue(double mapPointValue,
                                    CLLocationDistance metersPerMapPoint,
                                    CLLocationDistance distancePerBucket)
{
  return round(mapPointValue * metersPerMapPoint * distancePerBucket) / (metersPerMapPoint * distancePerBucket);
}

@implementation BLTGridSummary

- (instancetype)initWithMapPoint:(MKMapPoint)mapPoint
                 dateEnteredGrid:(NSDate *)dateEnteredGrid
                    dateLeftGrid:(NSDate *)dateLeftGrid
{
  self = [super init];
  if (self != nil) {
    _mapPoint = mapPoint;
    _dateEnteredGrid = dateEnteredGrid;
    _dateLeftGrid = dateLeftGrid;
  }
  return self;
}

- (NSTimeInterval)duration
{
  return [_dateLeftGrid timeIntervalSinceDate:_dateEnteredGrid];
}

+ (MKMapPoint)bucketizedMapPointForCoordinate:(CLLocationCoordinate2D)coordinate
                            distancePerBucket:(CLLocationDistance)distancePerBucket
{
  CLLocationDegrees nearestDegreeLatitude = round(coordinate.latitude);
  CLLocationDistance metersPerMapPoint = MKMetersPerMapPointAtLatitude(nearestDegreeLatitude);
  MKMapPoint mapPoint = MKMapPointForCoordinate(coordinate);
  return MKMapPointMake(BLTBucketizedValue(mapPoint.x, metersPerMapPoint, distancePerBucket),
                        BLTBucketizedValue(mapPoint.y, metersPerMapPoint, distancePerBucket));
}

@end
