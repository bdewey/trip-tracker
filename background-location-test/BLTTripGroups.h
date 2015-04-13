//
//  BLTTripGroups.h
//  background-location-test
//
//  Created by Brian Dewey on 4/12/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BLTTrip;

@interface BLTTripGroups : NSObject <NSSecureCoding>

@property (nonatomic, readonly, assign) NSUInteger countOfTripGroups;

- (NSString *)nameOfTripGroup:(NSUInteger)indexOfTripGroup;
- (NSUInteger)countOfTripsInGroup:(NSUInteger)indexOfTripGroup;
- (BLTTrip *)tripForIndexPath:(NSIndexPath *)indexPath;

// BLTTripGroups is an immutable container. Right now it's an inefficient implementation.
- (BLTTripGroups *)tripGroupsByAddingTrip:(BLTTrip *)trip;

@end
