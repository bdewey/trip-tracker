//
//  BLTTrip.m
//  background-location-test
//
//  Created by Brian Dewey on 4/3/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "BLTLocation.h"
#import "BLTLocationHelpers.h"
#import "BLTStatisticsSummary.h"
#import "BLTTrip.h"

typedef struct {
  CLLocationDistance distanceFromStartOfTrip;
  CLLocationDistance altitude;
} BLTTripAltitude;

NS_INLINE BLTTripAltitude BLTTripAltitudeMake(CLLocationDistance distanceFromStartOfTrip, CLLocationDistance altitude)
{
  BLTTripAltitude altitudeMeasurement;
  altitudeMeasurement.distanceFromStartOfTrip = distanceFromStartOfTrip;
  altitudeMeasurement.altitude = altitude;
  return altitudeMeasurement;
}

NS_INLINE BOOL _CompareDouble(double x, double y)
{
  return fabs(x - y) < 0.0000001;
}

@interface BLTTrip ()

- (instancetype)initWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
               countOfCoordinates:(NSUInteger)countOfCoordinates
                         distance:(CLLocationDistance)distance
                     altitudeGain:(CLLocationDistance)altitudeGain
                   coordinateData:(NSData *)coordinateData
                     altitudeData:(NSData *)altitudeData
             locationSpeedSummary:(BLTStatisticsSummary *)locationSpeedSummary
      locationAccelerationSummary:(BLTStatisticsSummary *)locationAccelerationSummary
                                  NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end

@implementation BLTTrip
{
  NSData *_altitudeData;
}

- (instancetype)initWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
               countOfCoordinates:(NSUInteger)countOfCoordinates
                         distance:(CLLocationDistance)distance
                     altitudeGain:(CLLocationDistance)altitudeGain
                   coordinateData:(NSData *)coordinateData
                     altitudeData:(NSData *)altitudeData
             locationSpeedSummary:(BLTStatisticsSummary *)locationSpeedSummary
      locationAccelerationSummary:(BLTStatisticsSummary *)locationAccelerationSummary
{
  self = [super initWithStartDate:startDate endDate:endDate countOfCoordinates:countOfCoordinates coordinateData:coordinateData];
  if (self != nil) {
    _distance = distance;
    _altitudeGain = altitudeGain;
    _altitudeData = [altitudeData copy];
    _locationSpeedSummary = [locationSpeedSummary copy];
    _locationAccelerationSummary = [locationAccelerationSummary copy];
  }
  return self;
}

- (instancetype)initWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
                        locations:(NSArray *)locations
{
  NSUInteger countOfCoordinates = locations.count;
  NSMutableData *coordinateData = [[NSMutableData alloc] initWithLength:countOfCoordinates * sizeof(CLLocationCoordinate2D)];
  CLLocationCoordinate2D *coordinates = coordinateData.mutableBytes;
  NSMutableData *altitudeData = [[NSMutableData alloc] initWithLength:countOfCoordinates * sizeof(BLTTripAltitude)];
  BLTTripAltitude *altitudeMeasurements = altitudeData.mutableBytes;
  CLLocation *startOfTrip = nil;
  CLLocation *priorLocation = nil;
  BLTStatisticsSummary *locationSpeedSummary = [[BLTStatisticsSummary alloc] init];
  BLTStatisticsSummary *locationAccelerationSummary = [[BLTStatisticsSummary alloc] init];
  CLLocationDistance distance = 0;
  CLLocationDistance altitudeGain = 0;
  for (NSUInteger i = 0; i < countOfCoordinates; i++) {
    BLTLocation *managedLocationObject = locations[i];
    CLLocation *location = [BLTLocationHelpers locationFromManagedLocation:managedLocationObject];
    if (startOfTrip == nil) {
      startOfTrip = location;
    }
    altitudeMeasurements[i] = BLTTripAltitudeMake([location distanceFromLocation:startOfTrip], location.altitude);
    coordinates[i] = location.coordinate;
    [locationSpeedSummary addObservation:location.speed];
    if (priorLocation != nil) {
      distance += [priorLocation distanceFromLocation:location];
      CLLocationDistance altitudeDelta = location.altitude - priorLocation.altitude;
      if (altitudeDelta > 0) {
        altitudeGain += altitudeDelta;
      }
      CLLocationSpeed speedDelta = location.speed - priorLocation.speed;
      NSTimeInterval timeDelta = [location.timestamp timeIntervalSinceDate:priorLocation.timestamp];
      [locationAccelerationSummary addObservation:speedDelta/timeDelta];
    }
    priorLocation = location;
  }
  return [self initWithStartDate:startDate
                         endDate:endDate
              countOfCoordinates:countOfCoordinates
                        distance:distance
                    altitudeGain:altitudeGain
                  coordinateData:coordinateData
                    altitudeData:altitudeData
            locationSpeedSummary:locationSpeedSummary
     locationAccelerationSummary:locationAccelerationSummary];
}

- (instancetype)initWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
               countOfCoordinates:(NSUInteger)countOfCoordinates
                   coordinateData:(NSData *)coordinateData
{
  @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"not designated initializer" userInfo:nil];
  return [self initWithStartDate:nil endDate:nil locations:nil];
}

- (NSDictionary *)dictionaryRepresentation
{
  NSMutableDictionary *mutableParent = [[super dictionaryRepresentation] mutableCopy];
  [mutableParent addEntriesFromDictionary:@{
                                            @"distance": @(_distance),
                                            @"altitudeGain": @(_altitudeGain),
                                            @"speed": _locationSpeedSummary,
                                            @"acceleration": _locationAccelerationSummary,
                                            }];
  return mutableParent;
}

- (BOOL)isEqualToTrip:(BLTTrip *)trip
{
  if (trip == nil) {
    return NO;
  }
  return [self isEqualToLocationSegment:trip] &&
    _CompareDouble(_distance, trip->_distance) &&
    _CompareDouble(_altitudeGain, trip->_altitudeGain) &&
    [_altitudeData isEqualToData:trip->_altitudeData] &&
    [_locationSpeedSummary isEqualToStatisticsSummary:trip->_locationSpeedSummary] &&
    [_locationAccelerationSummary isEqualToStatisticsSummary:trip->_locationAccelerationSummary];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if ([object isKindOfClass:[self class]]) {
    return [self isEqualToTrip:object];
  }
  return NO;
}

- (NSUInteger)hash
{
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
  return [data hash];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self != nil) {
    _distance = [aDecoder decodeDoubleForKey:@"distance"];
    _altitudeGain = [aDecoder decodeDoubleForKey:@"altitudeGain"];
    _altitudeData = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"altitudeData"];
    _locationSpeedSummary = [aDecoder decodeObjectOfClass:[BLTStatisticsSummary class] forKey:@"locationSpeedSummary"];
    _locationAccelerationSummary = [aDecoder decodeObjectOfClass:[BLTStatisticsSummary class] forKey:@"locationAccelerationSummary"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeDouble:_distance forKey:@"distance"];
  [aCoder encodeDouble:_altitudeGain forKey:@"altitudeGain"];
  [aCoder encodeObject:_altitudeData forKey:@"altitudeData"];
  [aCoder encodeObject:_locationSpeedSummary forKey:@"locationSpeedSummary"];
  [aCoder encodeObject:_locationAccelerationSummary forKey:@"locationAccelerationSummary"];
}

@end
