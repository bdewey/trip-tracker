//
//  BLTGridSummary.h
//  background-location-test
//
//  Created by Brian Dewey on 4/25/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface BLTGridSummary : NSObject

@property (nonatomic, readonly, assign) MKMapPoint mapPoint;
@property (nonatomic, readonly, strong) NSDate *dateEnteredGrid;
@property (nonatomic, readonly, strong) NSDate *dateLeftGrid;

// Calculated property
@property (nonatomic, readonly, assign) NSTimeInterval duration;

- (instancetype)initWithMapPoint:(MKMapPoint)mapPoint
                 dateEnteredGrid:(NSDate *)dateEnteredGrid
                    dateLeftGrid:(NSDate *)dateLeftGrid NS_DESIGNATED_INITIALIZER;

+ (MKMapPoint)bucketizedMapPointForCoordinate:(CLLocationCoordinate2D)coordinate
                            distancePerBucket:(CLLocationDistance)distancePerBucket;

@end
