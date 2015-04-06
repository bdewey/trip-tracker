//
//  AppDelegate.m
//  background-location-test
//
//  Created by Brian Dewey on 4/1/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "AppDelegate.h"
#import "BLTDatabase.h"
#import "BLTLocationManager.h"

@interface AppDelegate ()

@property (nonatomic, readonly, strong) BLTDatabase *database;
@property (nonatomic, readonly, strong) BLTLocationManager *locationManager;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  _database = [[BLTDatabase alloc] init];
  [BLTDatabase setSharedDatabase:_database];
  UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert categories:nil];
  [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
  CLLocationManager *coreLocationManager = [[CLLocationManager alloc] init];
  coreLocationManager.activityType = CLActivityTypeFitness;
  _locationManager = [[BLTLocationManager alloc] initWithLocationManager:coreLocationManager database:_database];
  [_locationManager startRecordingLocationHistory];
  [_locationManager startRecordingVisits];
  [BLTLocationManager setSharedLocationManager:_locationManager];
  [_database logMessage:@"application:didFinishLaunchingWithOptions:" displayAsNotification:NO];
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  // Saves changes in the application's managed object context before the application terminates.
  [_database saveContext];
}

@end
