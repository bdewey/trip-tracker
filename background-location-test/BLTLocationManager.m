//
//  BLTLocationManager.m
//  background-location-test
//
//  Created by Brian Dewey on 4/1/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <UIKit/UIKit.h>

#import "BLTDatabase.h"
#import "BLTGridSummary.h"
#import "BLTLocation.h"
#import "BLTLocationDataSummary.h"
#import "BLTLocationManager.h"
#import "BLTMotionActivity.h"
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
  CMMotionActivityManager *_motionActivityManager;
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
    if ([CMMotionActivityManager isActivityAvailable]) {
      _motionActivityManager = [[CMMotionActivityManager alloc] init];
    }
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

+ (BLTMotionActivity *)_newManagedActivityFromActivity:(CMMotionActivity *)activity inManagedObjectContext:(NSManagedObjectContext *)moc
{
  BLTMotionActivity *managedMotionActivity = [NSEntityDescription insertNewObjectForEntityForName:@"BLTMotionActivity" inManagedObjectContext:moc];
  managedMotionActivity.stationary = activity.stationary;
  managedMotionActivity.walking = activity.walking;
  managedMotionActivity.running = activity.running;
  managedMotionActivity.automotive = activity.automotive;
  managedMotionActivity.cycling = activity.cycling;
  managedMotionActivity.startDate = [activity.startDate timeIntervalSinceReferenceDate];
  return managedMotionActivity;
}

- (void)updateDatabaseWithMotionActivities
{
  if (_motionActivityManager == nil) {
    return;
  }
  [_managedObjectContext performBlock:^{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"BLTMotionActivity"];
    NSSortDescriptor *sortByTimestamp = [[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:NO];
    fetchRequest.sortDescriptors = @[sortByTimestamp];
    fetchRequest.fetchLimit = 1;
    NSArray *existingObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    NSDate *now = [NSDate date];
    NSDate *startDate = nil;
    BLTMotionActivity *lastActivity = existingObjects.firstObject;
    if (lastActivity == nil) {
      startDate = [now dateByAddingTimeInterval:-1 * 7 * 24 * 60 * 60];
    } else {
      startDate = [NSDate dateWithTimeIntervalSinceReferenceDate:lastActivity.startDate];
    }
    [_motionActivityManager queryActivityStartingFromDate:startDate toDate:now toQueue:[NSOperationQueue mainQueue] withHandler:^(NSArray *activities, NSError *error) {
      if (error != nil) {
        NSString *errorMessage = [NSString stringWithFormat:@"Error querying motion activities: %@", error];
        [_database logMessage:errorMessage displayAsNotification:YES];
      } else {
        [_managedObjectContext performBlock:^{
          for (CMMotionActivity *motionActivity in activities) {
            [[self class] _newManagedActivityFromActivity:motionActivity
                                   inManagedObjectContext:_managedObjectContext];
          }
          [_managedObjectContext save:NULL];
        }];
      }
    }];
  }];
}

- (void)buildTrips:(BLTTripBuilderCallback)callback
{
  if (callback == NULL) {
    return;
  }
  [_managedObjectContext performBlock:^{
    NSFetchRequest *visitFetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"BLTVisit"];
    NSSortDescriptor *sortByArrivalDate = [[NSSortDescriptor alloc] initWithKey:@"arrivalDate" ascending:YES];
    visitFetchRequest.sortDescriptors = @[sortByArrivalDate];
    NSArray *visits = [_managedObjectContext executeFetchRequest:visitFetchRequest error:NULL];
    NSDate *lastDepartureDate = nil;
    BLTTripGroups *tripGroups = [[BLTTripGroups alloc] init];
    for (BLTVisit *managedVisitObject in visits) {
      if (lastDepartureDate != nil && managedVisitObject.arrivalDate != [NSDate distantPast]) {
        NSFetchRequest *locationFetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"BLTLocation"];
        NSSortDescriptor *sortByTimestamp = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
        NSPredicate *locationsInTimeRange = [NSPredicate predicateWithFormat:@"timestamp >= %@ AND timestamp <= %@", lastDepartureDate, managedVisitObject.arrivalDate];
        locationFetchRequest.sortDescriptors = @[sortByTimestamp];
        locationFetchRequest.predicate = locationsInTimeRange;
        NSArray *locations = [_managedObjectContext executeFetchRequest:locationFetchRequest error:NULL];
        BLTTrip *trip = [[BLTTrip alloc] initWithStartDate:lastDepartureDate endDate:managedVisitObject.arrivalDate locations:locations];
        tripGroups = [tripGroups tripGroupsByAddingTrip:trip];
        lastDepartureDate = nil;
      }
      if (managedVisitObject.departureDate != [NSDate distantFuture]) {
        lastDepartureDate = managedVisitObject.departureDate;
      }
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
    NSMutableArray *locationSummaries = [[NSMutableArray alloc] init];
    __block NSDate *firstSummarizedTimestamp = nil;
    __block NSDate *lastSummarizedTimestamp = nil;
    __block NSUInteger countOfSummarizedLocations = 0;
    [self _enumerateLocationsWithBlock:^(BLTLocation *managedLocation) {
      NSDate *currentTimestamp = [NSDate dateWithTimeIntervalSinceReferenceDate:managedLocation.timestamp];
      NSTimeInterval delta = [lastSummarizedTimestamp timeIntervalSinceDate:currentTimestamp] * -1.0;
      if (delta > kTenSeconds) {
        BLTLocationDataSummary *summary = [[BLTLocationDataSummary alloc] initWithStartDate:firstSummarizedTimestamp endDate:lastSummarizedTimestamp countOfLocationObservations:countOfSummarizedLocations];
        [locationSummaries addObject:summary];
        firstSummarizedTimestamp = lastSummarizedTimestamp = nil;
        countOfSummarizedLocations = 0;
      }
      firstSummarizedTimestamp = firstSummarizedTimestamp ?: currentTimestamp;
      lastSummarizedTimestamp = currentTimestamp;
      countOfSummarizedLocations++;
    }];
    BLTLocationDataSummary *summary = [[BLTLocationDataSummary alloc] initWithStartDate:firstSummarizedTimestamp endDate:lastSummarizedTimestamp countOfLocationObservations:countOfSummarizedLocations];
    [locationSummaries addObject:summary];
    dispatch_async(dispatch_get_main_queue(), ^{
      callback(locationSummaries);
    });
  }];
}

