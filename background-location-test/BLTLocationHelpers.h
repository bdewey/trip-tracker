//
//  BLTLocationHelpers.h
//  background-location-test
//
//  Created by Brian Dewey on 4/15/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BLTLocation;
@class CLLocation;

@interface BLTLocationHelpers : NSObject

+ (CLLocation *)locationFromManagedLocation:(BLTLocation *)managedLocation;

@end

