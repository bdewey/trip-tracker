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
#import "BLTFormattingHelpers.h"
#import "BLTGroupedItems.h"
#import "BLTLocation.h"
#import "BLTLocationDataSummary.h"
#import "BLTLocationManager.h"

static NSString *const kLocationReuseIdentifier = @"BLTLocation";

@interface BLTLocationsTableViewController () <BLTGroupedItemsDelegate>

@end

@implementation BLTLocationsTableViewController
{
  BLTDatabase *_database;
  BLTLocationManager *_locationManager;
  BLTGroupedItems *_groupedLocationSummaries;
  NSDateIntervalFormatter *_dateIntervalFormatter;
}

- (void)dealloc
{
  [self.refreshControl removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _database = [BLTDatabase sharedDatabase];
  NSAssert(_database != nil, @"Must have a database");
  _locationManager = [BLTLocationManager sharedLocationManager];
  NSAssert(_locationManager != nil, @"Must have a location manager");

  _dateIntervalFormatter = [[NSDateIntervalFormatter alloc] init];
  _dateIntervalFormatter.dateStyle = NSDateIntervalFormatterNoStyle;
  _dateIntervalFormatter.timeStyle = NSDateIntervalFormatterMediumStyle;
  
  UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
  [refreshControl addTarget:self action:@selector(_refresh:) forControlEvents:UIControlEventValueChanged];
  self.refreshControl = refreshControl;
  [self _refresh:nil];
}

- (IBAction)_refresh:(id)sender
{
  [self.refreshControl beginRefreshing];
  [_locationManager buildLocationSummaries:^(NSArray *locationSummaries) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      BLTGroupedItems *groupedSummaries = [[BLTGroupedItems alloc] initWithDelegate:self];
      for (NSInteger i = 0; i < locationSummaries.count; i++) {
        groupedSummaries = [groupedSummaries groupedItemsByAddingItem:locationSummaries[i]];
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        _groupedLocationSummaries = groupedSummaries;
        [self.refreshControl endRefreshing];
        [self.tableView reloadData];
      });
    });
  }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return _groupedLocationSummaries.countOfGroups;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  return [_groupedLocationSummaries nameOfGroup:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [_groupedLocationSummaries countOfItemsInGroup:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLocationReuseIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kLocationReuseIdentifier];
  }
  BLTLocationDataSummary *locationSummary = (BLTLocationDataSummary *)[_groupedLocationSummaries itemForIndexPath:indexPath];
  cell.textLabel.text = [_dateIntervalFormatter stringFromDate:locationSummary.startDate toDate:locationSummary.endDate];
  cell.detailTextLabel.text = [NSString stringWithFormat:@"%tu locations", locationSummary.countOfLocationObservations];
  return cell;
}

#pragma mark - BLTGroupedItemsDelegate

- (NSString *)groupedItems:(BLTGroupedItems *)groupedItems nameOfGroupForItem:(BLTLocationDataSummary *)item
{
  return [BLTDateFormatterWithDayOfWeekMonthDay() stringFromDate:item.startDate];
}

- (BOOL)groupedItemsDisplayInReversedOrder:(BLTGroupedItems *)groupedItems
{
  return YES;
}

@end
