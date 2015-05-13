//
//  BLTLocationSegment.h
//  
//
//  Created by Brian Dewey on 5/12/15.
//
//

#import <Foundation/Foundation.h>

@interface BLTLocationSegment : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, readonly, strong) NSDate *startDate;
@property (nonatomic, readonly, strong) NSDate *endDate;
@property (nonatomic, readonly, strong) MKPolyline *route;
@property (nonatomic, readonly, strong) NSDictionary *dictionaryRepresentation;

- (instancetype)initWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
               countOfCoordinates:(NSUInteger)countOfCoordinates
                   coordinateData:(NSData *)coordinateData NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
                        locations:(NSArray *)locations;

- (BOOL)isEqualToLocationSegment:(BLTLocationSegment *)locationSegment;

+ (NSData *)coordinateDataForLocations:(NSArray *)locations;

@end
