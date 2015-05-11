//
//  BLTTripsTableViewController.m
//  background-location-test
//
//  Created by Brian Dewey on 4/3/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "BLTTripsTableViewController.h"

#import "BLTDatabase.h"
#import "BLTFormattingHelpers.h"
#import "BLTLocationHelpers.h"
#import "BLTLocationManager.h"
#import "BLTLocationsTableViewController.h"
#import "BLTMapViewController.h"
#import "BLTTrip.h"
#import "BLTGroupedItems.h"
#import "BLTTripSummaryTableViewCell.h"

static NSString *const kTripCellReuseIdentifier = @"BLTTrip";

@interface BLTTripsTableViewController () <
  BLTGroupedItemsDelegate,
  BLTMapViewControllerDelegate
>

@end

@implementation BLTTripsTableViewController
{
  BLTLocationManager *_locationManager;
  BLTGroupedItems *_tripGroups;
  BLTTrip *_selectedTripForMapView;
}

- (void)dealloc
{
  [self.refreshControl removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _locationManager = [BLTLocationManager sharedLocationManager];
  NSAssert(_locationManager != nil, @"We must have a location manager");
  UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
  [refreshControl addTarget:self action:@selector(_didTapRefresh:) forControlEvents:UIControlEventValueChanged];
  self.refreshControl = refreshControl;
  [self _didTapRefresh:nil];
}

- (IBAction)_didTapSettings:(UIBarButtonItem *)sender
{
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Settings" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
  UIAlertAction *refreshAction = [UIAlertAction actionWithTitle:@"Refresh" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [self _didTapRefresh:nil];
  }];
  [alertController addAction:refreshAction];
  UIAlertAction *archiveAction = [UIAlertAction actionWithTitle:@"Archive" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
    [[BLTDatabase sharedDatabase] archiveDatabase];
  }];
  [alertController addAction:archiveAction];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    // nothing
  }];
  [alertController addAction:cancelAction];
  [self presentViewController:alertController animated:YES completion:NULL];
}

- (IBAction)_didTapRefresh:(UIBarButtonItem *)sender
{
  [self.refreshControl beginRefreshing];
  [_locationManager buildTripsWithGroupedItemsDelegate:self callback:^(BLTGroupedItems *tripGroups) {
    _tripGroups = tripGroups;
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
  }];
}

#pragma mark - BLTMapViewControllerDelegate

- (void)mapViewController:(BLTMapViewController *)mapViewController willAppearWithMapView:(MKMapView *)mapView
{
  mapView.delegate = self;
  mapView.region = [BLTLocationHelpers coordinateRegionForMultiPoint:_selectedTripForMapView.route];
  [mapView addOverlay:_selectedTripForMapView.route level:MKOverlayLevelAboveRoads];
}

#pragma mark - MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
  MKPolylineRenderer *polylineRenderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
  polylineRenderer.strokeColor = [UIColor greenColor];
  polylineRenderer.alpha = 0.7;
  polylineRenderer.lineWidth = 4;
  return polylineRenderer;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return _tripGroups.countOfGroups;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [_tripGroups countOfItemsInGroup:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  return [_tripGroups nameOfGroup:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  BLTTripSummaryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTripCellReuseIdentifier forIndexPath:indexPath];
  cell.trip = (BLTTrip *)[_tripGroups itemForIndexPath:indexPath];
  return cell;
}

#pragma mark - Storyboard

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
  if ([identifier isEqualToString:@"ShowTripMapSegue"]) {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    BLTTrip *trip = (BLTTrip *)[_tripGroups itemForIndexPath:indexPath];
    return trip.route.pointCount > 0;
  } else {
    return YES;
  }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
  BLTTrip *trip = (BLTTrip *)[_tripGroups itemForIndexPath:indexPath];
  if ([segue.identifier isEqualToString:@"ShowTripMapSegue"]) {
    BLTMapViewController *mapViewController = segue.destinationViewController;
    mapViewController.delegate = self;
    _selectedTripForMapView = trip;
  } else if ([segue.identifier isEqualToString:@"ShowLocationDetailSegue"]) {
    BLTLocationsTableViewController *locationsTableViewController = segue.destinationViewController;
    locationsTableViewController.locationFilterPredicate = [NSPredicate predicateWithFormat:@"timestamp >= %@ AND timestamp <= %@", trip.startDate, trip.endDate];
  }
}

#pragma mark - BLTGroupedItemsDelegate

- (NSString *)groupedItems:(BLTGroupedItems *)groupedItems nameOfGroupForItem:(BLTTrip *)item
{
  return [BLTDateFormatterWithDayOfWeekMonthDay() stringFromDate:item.startDate];
}

- (BOOL)groupedItemsDisplayInReversedOrder:(BLTGroupedItems *)groupedItems
{
  return YES;
}

@end
