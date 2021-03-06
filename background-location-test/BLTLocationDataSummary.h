//
//  BLTLocationDataSummary.h
//  background-location-test
//
//  Created by Brian Dewey on 4/10/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLTLocationDataSummary : NSObject <NSSecureCoding>

@property (nonatomic, readonly, strong) NSDate *startDate;
@property (nonatomic, readonly, strong) NSDate *endDate;
@property (nonatomic, readonly, assign) NSInteger countOfLocationObservations;

- (instancetype)initWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
      countOfLocationObservations:(NSInteger)countOfLocationObservations NS_DESIGNATED_INITIALIZER;

@end
