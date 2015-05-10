//
//  BLTTripGroupsTests.m
//  background-location-test
//
//  Created by Brian Dewey on 4/12/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "BLTTrip.h"
#import "BLTGroupedItems.h"

static BLTTrip *_TestTrip()
{
  NSDate *startDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
  NSDate *endDate = [NSDate dateWithTimeInterval:60*60 sinceDate:startDate];
  return [[BLTTrip alloc] initWithStartDate:startDate endDate:endDate locations:@[]];
}

@interface BLTTripGroupsTests : XCTestCase

@end

@implementation BLTTripGroupsTests

- (void)testEmpty
{
  BLTGroupedItems *tripGroups = [[BLTGroupedItems alloc] init];
  XCTAssertEqual(0, tripGroups.countOfGroups);
}

- (void)testAddOne
{
  BLTGroupedItems *tripGroups = [[BLTGroupedItems alloc] init];
  BLTTrip *trip = _TestTrip();
  tripGroups = [tripGroups groupedItemsByAddingItem:trip];
  XCTAssertEqual(1, tripGroups.countOfGroups);
  XCTAssertEqualObjects(@"12/31/69", [tripGroups nameOfGroup:0]);
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
  XCTAssertEqual(trip, [tripGroups itemForIndexPath:indexPath]);
}

@end
