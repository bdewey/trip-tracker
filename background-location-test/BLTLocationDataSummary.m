//
//  BLTLocationDataSummary.m
//  background-location-test
//
//  Created by Brian Dewey on 4/10/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import "BLTLocationDataSummary.h"

@implementation BLTLocationDataSummary

- (instancetype)initWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate countOfLocationObservations:(NSUInteger)countOfLocationObservations
{
  self = [super init];
  if (self != nil) {
    _startDate = startDate;
    _endDate = endDate;
    _countOfLocationObservations = countOfLocationObservations;
  }
  return self;
}

@end
