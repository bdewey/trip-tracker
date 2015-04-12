//
//  BLTStatisticsSummaryTests.m
//  background-location-test
//
//  Created by Brian Dewey on 4/11/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "BLTStatisticsSummary.h"

@interface BLTStatisticsSummaryTests : XCTestCase

@end

@implementation BLTStatisticsSummaryTests

- (void)testSimpleMath
{
  BLTStatisticsSummary *summary = [[BLTStatisticsSummary alloc] init];
  for (int i = 0; i < 5; i++) {
    [summary addObservation:i+1];
  }
  XCTAssertEqual(1, summary.min);
  XCTAssertEqual(5, summary.max);
  XCTAssertEqual(5, summary.count);
  XCTAssertEqualWithAccuracy(3.0, summary.mean, 0.001);
  XCTAssertEqualWithAccuracy(2.5, summary.variance, 0.01);
  XCTAssertEqualWithAccuracy(1.58, summary.standardDeviation, 0.01);
}

@end
