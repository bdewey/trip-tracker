//
//  BLTGridSummariesTableViewController.m
//  background-location-test
//
//  Created by Brian Dewey on 4/25/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import "BLTGridSummariesTableViewController.h"

#import <CoreLocation/CoreLocation.h>

#import "BLTLocationsTableViewController.h"

#import "BLTDatabase.h"
#import "BLTGridSummary.h"
#import "BLTLocation.h"
#import "BLTLocationManager.h"
#import "BLTMapViewController.h"

static NSString *const kLocationReuseIdentifier = @"BLTGridSummaryCell";
static NSString *const kShowMapSegueIdentifier = @"ShowMapSegue";

@interface BLTGridSummariesTableViewController () <BLTMapViewControllerDelegate, MKMapViewDelegate>

@end

@implementation BLTGridSummariesTableViewController
{
  BLTDatabase *_database;
  BLTLocationManager *_locationManager;
  NSArray *_gridSummaries;
  NSDateFormatter *_dateFormatter;
  NSDateComponentsFormatter *_dateComponentsFormatter;
  BLTGridSummary *_selectedGridSummary;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _database = [BLTDatabase sharedDatabase];
  NSAssert(_database != nil, @"Must have a database");
  _locationManager = [BLTLocationManager sharedLocationManager];
  NSAssert(_locationManager != nil, @"Must have a location manager");

  _dateFormatter = [[NSDateFormatter alloc] init];
  _dateFormatter.dateStyle = NSDateFormatterShortStyle;
  _dateFormatter.timeStyle = NSDateFormatterShortStyle;
  
  _dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
  _dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
  
  [self _refresh:nil];
}

- (IBAction)_refresh:(id)sender
{
  [_locationManager buildGridSummariesForBucketDistance:10 minimumDuration:5 * 60 callback:^(NSArray *gridSummaries) {
    _gridSummaries = [gridSummaries copy];
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
  return _gridSummaries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLocationReuseIdentifier forIndexPath:indexPath];
  BLTGridSummary *gridSummary = _gridSummaries[indexPath.row];
  NSString *datePart = [_dateFormatter stringFromDate:gridSummary.dateEnteredGrid];
  NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute
                                                                     fromDate:gridSummary.dateEnteredGrid
                                                                       toDate:gridSummary.dateLeftGrid
                                                                      options:0];
  NSString *durationPart = [_dateComponentsFormatter stringFromDateComponents:dateComponents];
  cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", datePart, durationPart];
  CLLocationCoordinate2D coordinate = MKCoordinateForMapPoint(gridSummary.mapPoint);
  cell.detailTextLabel.text = [NSString stringWithFormat:@"%0.6f, %0.6f", coordinate.latitude, coordinate.longitude];
  return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([segue.identifier isEqualToString:kShowMapSegueIdentifier]) {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    _selectedGridSummary = _gridSummaries[indexPath.row];
    BLTMapViewController *mapViewController = (BLTMapViewController *)segue.destinationViewController;
    mapViewController.delegate = self;
  }
}

#pragma mark - BLTMapViewControllerDelegate

- (void)mapViewController:(BLTMapViewController *)mapViewController willAppearWithMapView:(MKMapView *)mapView
{
  mapView.delegate = self;
  CLLocationCoordinate2D coordinate = MKCoordinateForMapPoint(_selectedGridSummary.mapPoint);
  MKCircle *gridCirle = [MKCircle circleWithCenterCoordinate:coordinate radius:_selectedGridSummary.horizontalAccuracy];
  [mapView addOverlay:gridCirle level:MKOverlayLevelAboveRoads];
  mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, 500, 500);
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
  MKCircleRenderer *renderer = [[MKCircleRenderer alloc] initWithCircle:overlay];
  renderer.fillColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.25];
  return renderer;
}

@end
