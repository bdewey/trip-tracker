//
//  BLTMotionActivitesTableViewController.m
//  background-location-test
//
//  Created by Brian Dewey on 4/15/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <CoreMotion/CoreMotion.h>

#import "BLTDatabase.h"
#import "BLTLocationManager.h"
#import "BLTMotionActivity.h"
#import "BLTMotionActivitesTableViewController.h"

static NSString *_summaryOfManagedMotionActivity(BLTMotionActivity *motionActivity)
{
  NSMutableString *result = [[NSMutableString alloc] init];
  switch ((CMMotionActivityConfidence)motionActivity.confidence) {
    case CMMotionActivityConfidenceHigh:
      [result appendString:@"(High) "];
      break;

    case CMMotionActivityConfidenceMedium:
      [result appendString:@"(Medium) "];
      break;

    case CMMotionActivityConfidenceLow:
      [result appendString:@"(Low) "];
      break;
  }
  if (motionActivity.stationary) {
    [result appendString:@"Stationary "];
  }
  if (motionActivity.walking) {
    [result appendString:@"Walking"];
  }
  if (motionActivity.running) {
    [result appendString:@"Running"];
  }
  if (motionActivity.automotive) {
    [result appendString:@"Automotive"];
  }
  if (motionActivity.cycling) {
    [result appendString:@"Cycling"];
  }
  if (motionActivity.unknown) {
    [result appendString:@"Unknown"];
  }
  return result;
}

@interface BLTMotionActivitesTableViewController () <NSFetchedResultsControllerDelegate>

@end

@implementation BLTMotionActivitesTableViewController
{
  BLTLocationManager *_locationManager;
  BLTDatabase *_database;
  NSFetchedResultsController *_fetchedResultsController;
  NSDateFormatter *_dateFormatter;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _locationManager = [BLTLocationManager sharedLocationManager];
  NSAssert(_locationManager != nil, @"Must have a location manager");
  _database = _locationManager.database;
  [_locationManager updateDatabaseWithMotionActivities];
  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"BLTMotionActivity"];
  NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:NO];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"confidence != %d", CMMotionActivityConfidenceLow];
  fetchRequest.predicate = predicate;
  fetchRequest.sortDescriptors = @[sortDescriptor];
  _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                  managedObjectContext:_database.managedObjectContext
                                                                    sectionNameKeyPath:nil
                                                                             cacheName:nil];
  _fetchedResultsController.delegate = self;
  [_fetchedResultsController performFetch:NULL];
  _dateFormatter = [[NSDateFormatter alloc] init];
  _dateFormatter.dateStyle = NSDateFormatterShortStyle;
  _dateFormatter.timeStyle = NSDateFormatterShortStyle;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return _fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [_fetchedResultsController.sections[section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BLTMotionActivityCell" forIndexPath:indexPath];
  BLTMotionActivity *managedMotionActivity = [_fetchedResultsController objectAtIndexPath:indexPath];
  cell.textLabel.text = _summaryOfManagedMotionActivity(managedMotionActivity);
  NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:managedMotionActivity.startDate];
  cell.detailTextLabel.text = [_dateFormatter stringFromDate:date];
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
  [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
