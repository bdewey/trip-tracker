//
//  BLTLocationSegment.m
//  
//
//  Created by Brian Dewey on 5/12/15.
//
//

#import <CoreLocation/CoreLocation.h>

#import "BLTLocation.h"
#import "BLTLocationHelpers.h"
#import "BLTLocationSegment.h"

@implementation BLTLocationSegment
{
  NSUInteger _countOfCoordinates;
  NSData *_coordinateData;
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

- (instancetype)initWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate locations:(NSArray *)locations
{
  NSData *coordinateData = [[self class] coordinateDataForLocations:locations];
  return [self initWithStartDate:startDate
                         endDate:endDate
              countOfCoordinates:locations.count
                  coordinateData:coordinateData];
}

- (MKPolyline *)route
{
  return [MKPolyline polylineWithCoordinates:(void *)_coordinateData.bytes count:_countOfCoordinates];
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

#pragma mark NSObject

- (NSDictionary *)dictionaryRepresentation
{
  return @{
           @"start": _startDate,
           @"end": _endDate,
           @"count": @(_countOfCoordinates),
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
