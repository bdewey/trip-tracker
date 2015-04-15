//
//  BLTDatabase.m
//  background-location-test
//
//  Created by Brian Dewey on 4/1/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BLTDatabase.h"
#import "BLTLogRecord.h"

NSString *const kBLTLogRecordEntityName = @"BLTLogRecord";

static BLTDatabase *g_database;

@implementation BLTDatabase
{
  NSMutableDictionary *_nameToMocMap;
  NSManagedObjectContext *_logContext;
}

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (instancetype)init
{
  self = [super init];
  if (self != nil) {
    _nameToMocMap = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (BLTDatabase *)sharedDatabase
{
  return g_database;
}

+ (void)setSharedDatabase:(BLTDatabase *)sharedDatabase
{
  g_database = sharedDatabase;
}

#pragma mark - Core Data stack

- (NSURL *)applicationDocumentsDirectory {
  // The directory the application uses to store the Core Data store file. This code uses a directory named "org.brians-brain.background_location_test" in the application's documents directory.
  return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
  // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
  if (_managedObjectModel != nil) {
    return _managedObjectModel;
  }
  NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"background_location_test" withExtension:@"momd"];
  _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
  return _managedObjectModel;
}

- (NSURL *)_storeURL
{
  return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"background_location_test.sqlite"];
}

- (NSNumber *)sizeOfDatabase
{
  NSDictionary *storeAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self _storeURL].path error:NULL];
  return storeAttributes[NSFileSize];
}

- (void)archiveDatabase
{
  NSURL *storeURL = [self _storeURL];
  NSString *lastPath = [storeURL lastPathComponent];
  NSString *lastPathWithoutExtension = [lastPath stringByDeletingPathExtension];
  NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
                                                                 fromDate:[NSDate date]];
  NSString *dateString = [NSString stringWithFormat:@"-%zd.%02zd.%02zd-%02zd.%02zd.%02zd", components.year, components.month, components.day, components.hour, components.minute, components.second];
  NSString *newPath = [lastPathWithoutExtension stringByAppendingString:dateString];
  NSString *newPathWithExtension = [newPath stringByAppendingPathExtension:@"sqlite"];
  NSURL *fullURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:newPathWithExtension];
  
  NSPersistentStoreCoordinator *psc = self.persistentStoreCoordinator;
  NSPersistentStore *store = [psc persistentStoreForURL:storeURL];
  NSError *error;
  if (![psc removePersistentStore:store error:&error]) {
    NSString *errorMessage = [NSString stringWithFormat:@"Can't remove persistent store: %@", error];
    [self logMessage:errorMessage displayAsNotification:YES];
  } else {
    if (![[NSFileManager defaultManager] moveItemAtURL:storeURL toURL:fullURL error:&error]) {
      [self logMessage:[NSString stringWithFormat:@"Can't move database from %@ to %@: %@", storeURL, fullURL, error] displayAsNotification:YES];
    }
    abort();
  }
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
  // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
  if (_persistentStoreCoordinator != nil) {
    return _persistentStoreCoordinator;
  }
  
  // Create the coordinator and store
  
  _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
  NSURL *storeURL = [self _storeURL];
  NSError *error = nil;
  NSString *failureReason = @"There was an error creating or loading the application's saved data.";
  NSDictionary *pscOptions = @{
                               NSMigratePersistentStoresAutomaticallyOption: @YES,
                               NSInferMappingModelAutomaticallyOption: @YES,
                               };
  if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:pscOptions error:&error]) {
    // Report any error we got.
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
    dict[NSLocalizedFailureReasonErrorKey] = failureReason;
    dict[NSUnderlyingErrorKey] = error;
    error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
    // Replace this with code to handle the error appropriately.
    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    abort();
  }
  
  return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)newPrivateQueueManagedObjectContextWithName:(NSString *)name
{
  NSPersistentStoreCoordinator *persistentStoreCoordinator = [self persistentStoreCoordinator];
  if (!persistentStoreCoordinator) {
    return nil;
  }
  NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
  moc.persistentStoreCoordinator = persistentStoreCoordinator;
  @synchronized(_nameToMocMap) {
    NSAssert(_nameToMocMap[name] == nil, @"Cannot register two mocs with the same name");
    _nameToMocMap[name] = moc;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_processChangeNotification:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:moc];
  }
  return moc;
}

- (void)logMessage:(NSString *)message displayAsNotification:(BOOL)displayAsNotification
{
  if (_logContext == nil) {
    _logContext = [self newPrivateQueueManagedObjectContextWithName:@"logging"];
  }
  [_logContext performBlock:^{
    BLTLogRecord *logRecord = [NSEntityDescription insertNewObjectForEntityForName:kBLTLogRecordEntityName inManagedObjectContext:_logContext];
    NSAssert(logRecord != nil, @"Must be able to create a log record");
    logRecord.timestamp = [NSDate date];
    logRecord.message = message;
    [_logContext save:NULL];
    if (displayAsNotification) {
      UILocalNotification *notification = [[UILocalNotification alloc] init];
      notification.alertAction = nil;
      notification.alertBody = message;
      dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
      });
    }
  }];
}

- (void)_processChangeNotification:(NSNotification *)notification
{
  [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
}

- (NSManagedObjectContext *)managedObjectContext {
  // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
  if (_managedObjectContext != nil) {
    return _managedObjectContext;
  }
  
  NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
  if (!coordinator) {
    return nil;
  }
  _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
  [_managedObjectContext setPersistentStoreCoordinator:coordinator];
  return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
  NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
  if (managedObjectContext != nil) {
    NSError *error = nil;
    if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
      // Replace this implementation with code to handle the error appropriately.
      // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    }
  }
}

@end
