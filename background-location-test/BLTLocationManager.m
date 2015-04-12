//
//  BLTLocationManager.m
//  background-location-test
//
//  Created by Brian Dewey on 4/1/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

#import "BLTDatabase.h"
#import "BLTLocation.h"
#import "BLTLocationDataSummary.h"
#import "BLTLocationManager.h"
#import "BLTLocationSlidingWindow.h"
#import "BLTTrip.h"
#import "BLTTripGroups.h"
#import "BLTVisit.h"

const BOOL kDebugNotificationsEnabled = YES;
static BOOL DisableLocationMonitoringWhenStationary = NO;

static BLTLocationManager *g_sharedLocationManager;

@interface BLTLocationManager () <CLLocationManagerDelegate>

@end

@implementation BLTLocationManager
{
  NSMutableArray *_blocksToPerformWhenAuthorized;
  BOOL _isDeferringUpdates;
}

- (instancetype)initWithDatabase:(BLTDatabase *)database
{
  self = [super init];
  if (self != nil) {
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.activityType = CLActivityTypeOther;
    _locationManager.pausesLocationUpdatesAutomatically = NO;
    _locationManager.delegate = self;
    _database = database;
    _managedObjectContext = [_database newPrivateQueueManagedObjectContextWithName:@"location monitoring"];
    _blocksToPerformWhenAuthorized = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc
{
  _locationManager.delegate = nil;
}

+ (BLTLocationManager *)sharedLocationManager
{
  return g_sharedLocationManager;
}

+ (void)setSharedLocationManager:(BLTLocationManager *)locationManager
{
  g_sharedLocationManager = locationManager;
}

- (void)startRecordingLocationHistory
{
  [_database logMessage:@"startRecordingLocationHistory" displayAsNotification:NO];
  [self _performBlockWhenAuthorized:^{
    NSAssert([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways,
             @"Should be authorized if we get here");
    _recordingLocationHistory = YES;
    [_locationManager startUpdatingLocation];
  }];
}

- (void)stopRecordingLocationHistory
{
  [_database logMessage:@"stopRecordingLocationHistory" displayAsNotification:NO];
  [_locationManager stopUpdatingLocation];
  _recordingLocationHistory = NO;
}

- (void)startRecordingVisits
{
  [self _performBlockWhenAuthorized:^{
    [_locationManager startMonitoringVisits];
    _recordingVisits = YES;
  }];
}

- (void)stopRecordingVisits
{
  [_locationManager stopMonitoringVisits];
  _recordingVisits = NO;
}

- (void)buildTrips:(BLTTripBuilderCallback)callback
{
  static const NSTimeInterval kSlidingWindowDuration = 2 * 60;
  static const NSTimeInterval kCoalesceTripInterval = 2 * 60;
  static const CLLocationSpeed kMinimumAverageMovingSpeed = 1.0;
  static const CLLocationDistance kMinimumWindowTripDistance = kMinimumAverageMovingSpeed * kSlidingWindowDuration;
  if (callback == NULL) {
    return;
  }
  [_managedObjectContext performBlock:^{
    BLTLocationSlidingWindow *slidingWindow = [[BLTLocationSlidingWindow alloc] initWithDesiredTimeInterval:kSlidingWindowDuration];
    BLTTripGroups *tripGroups = [[BLTTripGroups alloc] init];
    NSFetchRequest *locationFetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"BLTLocation"];
    NSSortDescriptor *sortByTimestamp = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
    locationFetchRequest.sortDescriptors = @[sortByTimestamp];
    NSArray *locations = [_managedObjectContext executeFetchRequest:locationFetchRequest error:NULL];
    NSUInteger startTripIndex = NSNotFound;
    BLTLocation *startingManagedLocation = nil;
    NSUInteger potentialEndTripIndex = NSNotFound;
    BLTLocation *potentialEndManagedLocation = nil;
    for (NSUInteger i = 0; i < locations.count; i++) {
      BLTLocation *managedLocation = locations[i];
      [slidingWindow addLocation:managedLocation.location];
      
      if (startTripIndex == NSNotFound) {
        // Still looking for a potential start to a trip. Is this it?
        if (slidingWindow.actualTimeInterval >= kSlidingWindowDuration && slidingWindow.distance >= kMinimumWindowTripDistance) {
          // We've started a trip. Remember the start location.
          startTripIndex = i;
          startingManagedLocation = managedLocation;
        }
      } else {
        // We're in a trip. See if it looks like we've stopped.
        if (slidingWindow.distance >= kMinimumWindowTripDistance) {
          // Definitely haven't stopped. If we had a potential end, get rid of it.
          potentialEndTripIndex = NSNotFound;
          potentialEndManagedLocation = nil;
        } else if (potentialEndTripIndex == NSNotFound) {
          // This is the first potential endpoint.
          potentialEndTripIndex = i;
          potentialEndManagedLocation = managedLocation;
        } else if ([managedLocation.timestamp timeIntervalSinceDate:potentialEndManagedLocation.timestamp] > kCoalesceTripInterval) {
          // We've gone sufficient time since we've been moving. Declare this an official trip.
          NSArray *slice = [locations subarrayWithRange:NSMakeRange(startTripIndex, potentialEndTripIndex - startTripIndex)];
          BLTTrip *trip = [[BLTTrip alloc] initWithStartDate:startingManagedLocation.timestamp endDate:potentialEndManagedLocation.timestamp locations:slice];
          tripGroups = [tripGroups tripGroupsByAddingTrip:trip];
          startTripIndex = NSNotFound;
          startingManagedLocation = nil;
          potentialEndTripIndex = NSNotFound;
          potentialEndManagedLocation = nil;
        }
      }
    }
    if (startTripIndex != NSNotFound) {
      NSArray *slice = [locations subarrayWithRange:NSMakeRange(startTripIndex, locations.count - startTripIndex)];
      BLTLocation *lastManagedLocation = locations.lastObject;
      BLTTrip *trip = [[BLTTrip alloc] initWithStartDate:startingManagedLocation.timestamp endDate:lastManagedLocation.timestamp locations:slice];
      tripGroups = [tripGroups tripGroupsByAddingTrip:trip];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      callback(tripGroups);
    });
  }];
}

- (void)buildLocationSummaries:(BLTLocationSummaryBuilderCallback)callback
{
  static const NSTimeInterval kTenSeconds = 10.0;
  if (callback == NULL) {
    return;
  }
  [_managedObjectContext performBlock:^{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"BLTLocation"];
    NSSortDescriptor *sortByTimestamp = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
    fetchRequest.sortDescriptors = @[sortByTimestamp];
    NSArray *locations = [_managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    NSMutableArray *locationSummaries = [[NSMutableArray alloc] init];
    BLTLocation *firstSummarizedLocation = nil;
    BLTLocation *lastSummarizedLocation = nil;
    NSUInteger countOfSummarizedLocations = 0;
    for (BLTLocation *managedLocation in locations) {
      NSTimeInterval delta = [lastSummarizedLocation.timestamp timeIntervalSinceDate:managedLocation.timestamp] * -1.0;
      if (delta > kTenSeconds) {
        BLTLocationDataSummary *summary = [[BLTLocationDataSummary alloc] initWithStartDate:firstSummarizedLocation.timestamp endDate:lastSummarizedLocation.timestamp countOfLocationObservations:countOfSummarizedLocations];
        [locationSummaries addObject:summary];
        firstSummarizedLocation = lastSummarizedLocation = nil;
        countOfSummarizedLocations = 0;
      }
      firstSummarizedLocation = firstSummarizedLocation ?: managedLocation;
      lastSummarizedLocation = managedLocation;
      countOfSummarizedLocations++;
    }
    BLTLocationDataSummary *summary = [[BLTLocationDataSummary alloc] initWithStartDate:firstSummarizedLocation.timestamp endDate:lastSummarizedLocation.timestamp countOfLocationObservations:countOfSummarizedLocations];
    [locationSummaries addObject:summary];
    dispatch_async(dispatch_get_main_queue(), ^{
      callback(locationSummaries);
    });
  }];
}

- (void)_performBlockWhenAuthorized:(dispatch_block_t)block
{
  if (block == NULL) {
    return;
  }
  CLAuthorizationStatus currentAuthorizationStatus = [CLLocationManager authorizationStatus];
  if (currentAuthorizationStatus == kCLAuthorizationStatusDenied || currentAuthorizationStatus == kCLAuthorizationStatusRestricted) {
    [self.delegate bltLocationManagerDidFailAuthorization:self];
    return;
  }
  if (currentAuthorizationStatus != kCLAuthorizationStatusAuthorizedAlways) {
    [_blocksToPerformWhenAuthorized addObject:block];
    [_locationManager requestAlwaysAuthorization];
  } else {
    block();
  }
}

#pragma mark - CLLocationManagerDelegate

- (void)      locationManager:(CLLocationManager *)manager
 didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
  if (status == kCLAuthorizationStatusAuthorizedAlways) {
    for (dispatch_block_t block in _blocksToPerformWhenAuthorized) {
      block();
    }
    [_blocksToPerformWhenAuthorized removeAllObjects];
  } else {
    [self.delegate bltLocationManagerDidFailAuthorization:self];
  }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
  [_database logMessage:[NSString stringWithFormat:@"locationManager:didFailWithError: %@", error] displayAsNotification:YES];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
  if (!_recordingLocationHistory) {
    return;
  }
  if (!_isDeferringUpdates) {
    [_database logMessage:@"Asking for deferred updates" displayAsNotification:NO];
    [_locationManager allowDeferredLocationUpdatesUntilTraveled:CLLocationDistanceMax timeout:CLTimeIntervalMax];
    _isDeferringUpdates = YES;
  }
  [_managedObjectContext performBlock:^{
    for (CLLocation *location in locations) {
      BLTLocation *locationObject = [NSEntityDescription insertNewObjectForEntityForName:@"BLTLocation" inManagedObjectContext:_managedObjectContext];
      locationObject.location = location;
      locationObject.timestamp = location.timestamp;
    }
    [_managedObjectContext save:NULL];
  }];
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error
{
  [_database logMessage:[NSString stringWithFormat:@"Finished deferred updates. Error = %@", error]
  displayAsNotification:(kDebugNotificationsEnabled && error != nil)];
  _isDeferringUpdates = NO;
}

- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit
{
  if (!_recordingVisits) {
    [_database logMessage:[NSString stringWithFormat:@"Got visit but not recording: %@", visit] displayAsNotification:kDebugNotificationsEnabled];
    return;
  }
  if (DisableLocationMonitoringWhenStationary) {
    if (visit.departureDate == [NSDate distantFuture]) {
      [_database logMessage:@"Arrived. Turning off location monitoring." displayAsNotification:kDebugNotificationsEnabled];
      [self stopRecordingLocationHistory];
    } else {
      [_database logMessage:@"Departed. Monitoring location." displayAsNotification:kDebugNotificationsEnabled];
      [self startRecordingLocationHistory];
    }
  }
  [_managedObjectContext performBlock:^{
    BLTVisit *visitObject = [NSEntityDescription insertNewObjectForEntityForName:@"BLTVisit" inManagedObjectContext:_managedObjectContext];
    if (visitObject == nil) {
      [_database logMessage:@"visitObject is nil. WTF?" displayAsNotification:kDebugNotificationsEnabled];
    } else {
      visitObject.visit = visit;
      visitObject.arrivalDate = visit.arrivalDate;
      visitObject.departureDate = visit.departureDate;
      visitObject.timestamp = [NSDate date];
      NSError *error;
      BOOL didSave = [_managedObjectContext save:&error];
      NSString *notificationMessage = [NSString stringWithFormat:@"Visit %@ save %d", visit, didSave];
      [_database logMessage:notificationMessage displayAsNotification:kDebugNotificationsEnabled];
    }
  }];
}

@end
