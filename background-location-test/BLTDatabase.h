//
//  BLTDatabase.h
//  background-location-test
//
//  Created by Brian Dewey on 4/1/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface BLTDatabase : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSManagedObjectContext *)newPrivateQueueManagedObjectContextWithName:(NSString *)name;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

+ (BLTDatabase *)sharedDatabase;
+ (void)setSharedDatabase:(BLTDatabase *)sharedDatabase;

@end
