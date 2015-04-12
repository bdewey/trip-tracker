//
//  BLTVisit.h
//  
//
//  Created by Brian Dewey on 4/11/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface BLTVisit : NSManagedObject

@property (nonatomic, retain) NSDate * arrivalDate;
@property (nonatomic, retain) NSDate * departureDate;
@property (nonatomic, retain) id visit;
@property (nonatomic, retain) NSDate * timestamp;

@end
