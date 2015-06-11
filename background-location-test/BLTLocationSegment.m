//
//  BLTLocationSegment.m
//  
//
//  Created by Brian Dewey on 5/12/15.
//
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "BLTLocation.h"
#import "BLTLocationHelpers.h"
#import "BLTLocationSegment.h"

@interface BLTLocationSegment ()

@property (nonatomic, readonly, assign) NSUInteger countOfCoordinates;
@property (nonatomic, readonly, copy) NSData *coordinateData;

- (CLLocationCoordinate2D)coordinateAtIndex:(NSUInteger)index;
- (CLLocationCoordinate2D)firstCoordinate;
- (CLLocationCoordinate2D)lastCoordinate;

@end

@implementation BLTLocationSegment
{
  NSUInteger _countOfCoordinates;
  NSData *_coordinateData;
  NSDate *_startDate;
  NSDate *_endDate;
  BLTLocationSegment *_firstSegment;
  BLTLocationSegment *_secondSegment;
}

- (instancetype)initWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
               countOfCoordinates:(NSUInteger)countOfCoordinates
                   coordinateData:(NSData *)coordinateData
{
  self = [super init];
  if (self != nil) {
    _startDate = startDate;
    _endDate = endDate;
    _countOfCoordinates = countOfCoordinates;
    _coordinateData = [coordinateData copy];
  }
  return self;
}

- (instancetype)initWithFirstSegment:(BLTLocationSegment *)firstSegment secondSegment:(BLTLocationSegment *)secondSegment
{
  self = [super init];
  if (self != nil) {
    _firstSegment = firstSegment;
    _secondSegment = secondSegment;
  }
  return self;
}

- (instancetype)initWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate locations:(NSArray *)locations
{
  NSData *coordinateData = [[self class] coordinateDataForLocations:locations];
  return [self initWithStartDate:startDate
                         endDate:endDate
              countOfCoordinates:locations.count
                  coordinateData:coordinateData];
}

- (instancetype)init
{
  @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:nil userInfo:nil];
  return [self initWithStartDate:nil endDate:nil locations:nil];
}

+ (instancetype)locationSegmentByMergingSegment:(BLTLocationSegment *)locationSegment
                                    withSegment:(BLTLocationSegment *)otherLocationSegment
{
  if (locationSegment == nil) {
    return otherLocationSegment;
  }
  if (otherLocationSegment == nil) {
    return locationSegment;
  }
  BLTLocationSegment *firstLocationSegment;
  BLTLocationSegment *secondLocationSegment;
  if ([locationSegment->_startDate timeIntervalSinceDate:otherLocationSegment->_startDate] > 0) {
    firstLocationSegment = otherLocationSegment;
    secondLocationSegment = locationSegment;
  } else {
    firstLocationSegment = locationSegment;
    secondLocationSegment = otherLocationSegment;
  }
  return [[self alloc] initWithFirstSegment:firstLocationSegment secondSegment:secondLocationSegment];
}

- (MKPolyline *)route
{
  return [MKPolyline polylineWithCoordinates:(void *)self.coordinateData.bytes count:self.countOfCoordinates];
}

+ (NSData *)coordinateDataForLocations:(NSArray *)locations
{
  NSMutableData *coordinateData = [[NSMutableData alloc] initWithLength:locations.count * sizeof(CLLocationCoordinate2D)];
  CLLocationCoordinate2D *coordinates = coordinateData.mutableBytes;
  NSUInteger i = 0;
  for (BLTLocation *managedLocation in locations) {
    CLLocation *location = [BLTLocationHelpers locationFromManagedLocation:managedLocation];
    coordinates[i] = location.coordinate;
    i++;
  }
  return coordinateData;
}

- (NSUInteger)countOfCoordinates
{
  if (_firstSegment != nil) {
    return _firstSegment.countOfCoordinates + _secondSegment.countOfCoordinates;
  } else {
    return _countOfCoordinates;
  }
}

- (NSData *)coordinateData
{
  if (_coordinateData != nil) {
    return _coordinateData;
  }
  NSMutableData *mutableData = [[NSMutableData alloc] initWithCapacity:self.countOfCoordinates * sizeof(CLLocationCoordinate2D)];
  NSUInteger offset = 0;
  [self _appendCoordinatesToBuffer:mutableData.mutableBytes offset:&offset];
  _coordinateData = mutableData;
  return _coordinateData;
}

