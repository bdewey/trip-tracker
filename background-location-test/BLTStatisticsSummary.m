//
//  BLTStatisticsSummary.m
//  background-location-test
//
//  Created by Brian Dewey on 4/11/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import "BLTStatisticsSummary.h"

static BOOL _DoubleAreEqual(double x, double y)
{
  static const double epsilon = 0.0000001;
  return fabs(x - y) < epsilon;
}

@interface BLTStatisticsSummary ()

- (instancetype)initWithMin:(double)min
                        max:(double)max
                      count:(NSInteger)count
                        sum:(double)sum
                          m:(double)m
                          s:(double)s NS_DESIGNATED_INITIALIZER;

@end

@implementation BLTStatisticsSummary
{
  double _sum;
  double _m;
  double _s;
}

- (instancetype)initWithMin:(double)min max:(double)max count:(NSInteger)count sum:(double)sum m:(double)m s:(double)s
{
  self = [super init];
  if (self != nil) {
    _min = min;
    _max = max;
    _count = count;
    _sum = sum;
    _m = m;
    _s = s;
  }
  return self;
}

- (instancetype)init
{
  return [self initWithMin:DBL_MAX max:-DBL_MAX count:0 sum:0 m:0 s:0];
}

- (BOOL)isEqualToStatisticsSummary:(BLTStatisticsSummary *)summary
{
  return _DoubleAreEqual(_min, summary->_min) &&
  _DoubleAreEqual(_max, summary->_max) &&
  _count == summary->_count &&
  _DoubleAreEqual(_sum, summary->_sum) &&
  _DoubleAreEqual(_m, summary->_m) &&
  _DoubleAreEqual(_s, summary->_s);
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if ([object isKindOfClass:[self class]]) {
    return [self isEqualToStatisticsSummary:object];
  }
  return NO;
}

- (NSUInteger)hash
{
  NSData *encoded = [NSKeyedArchiver archivedDataWithRootObject:self];
  return encoded.hash;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  return [[BLTStatisticsSummary alloc] initWithMin:_min
                                               max:_max
                                             count:_count
                                               sum:_sum
                                                 m:_m
                                                 s:_s];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  return [self initWithMin:[aDecoder decodeDoubleForKey:@"min"]
                       max:[aDecoder decodeDoubleForKey:@"max"]
                     count:[aDecoder decodeIntegerForKey:@"count"]
                       sum:[aDecoder decodeDoubleForKey:@"sum"]
                         m:[aDecoder decodeDoubleForKey:@"m"]
                         s:[aDecoder decodeDoubleForKey:@"s"]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeDouble:_min forKey:@"min"];
  [aCoder encodeDouble:_max forKey:@"max"];
  [aCoder encodeInteger:_count forKey:@"count"];
  [aCoder encodeDouble:_sum forKey:@"sum"];
  [aCoder encodeDouble:_m forKey:@"m"];
  [aCoder encodeDouble:_s forKey:@"s"];
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