- (BOOL)_canMergeGridSummary:(BLTGridSummary *)gridSummary
             withGridSummary:(BLTGridSummary *)otherGridSummary
           thresholdDuration:(NSTimeInterval)duration
           thresholdDistance:(CLLocationDistance)distance
{
  return gridSummary != nil &&
    otherGridSummary != nil &&
    [gridSummary distanceFromSummary:otherGridSummary] <= distance;
//    ABS([gridSummary timeIntervalSinceSummary:otherGridSummary]) <= duration;
}

- (void)buildGridSummariesForBucketDistance:(CLLocationDistance)bucketDistance
                            minimumDuration:(NSTimeInterval)minimumDuration
                                   callback:(BLTGridSummaryBuilderCallback)callback
{
  if (callback == NULL) {
    return;
  }
  [_managedObjectContext performBlock:^{
    NSMutableArray *gridSummaries = [[NSMutableArray alloc] init];
    MKMapPoint invalidMapPoint = MKMapPointMake(-1, -1);
    __block MKMapPoint currentMapPoint = invalidMapPoint;
    __block BLTGridSummary *inProgressGridSummary = nil;
    __block NSDate *enteredDate = nil;
    __block NSDate *leftDate = nil;
    dispatch_block_t emitSummaryBlock = ^{
      BLTGridSummary *summary = [[BLTGridSummary alloc] initWithMapPoint:currentMapPoint
                                                      horizontalAccuracy:bucketDistance
                                                         dateEnteredGrid:enteredDate
                                                            dateLeftGrid:leftDate];
      if (summary.duration >= minimumDuration) {
        if ([self _canMergeGridSummary:inProgressGridSummary withGridSummary:summary thresholdDuration:10 * 60 thresholdDistance:bucketDistance * 10]) {
          inProgressGridSummary = [inProgressGridSummary gridSummaryByMergingSummary:summary];
        } else {
          if (inProgressGridSummary != nil) {
            [gridSummaries addObject:inProgressGridSummary];
          }
          inProgressGridSummary = summary;
        }
      }
    };
    [self _enumerateLocationsWithBlock:^(BLTLocation *managedLocation) {
      CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(managedLocation.latitude, managedLocation.longitude);
      MKMapPoint bucketizedMapPoint = [BLTGridSummary bucketizedMapPointForCoordinate:coordinate distancePerBucket:bucketDistance];
      if (!MKMapPointEqualToPoint(currentMapPoint, bucketizedMapPoint)) {
        if (!MKMapPointEqualToPoint(currentMapPoint, invalidMapPoint)) {
          emitSummaryBlock();
        }
        currentMapPoint = bucketizedMapPoint;
        enteredDate = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:managedLocation.timestamp];
      }
      leftDate = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:managedLocation.timestamp];
    }];
    if (!MKMapPointEqualToPoint(currentMapPoint, invalidMapPoint)) {
      emitSummaryBlock();
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      callback(gridSummaries);
    });
  }];
}

- (void)_enumerateLocationsWithBlock:(void (^)(BLTLocation *managedLocation))block
{
  if (block == NULL) {
    return;
  }
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"BLTLocation"];
  NSSortDescriptor *sortByTimestamp = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
  fetchRequest.sortDescriptors = @[sortByTimestamp];
  NSArray *locations = [_managedObjectContext executeFetchRequest:fetchRequest error:NULL];
  for (BLTLocation *managedLocation in locations) {
    block(managedLocation);
  }
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
  static CLLocation *previousLocation = nil;
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
      locationObject.timestamp = [location.timestamp timeIntervalSinceReferenceDate];
      locationObject.altitude = location.altitude;
      locationObject.course = location.course;
      locationObject.horizontalAccuracy = location.horizontalAccuracy;
      locationObject.latitude = location.coordinate.latitude;
      locationObject.longitude = location.coordinate.longitude;
      locationObject.speed = location.speed;
      locationObject.verticalAccuracy = location.verticalAccuracy;
      if (previousLocation != nil) {
        locationObject.distanceFromLastLocation = [location distanceFromLocation:previousLocation];
        locationObject.timeIntervalFromLastLocation = [location.timestamp timeIntervalSinceDate:previousLocation.timestamp];
        locationObject.interpolatedSpeed = locationObject.distanceFromLastLocation / locationObject.timeIntervalFromLastLocation;
      }
      previousLocation = location;
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
