//
//  BLTStatisticsSummary.h
//  background-location-test
//
//  Created by Brian Dewey on 4/11/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLTStatisticsSummary : NSObject

@property (nonatomic, readonly, assign) double min;
@property (nonatomic, readonly, assign) double max;
@property (nonatomic, readonly, assign) double mean;
@property (nonatomic, readonly, assign) double variance;
@property (nonatomic, readonly, assign) double standardDeviation;
@property (nonatomic, readonly, assign) NSUInteger count;

- (void)addObservation:(double)observation;

@end
