//
//  BLTLocationHelpers.m
//  background-location-test
//
//  Created by Brian Dewey on 4/15/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "BLTLocation.h"
#import "BLTLocationHelpers.h"


@implementation BLTLocationHelpers

+ (CLLocation *)locationFromManagedLocation:(BLTLocation *)managedLocation
{
  CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(managedLocation.latitude, managedLocation.longitude);
  NSDate *timestamp = [NSDate dateWithTimeIntervalSinceReferenceDate:managedLocation.timestamp];
  return [[CLLocation alloc] initWithCoordinate:coordinate
                                       altitude:managedLocation.altitude
                             horizontalAccuracy:managedLocation.horizontalAccuracy
                               verticalAccuracy:managedLocation.verticalAccuracy
                                         course:managedLocation.course
                                          speed:managedLocation.speed
                                      timestamp:timestamp];
}

+ (MKCoordinateRegion)coordinateRegionForMultiPoint:(MKMultiPoint *)multiPoint
{
  NSUInteger countOfPoints = multiPoint.pointCount;
  CLLocationCoordinate2D *coordinates = calloc(countOfPoints, sizeof(CLLocationCoordinate2D));
  if (coordinates == NULL) {
    return MKCoordinateRegionMake(CLLocationCoordinate2DMake(0, 0), MKCoordinateSpanMake(0, 0));
  }
  [multiPoint getCoordinates:coordinates range:NSMakeRange(0, countOfPoints)];
  CLLocationDegrees minLatitude = 90;
  CLLocationDegrees maxLatitude = -90;
  CLLocationDegrees minLongitude = 180;
  CLLocationDegrees maxLongitude = -180;
  for (NSUInteger i = 0; i < countOfPoints; i++) {
    CLLocationCoordinate2D coordinate = coordinates[i];
    if (CLLocationCoordinate2DIsValid(coordinate)) {
      minLatitude = MIN(minLatitude, coordinate.latitude);
      maxLatitude = MAX(maxLatitude, coordinate.latitude);
      minLongitude = MIN(minLongitude, coordinate.longitude);
      maxLongitude = MAX(maxLongitude, coordinate.longitude);
    }
  }
  free(coordinates);
  CLLocationCoordinate2D center = CLLocationCoordinate2DMake((minLatitude + maxLatitude) / 2, (minLongitude + maxLongitude) / 2);
  MKCoordinateSpan span = MKCoordinateSpanMake(maxLatitude - minLatitude, maxLongitude - minLongitude);
  return MKCoordinateRegionMake(center, span);
}

@end
