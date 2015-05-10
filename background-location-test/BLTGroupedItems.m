//
//  BLTTripGroups.m
//  background-location-test
//
//  Created by Brian Dewey on 4/12/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import "BLTFormattingHelpers.h"
#import "BLTTrip.h"
#import "BLTGroupedItems.h"

@interface BLTGroupedItems ()

- (instancetype)initWithTripGroupNames:(NSArray *)tripGroupNames
                            tripGroups:(NSArray *)tripGroups
                              delegate:(id<BLTGroupedItemsDelegate>)delegate NS_DESIGNATED_INITIALIZER;

@end

@implementation BLTGroupedItems
{
  NSArray *_tripGroupNames;
  NSArray *_tripGroups;
}

- (instancetype)initWithTripGroupNames:(NSArray *)tripGroupNames
                            tripGroups:(NSArray *)tripGroups
                              delegate:(id<BLTGroupedItemsDelegate>)delegate
{
  self = [super init];
  if (self != nil) {
    NSAssert(_tripGroupNames.count == _tripGroups.count, @"Parallel array counts must match");
    _tripGroupNames = tripGroupNames;
    _tripGroups = tripGroups;
    _delegate = delegate;
  }
  return self;
}

- (instancetype)initWithDelegate:(id<BLTGroupedItemsDelegate>)delegate
{
  return [self initWithTripGroupNames:@[] tripGroups:@[] delegate:delegate];
}

- (NSString *)description
{
  NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
  for (NSUInteger i = 0; i < _tripGroupNames.count; i++) {
    properties[_tripGroupNames[i]] = _tripGroups[i];
  }
  return [NSString stringWithFormat:@"%@ %@", [super description], properties];
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
  return [self initWithTripGroupNames:tripGroupNames tripGroups:tripGroups delegate:nil];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_tripGroupNames forKey:@"tripGroupNames"];
  [aCoder encodeObject:_tripGroups forKey:@"tripGroups"];
}

- (NSUInteger)countOfGroups
{
  return _tripGroupNames.count;
}

- (NSString *)nameOfGroup:(NSUInteger)indexOfTripGroup;
{
  if ([self.delegate groupedItemsDisplayInReversedOrder:self]) {
    return _tripGroupNames[_tripGroupNames.count - indexOfTripGroup - 1];
  } else {
    return _tripGroupNames[indexOfTripGroup];
  }
}

- (NSUInteger)countOfItemsInGroup:(NSUInteger)indexOfTripGroup;
{
  if ([self.delegate groupedItemsDisplayInReversedOrder:self]) {
    indexOfTripGroup = _tripGroups.count - indexOfTripGroup - 1;
  }
  NSArray *tripsInTripGroup = _tripGroups[indexOfTripGroup];
  return tripsInTripGroup.count;
}

- (BLTTrip *)itemForIndexPath:(NSIndexPath *)indexPath;
{
  BOOL reversed = [self.delegate groupedItemsDisplayInReversedOrder:self];
  NSUInteger groupIndex = reversed ? (_tripGroups.count - [indexPath indexAtPosition:0] - 1) : [indexPath indexAtPosition:0];
  NSArray *tripsInTripGroup = _tripGroups[groupIndex];
  NSUInteger itemIndex  = reversed ? (tripsInTripGroup.count - [indexPath indexAtPosition:1] - 1) : [indexPath indexAtPosition:1];
  return tripsInTripGroup[itemIndex];
}

- (BLTGroupedItems *)groupedItemsByAddingItem:(id<NSSecureCoding>)item
{
  NSArray *newGroupNames = _tripGroupNames;
  NSArray *newGroups = _tripGroups;
  NSString *groupNameForNewTrip = [self.delegate groupedItems:self nameOfGroupForItem:item];
  NSUInteger indexOfGroupName = [_tripGroupNames indexOfObject:groupNameForNewTrip];
  if (indexOfGroupName == NSNotFound) {
    newGroupNames = [newGroupNames arrayByAddingObject:groupNameForNewTrip];
    newGroups = [newGroups arrayByAddingObject:@[]];
    indexOfGroupName = newGroupNames.count - 1;
  }
  NSArray *groupToAppend = newGroups[indexOfGroupName];
  groupToAppend = [groupToAppend arrayByAddingObject:item];
  
  __unsafe_unretained id *rawGroups = (__unsafe_unretained id *)calloc(newGroups.count, sizeof(id));
  [newGroups getObjects:rawGroups];
  rawGroups[indexOfGroupName] = groupToAppend;
  newGroups = [NSArray arrayWithObjects:rawGroups count:newGroups.count];
  free(rawGroups);
  return [[BLTGroupedItems alloc] initWithTripGroupNames:newGroupNames tripGroups:newGroups delegate:_delegate];
}

@end
