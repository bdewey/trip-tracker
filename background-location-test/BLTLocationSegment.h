//
//  BLTLocationSegment.h
//  
//
//  Created by Brian Dewey on 5/12/15.
//
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

@class MKPolyline;

@interface BLTLocationSegment : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, readonly, strong) NSDate *startDate;
@property (nonatomic, readonly, strong) NSDate *endDate;
@property (nonatomic, readonly, strong) MKPolyline *route;
@property (nonatomic, readonly, strong) NSDictionary *dictionaryRepresentation;

- (instancetype)initWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
               countOfCoordinates:(NSUInteger)countOfCoordinates
                   coordinateData:(NSData *)coordinateData NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFirstSegment:(BLTLocationSegment *)firstSegment
                       secondSegment:(BLTLocationSegment *)secondSegment NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;
+ (instancetype)locationSegmentByMergingSegment:(BLTLocationSegment *)locationSegment
                                    withSegment:(BLTLocationSegment *)otherLocationSegment;

/**
 Convenience initializer that works with an array of BLTLocation objects.
 */
- (instancetype)initWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
                        locations:(NSArray *)locations;

- (BOOL)isEqualToLocationSegment:(BLTLocationSegment *)locationSegment;

- (NSTimeInterval)timeIntervalFromLocationSegment:(BLTLocationSegment *)otherSegment;
- (CLLocationDistance)distanceFromLocationSegment:(BLTLocationSegment *)otherSegment;

+ (NSData *)coordinateDataForLocations:(NSArray *)locations;

@end
