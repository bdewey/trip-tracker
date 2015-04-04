//
//  BLTLocationManager.h
//  background-location-test
//
//  Created by Brian Dewey on 4/1/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocationManager;
@class NSManagedObjectContext;

@protocol BLTLocationManagerDelegate;

@interface BLTLocationManager : NSObject

@property (nonatomic, readonly, strong) CLLocationManager *locationManager;
@property (nonatomic, readonly, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, weak) id<BLTLocationManagerDelegate> delegate;
@property (nonatomic, readonly, assign, getter=isRecordingLocationHistory) BOOL recordingLocationHistory;
@property (nonatomic, readonly, assign, getter=isRecordingVisits) BOOL recordingVisits;

- (instancetype)initWithLocationManager:(CLLocationManager *)locationManager
                   managedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_DESIGNATED_INITIALIZER;

- (void)startRecordingLocationHistory;
- (void)stopRecordingLocationHistory;

- (void)startRecordingVisits;
- (void)stopRecordingVisits;

@end

@protocol BLTLocationManagerDelegate <NSObject>

- (void)bltLocationManagerDidFailAuthorization:(BLTLocationManager *)locationManager;

@end
