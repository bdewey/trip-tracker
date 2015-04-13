//
//  BLTTripGroups.m
//  background-location-test
//
//  Created by Brian Dewey on 4/12/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import "BLTTrip.h"
#import "BLTTripGroups.h"

static NSDateFormatter *_DateFormatter()
{
  static NSDateFormatter *dateFormatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
  });
  return dateFormatter;
}

@interface BLTTripGroups ()

- (instancetype)initWithTripGroupNames:(NSArray *)tripGroupNames tripGroups:(NSArray *)tripGroups NS_DESIGNATED_INITIALIZER;

@end

@implementation BLTTripGroups
{
  NSArray *_tripGroupNames;
  NSArray *_tripGroups;
}

- (instancetype)initWithTripGroupNames:(NSArray *)tripGroupNames tripGroups:(NSArray *)tripGroups
{
  self = [super init];
  if (self != nil) {
    NSAssert(_tripGroupNames.count == _tripGroups.count, @"Parallel array counts must match");
    _tripGroupNames = tripGroupNames;
    _tripGroups = tripGroups;
  }
  return self;
}

- (instancetype)init
{
  return [self initWithTripGroupNames:@[] tripGroups:@[]];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  NSArray *tripGroupNames = [aDecoder decodeObjectOfClass:[NSArray class] forKey:@"tripGroupNames"];
  NSArray *tripGroups = [aDecoder decodeObjectOfClass:[NSArray class] forKey:@"tripGroups"];
  return [self initWithTripGroupNames:tripGroupNames tripGroups:tripGroups];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_tripGroupNames forKey:@"tripGroupNames"];
  [aCoder encodeObject:_tripGroups forKey:@"tripGroups"];
}

- (NSUInteger)countOfTripGroups
{
  return _tripGroupNames.count;
}

- (NSString *)nameOfTripGroup:(NSUInteger)indexOfTripGroup;
{
  return _tripGroupNames[indexOfTripGroup];
}

- (NSUInteger)countOfTripsInGroup:(NSUInteger)indexOfTripGroup;
{
  NSArray *tripsInTripGroup = _tripGroups[indexOfTripGroup];
  return tripsInTripGroup.count;
}

- (BLTTrip *)tripForIndexPath:(NSIndexPath *)indexPath;
{
  NSArray *tripsInTripGroup = _tripGroups[[indexPath indexAtPosition:0]];
  return tripsInTripGroup[[indexPath indexAtPosition:1]];
}

- (BLTTripGroups *)tripGroupsByAddingTrip:(BLTTrip *)trip;
{
  NSArray *newGroupNames = _tripGroupNames;
  NSArray *newGroups = _tripGroups;
  NSString *groupNameForNewTrip = [_DateFormatter() stringFromDate:trip.startDate];
  NSUInteger indexOfGroupName = [_tripGroupNames indexOfObject:groupNameForNewTrip];
  if (indexOfGroupName == NSNotFound) {
    newGroupNames = [newGroupNames arrayByAddingObject:groupNameForNewTrip];
    newGroups = [newGroups arrayByAddingObject:@[]];
    indexOfGroupName = newGroupNames.count - 1;
  }
  NSArray *groupToAppend = newGroups[indexOfGroupName];
  groupToAppend = [groupToAppend arrayByAddingObject:trip];
  
  __unsafe_unretained id *rawGroups = (__unsafe_unretained id *)calloc(newGroups.count, sizeof(id));
  [newGroups getObjects:rawGroups];
  rawGroups[indexOfGroupName] = groupToAppend;
  newGroups = [NSArray arrayWithObjects:rawGroups count:newGroups.count];
  free(rawGroups);
  return [[BLTTripGroups alloc] initWithTripGroupNames:newGroupNames tripGroups:newGroups];
}

@end
