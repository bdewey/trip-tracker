//
//  BLTTripTests.m
//  background-location-test
//
//  Created by Brian Dewey on 4/12/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "BLTTrip.h"

static BLTTrip *_TestTrip()
{
  NSDate *startDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
  NSDate *endDate = [NSDate dateWithTimeInterval:60*60 sinceDate:startDate];
  return [[BLTTrip alloc] initWithStartDate:startDate endDate:endDate locations:@[]];
}

@interface BLTTripTests : XCTestCase

@end

@implementation BLTTripTests

- (void)testSerialization
{
  BLTTrip *trip = _TestTrip();
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:trip];
  BLTTrip *unarchived = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  XCTAssertNotEqual(trip, unarchived);
  XCTAssertEqualObjects(trip, unarchived);
}

@end
