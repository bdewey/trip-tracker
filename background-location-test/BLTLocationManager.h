//
//  BLTLocationManager.h
//  background-location-test
//
//  Created by Brian Dewey on 4/1/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class BLTDatabase;
@class BLTGroupedItems;
@protocol BLTGroupedItemsDelegate;
@protocol BLTPlaceDetectionStrategy;
@class CLLocationManager;
@class NSManagedObjectContext;

typedef void (^BLTTripBuilderCallback)(BLTGroupedItems *tripGroups);
typedef void (^BLTLocationSummaryBuilderCallback)(NSArray *locationSummaries);
typedef void (^BLTPlaceVisitBuilderCallback)(NSArray *placeVisits);

@protocol BLTLocationManagerDelegate;

@interface BLTLocationManager : NSObject

@property (nonatomic, readonly, strong) CLLocationManager *locationManager;
@property (nonatomic, readonly, strong) BLTDatabase *database;
@property (nonatomic, readonly, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, weak) id<BLTLocationManagerDelegate> delegate;
@property (nonatomic, readonly, assign, getter=isRecordingLocationHistory) BOOL recordingLocationHistory;
@property (nonatomic, readonly, assign, getter=isRecordingVisits) BOOL recordingVisits;

+ (BLTLocationManager *)sharedLocationManager;
+ (void)setSharedLocationManager:(BLTLocationManager *)locationManager;

- (instancetype)initWithDatabase:(BLTDatabase *)database NS_DESIGNATED_INITIALIZER;

- (void)startRecordingLocationHistory;
- (void)stopRecordingLocationHistory;

- (void)startRecordingVisits;
- (void)stopRecordingVisits;

- (void)updateDatabaseWithMotionActivities;

- (void)buildTripsWithGroupedItemsDelegate:(id<BLTGroupedItemsDelegate>)delegate callback:(BLTTripBuilderCallback)callback;
- (void)buildLocationSummaries:(BLTLocationSummaryBuilderCallback)callback;

- (void)buildPlaceVisitsFromStartDate:(NSDate *)startDate
                              endDate:(NSDate *)endDate
                        usingStrategy:(id<BLTPlaceDetectionStrategy>)strategy
                             callback:(BLTPlaceVisitBuilderCallback)callback;

@end

@protocol BLTLocationManagerDelegate <NSObject>

- (void)bltLocationManagerDidFailAuthorization:(BLTLocationManager *)locationManager;

@end
