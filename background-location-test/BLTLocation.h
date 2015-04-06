//
//  BLTLocation.h
//  background-location-test
//
//  Created by Brian Dewey on 4/1/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface BLTLocation : NSManagedObject

@property (nonatomic, retain) id location;
@property (nonatomic, retain) NSDate * timestamp;

@end
