//
//  BLTLocationDataSummary.m
//  background-location-test
//
//  Created by Brian Dewey on 4/10/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import "BLTLocationDataSummary.h"

@implementation BLTLocationDataSummary

- (instancetype)initWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate countOfLocationObservations:(NSInteger)countOfLocationObservations
{
  self = [super init];
  if (self != nil) {
    _startDate = startDate;
    _endDate = endDate;
    _countOfLocationObservations = countOfLocationObservations;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  NSDate *startDate = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"start_date"];
  NSDate *endDate = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"end_date"];
  NSInteger count = [aDecoder decodeIntegerForKey:@"count"];
  return [self initWithStartDate:startDate endDate:endDate countOfLocationObservations:count];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_startDate forKey:@"start_date"];
  [aCoder encodeObject:_endDate forKey:@"end_date"];
  [aCoder encodeInteger:_countOfLocationObservations forKey:@"count"];
}

+ (BOOL)supportsSecureCoding
{
  return YES;
}

@end
