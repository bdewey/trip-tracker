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
              horizontalAccuracy:(CLLocationDistance)horizontalAccuracy
                 dateEnteredGrid:(NSDate *)dateEnteredGrid
                    dateLeftGrid:(NSDate *)dateLeftGrid
{
  self = [super init];
  if (self != nil) {
    _mapPoint = mapPoint;
    _horizontalAccuracy = horizontalAccuracy;
    _dateEnteredGrid = dateEnteredGrid;
    _dateLeftGrid = dateLeftGrid;
  }
  return self;
}

- (instancetype)gridSummaryByMergingSummary:(BLTGridSummary *)otherSummary
{
  NSDate *dateEnteredGrid = [_dateEnteredGrid compare:otherSummary.dateEnteredGrid] == NSOrderedAscending ? _dateEnteredGrid : otherSummary.dateEnteredGrid;
  NSDate *dateLeftGrid = [_dateLeftGrid compare:otherSummary.dateLeftGrid] == NSOrderedDescending ? _dateLeftGrid : otherSummary.dateLeftGrid;
  double weightedAverageX = (self.duration * _mapPoint.x + otherSummary.duration * otherSummary.mapPoint.x) / (self.duration + otherSummary.duration);
  double weightedAverageY = (self.duration * _mapPoint.y + otherSummary.duration * otherSummary.mapPoint.y) / (self.duration + otherSummary.duration);
  MKMapPoint weightedAverageMapPoint = MKMapPointMake(weightedAverageX, weightedAverageY);
  CLLocationDistance horizontalAccuracy = MKMetersBetweenMapPoints(weightedAverageMapPoint, _mapPoint) + _horizontalAccuracy;
  CLLocationDistance distanceToEdgeOfOtherRange = MKMetersBetweenMapPoints(weightedAverageMapPoint, otherSummary.mapPoint) + otherSummary.horizontalAccuracy;
  horizontalAccuracy += MAX(0, distanceToEdgeOfOtherRange - horizontalAccuracy);
  return [[[self class] alloc] initWithMapPoint:weightedAverageMapPoint
                             horizontalAccuracy:horizontalAccuracy
                                dateEnteredGrid:dateEnteredGrid
                                   dateLeftGrid:dateLeftGrid];
}

- (NSTimeInterval)duration
{
  return [_dateLeftGrid timeIntervalSinceDate:_dateEnteredGrid];
}

- (NSTimeInterval)timeIntervalSinceSummary:(BLTGridSummary *)otherSummary
{
  // Make the comparison symmetric by determining which summary comes later
  BOOL selfComesFirst = [_dateEnteredGrid compare:otherSummary.dateEnteredGrid] == NSOrderedAscending;
  BLTGridSummary *firstSummary = nil;
  BLTGridSummary *secondSummary = nil;
  if (selfComesFirst) {
    firstSummary = self;
    secondSummary = otherSummary;
  } else {
    firstSummary = otherSummary;
    secondSummary = self;
  }
  NSTimeInterval interval = [secondSummary.dateEnteredGrid timeIntervalSinceDate:firstSummary.dateLeftGrid];
  NSAssert(interval > 0, @"Should have a postive interval");
  return interval;
}

- (CLLocationDistance)distanceFromSummary:(BLTGridSummary *)otherSummary
{
  return MKMetersBetweenMapPoints(_mapPoint, otherSummary.mapPoint);
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
