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
#import "BLTTripGroups.h"

static BLTTrip *_TestTrip()
{
  NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:0];
  NSDate *endDate = [NSDate dateWithTimeInterval:60*60 sinceDate:startDate];
  return [[BLTTrip alloc] initWithStartDate:startDate endDate:endDate locations:@[]];
}

@interface BLTTripGroupsTests : XCTestCase

@end

@implementation BLTTripGroupsTests

- (void)testEmpty
{
  BLTTripGroups *tripGroups = [[BLTTripGroups alloc] init];
  XCTAssertEqual(0, tripGroups.countOfTripGroups);
}

- (void)testAddOne
{
  BLTTripGroups *tripGroups = [[BLTTripGroups alloc] init];
  BLTTrip *trip = _TestTrip();
  tripGroups = [tripGroups tripGroupsByAddingTrip:trip];
  XCTAssertEqual(1, tripGroups.countOfTripGroups);
  XCTAssertEqualObjects(@"12/31/69", [tripGroups nameOfTripGroup:0]);
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
  XCTAssertEqual(trip, [tripGroups tripForIndexPath:indexPath]);
}

@end
