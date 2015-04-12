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

@interface BLTTripsTableViewController () <BLTMapViewControllerDelegate>

@end

@implementation BLTTripsTableViewController
{
  BLTLocationManager *_locationManager;
  NSArray *_trips;
  BLTTrip *_selectedTripForMapView;
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

#pragma mark - BLTMapViewControllerDelegate

- (void)mapViewController:(BLTMapViewController *)mapViewController willAppearWithMapView:(MKMapView *)mapView
{
  mapView.delegate = self;
  mapView.region = [[self class] _coordinateRegionForMultiPoint:_selectedTripForMapView.route];
  [mapView addOverlay:_selectedTripForMapView.route level:MKOverlayLevelAboveRoads];
}

+ (MKCoordinateRegion)_coordinateRegionForMultiPoint:(MKMultiPoint *)multiPoint
{
  NSUInteger countOfPoints = multiPoint.pointCount;
  CLLocationCoordinate2D *coordinates = calloc(countOfPoints, sizeof(CLLocationCoordinate2D));
  if (coordinates == NULL) {
    return MKCoordinateRegionMake(CLLocationCoordinate2DMake(0, 0), MKCoordinateSpanMake(0, 0));
  }
  [multiPoint getCoordinates:coordinates range:NSMakeRange(0, countOfPoints)];
  CLLocationDegrees minLatitude = 90;
  CLLocationDegrees maxLatitude = -90;
  CLLocationDegrees minLongitude = 180;
  CLLocationDegrees maxLongitude = -180;
  for (NSUInteger i = 0; i < countOfPoints; i++) {
    CLLocationCoordinate2D coordinate = coordinates[i];
    if (CLLocationCoordinate2DIsValid(coordinate)) {
      minLatitude = MIN(minLatitude, coordinate.latitude);
      maxLatitude = MAX(maxLatitude, coordinate.latitude);
      minLongitude = MIN(minLongitude, coordinate.longitude);
      maxLongitude = MAX(maxLongitude, coordinate.longitude);
    }
  }
  free(coordinates);
  CLLocationCoordinate2D center = CLLocationCoordinate2DMake((minLatitude + maxLatitude) / 2, (minLongitude + maxLongitude) / 2);
  MKCoordinateSpan span = MKCoordinateSpanMake(maxLatitude - minLatitude, maxLongitude - minLongitude);
  return MKCoordinateRegionMake(center, span);
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

#pragma mark - Storyboard

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
    mapViewController.delegate = self;
    _selectedTripForMapView = trip;
  } else if ([segue.identifier isEqualToString:@"ShowLocationDetailSegue"]) {
    BLTLocationsTableViewController *locationsTableViewController = segue.destinationViewController;
    locationsTableViewController.locationFilterPredicate = [NSPredicate predicateWithFormat:@"timestamp >= %@ AND timestamp <= %@", trip.startDate, trip.endDate];
  }
}

@end
