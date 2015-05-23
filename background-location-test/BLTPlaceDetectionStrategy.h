//
//  BLTPlaceDetectionStrategy.h
//  background-location-test
//
//  Created by Brian Dewey on 5/13/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BLTLocation;

@protocol BLTPlaceDetectionStrategy <NSObject>

@property (nonatomic, readonly, copy) NSArray *placeVisits;

- (void)addLocation:(BLTLocation *)location;

@end