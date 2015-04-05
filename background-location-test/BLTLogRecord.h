//
//  BLTLogRecord.h
//  background-location-test
//
//  Created by Brian Dewey on 4/5/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface BLTLogRecord : NSManagedObject

@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSDate * timestamp;

@end
