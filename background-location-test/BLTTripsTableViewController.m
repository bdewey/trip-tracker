//
//  BLTTripsTableViewController.m
//  background-location-test
//
//  Created by Brian Dewey on 4/3/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "BLTTripsTableViewController.h"

#import "BLTLocationManager.h"
#import "BLTLocationsTableViewController.h"
#import "BLTMapViewController.h"
#import "BLTTrip.h"

static NSString *const kTripCellReuseIdentifier = @"BLTTrip";

@interface BLTTripsTableViewController ()

@end

@implementation BLTTripsTableViewController
{
  BLTLocationManager *_locationManager;
  NSArray *_trips;
  NSLengthFormatter *_lengthFormatter;
  NSDateFormatter *_dateFormatter;
  NSDateComponentsFormatter *_dateComponentsFormatter;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _locationManager = [BLTLocationManager sharedLocationManager];
  NSAssert(_locationManager != nil, @"We must have a location manager");
  _lengthFormatter = [[NSLengthFormatter alloc] init];
  _dateFormatter = [[NSDateFormatter alloc] init];
  _dateFormatter.dateStyle = NSDateFormatterShortStyle;
  _dateFormatter.timeStyle = NSDateFormatterShortStyle;
  _dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
  _dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleAbbreviated;
  [self _didTapRefresh:nil];
}

- (IBAction)_didTapRefresh:(UIBarButtonItem *)sender
{
  [_locationManager buildTrips:^(NSArray *trips) {
    _trips = trips;
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
  return _trips.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTripCellReuseIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kTripCellReuseIdentifier];
  }
  BLTTrip *trip = _trips[indexPath.row];
  NSString *datePart = [_dateFormatter stringFromDate:trip.startDate];
  NSString *durationPart = [_dateComponentsFormatter stringFromTimeInterval:[trip.endDate timeIntervalSinceDate:trip.startDate]];
  cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", datePart, durationPart];
  cell.detailTextLabel.text = [_lengthFormatter stringFromMeters:trip.distance];
  return cell;
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
  if ([identifier isEqualToString:@"ShowTripMapSegue"]) {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    BLTTrip *trip = _trips[indexPath.row];
    return trip.route.pointCount > 0;
  } else {
    return YES;
  }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
  BLTTrip *trip = _trips[indexPath.row];
  if ([segue.identifier isEqualToString:@"ShowTripMapSegue"]) {
    BLTMapViewController *mapViewController = segue.destinationViewController;
    mapViewController.route = trip.route;
  } else if ([segue.identifier isEqualToString:@"ShowLocationDetailSegue"]) {
    BLTLocationsTableViewController *locationsTableViewController = segue.destinationViewController;
    locationsTableViewController.locationFilterPredicate = [NSPredicate predicateWithFormat:@"timestamp >= %@ AND timestamp <= %@", trip.startDate, trip.endDate];
  }
}

@end
