//
//  BLTLocationRecordsTableViewController.m
//  background-location-test
//
//  Created by Brian Dewey on 5/11/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "BLTDatabase.h"
#import "BLTLocation.h"
#import "BLTLocationRecordsTableViewController.h"

static NSString *const kReuseIdentifier = @"ManagedLocationReuseIdentifier";

@interface BLTLocationRecordsTableViewController ()

@end

@implementation BLTLocationRecordsTableViewController
{
  BLTDatabase *_database;
  NSFetchedResultsController *_fetchedResultsController;
  NSDateFormatter *_dateFormatter;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _database = [BLTDatabase sharedDatabase];
  NSAssert(_database != nil, @"Must have a database");
  _dateFormatter = [[NSDateFormatter alloc] init];
  _dateFormatter.dateStyle = NSDateFormatterNoStyle;
  _dateFormatter.timeStyle = NSDateFormatterMediumStyle;
  [self _refresh:nil];
}

- (void)_refresh:(id)sender
{
  if (!self.isViewLoaded || _sortDescriptors.count == 0) {
    return;
  }
  
  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"BLTLocation"];
  fetchRequest.sortDescriptors = _sortDescriptors;
  fetchRequest.predicate = _predicate;
  _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:_database.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
  if ([_fetchedResultsController performFetch:NULL]) {
    [self.tableView reloadData];
  }
}

- (void)setPredicate:(NSPredicate *)predicate
{
  if (_predicate != predicate) {
    _predicate = predicate;
    [self _refresh:nil];
  }
}

- (void)setSortDescriptors:(NSArray *)sortDescriptors
{
  if (_sortDescriptors != sortDescriptors) {
    _sortDescriptors = [sortDescriptors copy];
    [self _refresh:nil];
  }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return _fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  id<NSFetchedResultsSectionInfo> sectionInfo = _fetchedResultsController.sections[section];
  return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kReuseIdentifier forIndexPath:indexPath];
  BLTLocation *location = [_fetchedResultsController objectAtIndexPath:indexPath];
  cell.textLabel.text = [_dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:location.timestamp]];
  cell.detailTextLabel.text = [NSString stringWithFormat:@"%0.2f %0.2f (+/- %0.2f)", location.distanceFromLastLocation, location.speed, location.horizontalAccuracy];
  return cell;
}

@end