- (void)_appendCoordinatesToBuffer:(CLLocationCoordinate2D *)buffer offset:(NSUInteger *)offset
{
  if (_firstSegment == nil) {
    // base case
    memcpy(buffer + *offset, _coordinateData.bytes, _countOfCoordinates * sizeof(CLLocationCoordinate2D));
    *offset += _countOfCoordinates;
  } else {
    [_firstSegment _appendCoordinatesToBuffer:buffer offset:offset];
    [_secondSegment _appendCoordinatesToBuffer:buffer offset:offset];
  }
}

- (NSDate *)startDate
{
  if (_firstSegment != nil) {
    return _firstSegment.startDate;
  } else {
    return _startDate;
  }
}

- (NSDate *)endDate
{
  if (_secondSegment != nil) {
    return _secondSegment.endDate;
  } else {
    return _endDate;
  }
}

- (CLLocationCoordinate2D)coordinateAtIndex:(NSUInteger)index
{
  if (_firstSegment != nil) {
    NSUInteger countOfCoordinatesInFirstSegment = _firstSegment.countOfCoordinates;
    if (index < countOfCoordinatesInFirstSegment) {
      return [_firstSegment coordinateAtIndex:index];
    } else {
      return [_secondSegment coordinateAtIndex:index - countOfCoordinatesInFirstSegment];
    }
  } else {
    if (index >= _countOfCoordinates) {
      @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"index out of range" userInfo:@{ @"index" : @(index), @"maxIndex": @(_countOfCoordinates) }];
    }
    const CLLocationCoordinate2D *rawCoordinates = [_coordinateData bytes];
    return rawCoordinates[index];
  }
}

- (CLLocationCoordinate2D)firstCoordinate
{
  return [self coordinateAtIndex:0];
}

- (CLLocationCoordinate2D)lastCoordinate
{
  return [self coordinateAtIndex:self.countOfCoordinates - 1];
}

- (NSTimeInterval)timeIntervalFromLocationSegment:(BLTLocationSegment *)otherSegment
{
  if (otherSegment == nil) {
    return DBL_MAX;
  }
  return [self.startDate timeIntervalSinceDate:otherSegment.endDate];
}

- (CLLocationDistance)distanceFromLocationSegment:(BLTLocationSegment *)otherSegment
{
  if (otherSegment == nil) {
    return CLLocationDistanceMax;
  }
  MKMapPoint firstMapPoint = MKMapPointForCoordinate([self firstCoordinate]);
  MKMapPoint lastMapPointFromOtherSegment = MKMapPointForCoordinate([otherSegment lastCoordinate]);
  return MKMetersBetweenMapPoints(firstMapPoint, lastMapPointFromOtherSegment);
}

#pragma mark NSObject

- (NSDictionary *)dictionaryRepresentation
{
  return @{
           @"start": _startDate,
           @"end": _endDate,
           @"count": @(self.countOfCoordinates),
           };
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"%@ %@", [super description], self.dictionaryRepresentation];
}

- (BOOL)isEqualToLocationSegment:(BLTLocationSegment *)locationSegment
{
  if (locationSegment == nil) {
    return NO;
  }
  return [_startDate isEqualToDate:locationSegment->_startDate] &&
    [_endDate isEqualToDate:locationSegment->_endDate] &&
    _countOfCoordinates == locationSegment->_countOfCoordinates &&
    [_coordinateData isEqualToData:locationSegment->_coordinateData];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if ([object isKindOfClass:[self class]]) {
    return [self isEqualToLocationSegment:object];
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
  self = [super init];
  if (self != nil) {
    _startDate = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"start"];
    _endDate = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"end"];
    _countOfCoordinates = [aDecoder decodeIntegerForKey:@"count"];
    _coordinateData = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"coordinates"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_startDate forKey:@"start"];
  [aCoder encodeObject:_endDate forKey:@"end"];
  [aCoder encodeInteger:_countOfCoordinates forKey:@"count"];
  [aCoder encodeObject:_coordinateData forKey:@"coordinates"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  return self;
}

@end
