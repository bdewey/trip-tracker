//
//  BLTLocationsTableViewController.m
//  background-location-test
//
//  Created by Brian Dewey on 4/1/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "BLTLocationsTableViewController.h"

#import "BLTDatabase.h"
#import "BLTLocation.h"

static NSString *const kLocationReuseIdentifier = @"BLTLocation";

@interface BLTLocationsTableViewController () <NSFetchedResultsControllerDelegate>

@end

@implementation BLTLocationsTableViewController
{
  BLTDatabase *_database;
  NSFetchedResultsController *_fetchedResultsController;
}

- (void)dealloc
{
  _fetchedResultsController.delegate = nil;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _database = [BLTDatabase sharedDatabase];
  NSAssert(_database != nil, @"Must have a database");
  
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"BLTLocation"];
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
  fetchRequest.sortDescriptors = @[sortDescriptor];
  _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                  managedObjectContext:_database.managedObjectContext
                                                                    sectionNameKeyPath:nil
                                                                             cacheName:nil];
  _fetchedResultsController.delegate = self;
  [_fetchedResultsController performFetch:NULL];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return _fetchedResultsController.fetchedObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLocationReuseIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kLocationReuseIdentifier];
  }
  BLTLocation *locationObject = _fetchedResultsController.fetchedObjects[indexPath.row];
  CLLocation *location = locationObject.location;
  cell.textLabel.text = [NSString stringWithFormat:@"%.4f, @%.4f", location.coordinate.latitude, location.coordinate.longitude];
  cell.detailTextLabel.text = location.timestamp.description;
  return cell;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
  [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
  [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
  NSAssert(type == NSFetchedResultsChangeInsert, @"Only know how to do inserts");
  [self.tableView insertRowsAtIndexPaths:@[newIndexPath]
                        withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
