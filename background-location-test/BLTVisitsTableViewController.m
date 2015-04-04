//
//  BLTVisitsTableViewController.m
//  background-location-test
//
//  Created by Brian Dewey on 4/1/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "BLTDatabase.h"
#import "BLTMapViewController.h"
#import "BLTVisitsTableViewController.h"
#import "BLTVisit.h"

static NSString *const kVisitReuseIdentifier = @"BLTVisit";

@interface BLTVisitsTableViewController () <NSFetchedResultsControllerDelegate>

@end

@implementation BLTVisitsTableViewController
{
  BLTDatabase *_database;
  NSFetchedResultsController *_fetchedResultsController;
  NSDateFormatter *_dateFormatter;
  NSDateComponentsFormatter *_dateComponentsFormatter;
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
  _dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
  _dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleAbbreviated;
  
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"BLTVisit"];
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"arrivalDate" ascending:YES];
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
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kVisitReuseIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kVisitReuseIdentifier];
  }
  BLTVisit *managedVisitObject = _fetchedResultsController.fetchedObjects[indexPath.row];
  CLVisit *visit = managedVisitObject.visit;
  cell.textLabel.text = [NSString stringWithFormat:@"%.4f, @%.4f", visit.coordinate.latitude, visit.coordinate.longitude];
  if (visit.arrivalDate == [NSDate distantPast]) {
    cell.detailTextLabel.text = @"Unknown";
  } else {
    NSString *datePart = [_dateFormatter stringFromDate:visit.arrivalDate];
    NSString *durationPart = nil;
    if (visit.departureDate == [NSDate distantFuture]) {
      durationPart = @"Unknown";
    } else {
      NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitMinute | NSCalendarUnitHour fromDate:visit.arrivalDate toDate:visit.departureDate options:0];
      durationPart = [_dateComponentsFormatter stringFromDateComponents:dateComponents];
    }
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", datePart, durationPart];
  }
  return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"ShowMapSegue"]) {
    BLTMapViewController *mapViewController = segue.destinationViewController;
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    BLTVisit *managedVisitObject = _fetchedResultsController.fetchedObjects[selectedIndexPath.row];
    mapViewController.coordinate = ((CLVisit *)managedVisitObject.visit).coordinate;
  }
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
