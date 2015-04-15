//
//  BLTLocation.h
//  background-location-test
//
//  Created by Brian Dewey on 4/15/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface BLTLocation : NSManagedObject

@property (nonatomic) double altitude;
@property (nonatomic) double course;
@property (nonatomic) double distanceFromLastLocation;
@property (nonatomic) double horizontalAccuracy;
@property (nonatomic) double interpolatedSpeed;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) double speed;
@property (nonatomic) double timeIntervalFromLastLocation;
@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic) double verticalAccuracy;

@end
