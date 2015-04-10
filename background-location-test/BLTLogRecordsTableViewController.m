//
//  BLTLogRecordsTableViewController.m
//  background-location-test
//
//  Created by Brian Dewey on 4/5/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import "BLTLogRecordsTableViewController.h"
#import "BLTDatabase.h"
#import "BLTLogRecord.h"

static NSString *const kLogRecordReuseIdentifier = @"BLTLogRecord";

@interface BLTLogRecordsTableViewController () <NSFetchedResultsControllerDelegate>

@end

@implementation BLTLogRecordsTableViewController

{
  BLTDatabase *_database;
  NSFetchedResultsController *_fetchedResultsController;
  NSDateFormatter *_dateFormatter;
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
  
  _dateFormatter = [[NSDateFormatter alloc] init];
  _dateFormatter.dateStyle = NSDateFormatterShortStyle;
  _dateFormatter.timeStyle = NSDateFormatterShortStyle;
  
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kBLTLogRecordEntityName];
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
  fetchRequest.sortDescriptors = @[sortDescriptor];
  _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                  managedObjectContext:_database.managedObjectContext
                                                                    sectionNameKeyPath:nil
                                                                             cacheName:nil];
  _fetchedResultsController.delegate = self;
  BOOL success = [_fetchedResultsController performFetch:NULL];
  if (!success) {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Oops" message:@"Error" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
      [self dismissViewControllerAnimated:YES completion:NULL];
    }];
    [alertController addAction:dismiss];
    [self presentViewController:alertController animated:YES completion:NULL];
  }
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
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLogRecordReuseIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kLogRecordReuseIdentifier];
  }
  BLTLogRecord *managedLogRecord = _fetchedResultsController.fetchedObjects[indexPath.row];
  cell.textLabel.text = managedLogRecord.message;
  cell.detailTextLabel.text = [_dateFormatter stringFromDate:managedLogRecord.timestamp];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  BLTLogRecord *managedLogRecord = _fetchedResultsController.fetchedObjects[indexPath.row];
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Log Message" message:managedLogRecord.message preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [self dismissViewControllerAnimated:YES completion:NULL];
  }];
  [alertController addAction:dismissAction];
  [self presentViewController:alertController animated:YES completion:NULL];
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
