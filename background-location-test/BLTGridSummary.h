//
//  BLTGridSummary.h
//  background-location-test
//
//  Created by Brian Dewey on 4/25/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface BLTGridSummary : NSObject <NSSecureCoding>

@property (nonatomic, readonly, assign) MKMapPoint mapPoint;
@property (nonatomic, readonly, assign) CLLocationDistance horizontalAccuracy;
@property (nonatomic, readonly, strong) NSDate *dateEnteredGrid;
@property (nonatomic, readonly, strong) NSDate *dateLeftGrid;

// Calculated property
@property (nonatomic, readonly, assign) NSTimeInterval duration;

- (instancetype)initWithMapPoint:(MKMapPoint)mapPoint
              horizontalAccuracy:(CLLocationDistance)horizontalAccuracy
                 dateEnteredGrid:(NSDate *)dateEnteredGrid
                    dateLeftGrid:(NSDate *)dateLeftGrid NS_DESIGNATED_INITIALIZER;

- (instancetype)gridSummaryByMergingSummary:(BLTGridSummary *)otherSummary;
- (NSTimeInterval)timeIntervalSinceSummary:(BLTGridSummary *)otherSummary;
- (CLLocationDistance)distanceFromSummary:(BLTGridSummary *)otherSummary;
+ (MKMapPoint)bucketizedMapPointForCoordinate:(CLLocationCoordinate2D)coordinate
                            distancePerBucket:(CLLocationDistance)distancePerBucket;

@end
