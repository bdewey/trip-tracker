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
#import "BLTLocationDataSummary.h"
#import "BLTLocationManager.h"

static NSString *const kLocationReuseIdentifier = @"BLTLocation";

@interface BLTLocationsTableViewController () <NSFetchedResultsControllerDelegate>

@end

@implementation BLTLocationsTableViewController
{
  BLTDatabase *_database;
  BLTLocationManager *_locationManager;
  NSArray *_locationSummaries;
  NSDateIntervalFormatter *_dateIntervalFormatter;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _database = [BLTDatabase sharedDatabase];
  NSAssert(_database != nil, @"Must have a database");
  _locationManager = [BLTLocationManager sharedLocationManager];
  NSAssert(_locationManager != nil, @"Must have a location manager");

  _dateIntervalFormatter = [[NSDateIntervalFormatter alloc] init];
  _dateIntervalFormatter.dateStyle = NSDateIntervalFormatterShortStyle;
  _dateIntervalFormatter.timeStyle = NSDateIntervalFormatterMediumStyle;
  [self _refresh:nil];
}

- (IBAction)_refresh:(id)sender
{
  [_locationManager buildLocationSummaries:^(NSArray *locationSummaries) {
    _locationSummaries = [locationSummaries copy];
    [self.tableView reloadData];
  }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return _locationSummaries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLocationReuseIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kLocationReuseIdentifier];
  }
  BLTLocationDataSummary *locationSummary = _locationSummaries[indexPath.row];
  cell.textLabel.text = [_dateIntervalFormatter stringFromDate:locationSummary.startDate toDate:locationSummary.endDate];
  cell.detailTextLabel.text = [NSString stringWithFormat:@"%tu locations", locationSummary.countOfLocationObservations];
  return cell;
}

@end
