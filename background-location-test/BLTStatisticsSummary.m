//
//  BLTStatisticsSummary.m
//  background-location-test
//
//  Created by Brian Dewey on 4/11/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import "BLTStatisticsSummary.h"

@implementation BLTStatisticsSummary
{
  double _sum;
  double _m;
  double _s;
}

- (instancetype)init
{
  self = [super init];
  if (self != nil) {
    _min = DBL_MAX;
    _max = -DBL_MAX;
  }
  return self;
}

- (void)addObservation:(double)observation
{
  // standard deviation math comes from http://www.johndcook.com/blog/standard_deviation/
  _count++;
  _sum += observation;
  _min = MIN(_min, observation);
  _max = MAX(_max, observation);
  if (_count == 1) {
    _m = observation;
    _s = 0;
  } else {
    double oldM = _m;
    _m = oldM + (observation - oldM) / _count;
    _s = _s + (observation - oldM) * (observation - _m);
  }
}

- (double)mean
{
  return _sum / _count;
}

- (double)variance
{
  if (_count >= 2) {
    return _s / (_count - 1);
  } else {
    return 0;
  }
}

- (double)standardDeviation
{
  return sqrt(self.variance);
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"%@ n = %tu mean = %f min = %f max = %f", [super description], _count, self.mean, self.min, self.max];
}

@end
