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
#import "BLTFormattingHelpers.h"
#import "BLTGridSummary.h"
#import "BLTGroupedItems.h"
#import "BLTLocation.h"
#import "BLTLocationHelpers.h"
#import "BLTLocationManager.h"
#import "BLTLocationRecordsTableViewController.h"
#import "BLTMapViewController.h"

static NSString *const kLocationReuseIdentifier = @"BLTGridSummaryCell";
static NSString *const kShowMapSegueIdentifier = @"ShowMapSegue";
static NSString *const kShowLocationDetailSegue = @"ShowLocationDetailSegue";
static const CLLocationDistance kBucketDistance = 10;
static const NSTimeInterval kBucketTimeInterval = 5 * 60;

@interface BLTGridSummariesTableViewController () <
  BLTGroupedItemsDelegate,
  BLTMapViewControllerDelegate,
  MKMapViewDelegate
>

@end

@implementation BLTGridSummariesTableViewController
{
  BLTDatabase *_database;
  BLTLocationManager *_locationManager;
  BLTGroupedItems *_groupedGridSummaries;
  NSDateFormatter *_dateFormatter;
  NSDateComponentsFormatter *_dateComponentsFormatter;
  BLTGridSummary *_selectedGridSummary;
  NSArray *_unmergedGridSummariesForSelectedGridSummary;
  MKMapView *_activeMapView;
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

  _dateFormatter = [[NSDateFormatter alloc] init];
  _dateFormatter.dateStyle = NSDateFormatterNoStyle;
  _dateFormatter.timeStyle = NSDateFormatterShortStyle;
  
  _dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
  _dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
  
  UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
  [refreshControl addTarget:self action:@selector(_refresh:) forControlEvents:UIControlEventValueChanged];
  self.refreshControl = refreshControl;
  
  [self _refresh:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  _activeMapView.delegate = nil;
  _activeMapView = nil;
  _selectedGridSummary = nil;
  _unmergedGridSummariesForSelectedGridSummary = nil;
}

- (IBAction)_refresh:(id)sender
{
  [self.refreshControl beginRefreshing];
  [_locationManager buildGridSummariesForBucketDistance:kBucketDistance minimumDuration:kBucketTimeInterval callback:^(NSArray *gridSummaries) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      BLTGroupedItems *groupedGridSummaries = [[BLTGroupedItems alloc] initWithDelegate:self];
      for (BLTGridSummary *gridSummary in gridSummaries) {
        groupedGridSummaries = [groupedGridSummaries groupedItemsByAddingItem:gridSummary];
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
        _groupedGridSummaries = groupedGridSummaries;
        [self.tableView reloadData];
      });
    });
  }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [_groupedGridSummaries countOfGroups];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [_groupedGridSummaries countOfItemsInGroup:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  return [_groupedGridSummaries nameOfGroup:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLocationReuseIdentifier forIndexPath:indexPath];
  BLTGridSummary *gridSummary = (BLTGridSummary *)[_groupedGridSummaries itemForIndexPath:indexPath];
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
    BLTGridSummary *summary = (BLTGridSummary *)[_groupedGridSummaries itemForIndexPath:indexPath];
    _selectedGridSummary = summary;
    [_locationManager buildUnmergedGridSummariesFromStartDate:_selectedGridSummary.dateEnteredGrid
                                                      endDate:_selectedGridSummary.dateLeftGrid
                                               bucketDistance:kBucketDistance
                                              minimumDuration:kBucketTimeInterval callback:^(NSArray *gridSummaries) {
                                                [self _setUnmergedGridSummaries:gridSummaries forSelectedGridSummary:summary];
                                              }];
    BLTMapViewController *mapViewController = (BLTMapViewController *)segue.destinationViewController;
    mapViewController.delegate = self;
  } else if ([segue.identifier isEqualToString:kShowLocationDetailSegue]) {
    BLTLocationRecordsTableViewController *locationRecordsTableViewController = (BLTLocationRecordsTableViewController *)segue.destinationViewController;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    BLTGridSummary *summary = (BLTGridSummary *)[_groupedGridSummaries itemForIndexPath:indexPath];
    locationRecordsTableViewController.title = [BLTDateFormatterWithDayOfWeekMonthDay() stringFromDate:summary.dateEnteredGrid];
    locationRecordsTableViewController.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
    locationRecordsTableViewController.predicate = [NSPredicate predicateWithFormat:@"timestamp >= %@ AND timestamp <= %@ AND distanceFromLastLocation > 0", summary.dateEnteredGrid, summary.dateLeftGrid];
  }
}

- (void)_setUnmergedGridSummaries:(NSArray *)gridSummaries forSelectedGridSummary:(BLTGridSummary *)summary
{
  if (_selectedGridSummary != summary) {
    return;
  }
  _unmergedGridSummariesForSelectedGridSummary = gridSummaries;
  [self _addOverlayToActiveMapView];
}

- (void)_addOverlayToActiveMapView
{
  if (_activeMapView == nil || _unmergedGridSummariesForSelectedGridSummary.count == 0) {
    return;
  }
  CLLocationCoordinate2D *coordinates = calloc(_unmergedGridSummariesForSelectedGridSummary.count, sizeof(CLLocationCoordinate2D));
  if (coordinates == NULL) {
    return;
  }
  for (NSUInteger i = 0; i < _unmergedGridSummariesForSelectedGridSummary.count; i++) {
    BLTGridSummary *summary = _unmergedGridSummariesForSelectedGridSummary[i];
    coordinates[i] = MKCoordinateForMapPoint(summary.mapPoint);
  }
  MKPolyline *route = [MKPolyline polylineWithCoordinates:coordinates count:_unmergedGridSummariesForSelectedGridSummary.count];
  free(coordinates);
  [_activeMapView addOverlay:route level:MKOverlayLevelAboveRoads];
  _activeMapView.region = [BLTLocationHelpers coordinateRegionForMultiPoint:route];
}

#pragma mark - BLTMapViewControllerDelegate

- (void)mapViewController:(BLTMapViewController *)mapViewController willAppearWithMapView:(MKMapView *)mapView
{
  _activeMapView = mapView;
  mapView.delegate = self;
  [self _addOverlayToActiveMapView];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
  MKPolylineRenderer *polylineRenderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
  polylineRenderer.strokeColor = [UIColor blueColor];
  polylineRenderer.alpha = 0.5;
  polylineRenderer.lineWidth = 4;
  return polylineRenderer;
}

#pragma mark - BLTGroupedItemsDelegate

- (NSString *)groupedItems:(BLTGroupedItems *)groupedItems nameOfGroupForItem:(BLTGridSummary *)item
{
  return [BLTDateFormatterWithDayOfWeekMonthDay() stringFromDate:item.dateEnteredGrid];
}

- (BOOL)groupedItemsDisplayInReversedOrder:(BLTGroupedItems *)groupedItems
{
  return YES;
}

@end
