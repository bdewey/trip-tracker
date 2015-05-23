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

#import "BLTFormattingHelpers.h"
#import "BLTGridStrategy.h"
#import "BLTGroupedItems.h"
#import "BLTLocation.h"
#import "BLTLocationHelpers.h"
#import "BLTLocationManager.h"
#import "BLTLocationRecordsTableViewController.h"
#import "BLTMapViewController.h"
#import "BLTPlaceVisit.h"
#import "BLTLocationSlidingWindow.h"

static NSString *const kLocationReuseIdentifier = @"BLTGridSummaryCell";
static NSString *const kShowMapSegueIdentifier = @"ShowMapSegue";
static NSString *const kShowLocationDetailSegue = @"ShowLocationDetailSegue";

typedef NS_ENUM(NSInteger, BLTPlaceDetectionStrategyType) {
  BLTPlaceDetectionStrategyTypeGrid,
  BLTPlaceDetectionStrategyTypeSlidingWindow,
};

@interface BLTGridSummariesTableViewController () <
  BLTGroupedItemsDelegate,
  BLTMapViewControllerDelegate,
  MKMapViewDelegate
>

@end

@implementation BLTGridSummariesTableViewController
{
  BLTLocationManager *_locationManager;
  BLTGroupedItems *_groupedGridSummaries;
  NSDateFormatter *_dateFormatter;
  NSDateComponentsFormatter *_dateComponentsFormatter;
  BLTPlaceVisit *_selectedPlaceVisit;
  BLTPlaceDetectionStrategyType _currentStrategyType;
}

- (void)dealloc
{
  [self.refreshControl removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
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

- (id<BLTPlaceDetectionStrategy>)_newPlaceDetectionStrategy
{
  switch (_currentStrategyType) {
    case BLTPlaceDetectionStrategyTypeGrid:
      return [[BLTGridStrategy alloc] initWithBucketDistance:10 minimumDuration:2 * 60];

    case BLTPlaceDetectionStrategyTypeSlidingWindow:
      return [[BLTLocationSlidingWindow alloc] initWithThresholdDistance:50 thresholdInterval:5 * 60];
  }
}

- (IBAction)_refresh:(id)sender
{
  [self.refreshControl beginRefreshing];
  id<BLTPlaceDetectionStrategy> strategy = [self _newPlaceDetectionStrategy];
  [_locationManager buildPlaceVisitsFromStartDate:nil endDate:nil usingStrategy:strategy callback:^(NSArray *placeVisits) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      BLTGroupedItems *groupedPlaces = [[BLTGroupedItems alloc] initWithDelegate:self];
      for (BLTPlaceVisit *placeVisit in placeVisits) {
        groupedPlaces = [groupedPlaces groupedItemsByAddingItem:placeVisit];
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
        _groupedGridSummaries = groupedPlaces;
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
  BLTPlaceVisit *placeVisit = (BLTPlaceVisit *)[_groupedGridSummaries itemForIndexPath:indexPath];
  NSString *datePart = [_dateFormatter stringFromDate:placeVisit.startDate];
  NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute
                                                                     fromDate:placeVisit.startDate
                                                                       toDate:placeVisit.endDate
                                                                      options:0];
  NSString *durationPart = [_dateComponentsFormatter stringFromDateComponents:dateComponents];
  cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", datePart, durationPart];
  return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([segue.identifier isEqualToString:kShowMapSegueIdentifier]) {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    BLTPlaceVisit *placeVisit = (BLTPlaceVisit *)[_groupedGridSummaries itemForIndexPath:indexPath];
    _selectedPlaceVisit = placeVisit;
    BLTMapViewController *mapViewController = (BLTMapViewController *)segue.destinationViewController;
    mapViewController.delegate = self;
  } else if ([segue.identifier isEqualToString:kShowLocationDetailSegue]) {
    BLTLocationRecordsTableViewController *locationRecordsTableViewController = (BLTLocationRecordsTableViewController *)segue.destinationViewController;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    BLTPlaceVisit *placeVisit = (BLTPlaceVisit *)[_groupedGridSummaries itemForIndexPath:indexPath];
    locationRecordsTableViewController.title = [BLTDateFormatterWithDayOfWeekMonthDay() stringFromDate:placeVisit.startDate];
    locationRecordsTableViewController.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
    locationRecordsTableViewController.predicate = [NSPredicate predicateWithFormat:@"timestamp >= %@ AND timestamp <= %@ AND distanceFromLastLocation > 0", placeVisit.startDate, placeVisit.endDate];
  }
}

#pragma mark - BLTMapViewControllerDelegate

- (void)mapViewController:(BLTMapViewController *)mapViewController willAppearWithMapView:(MKMapView *)mapView
{
  mapView.delegate = self;
  [mapView addOverlay:_selectedPlaceVisit.route level:MKOverlayLevelAboveRoads];
  mapView.region = [BLTLocationHelpers coordinateRegionForMultiPoint:_selectedPlaceVisit.route];
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

- (NSString *)groupedItems:(BLTGroupedItems *)groupedItems nameOfGroupForItem:(BLTPlaceVisit *)item
{
  return [BLTDateFormatterWithDayOfWeekMonthDay() stringFromDate:item.startDate];
}

- (BOOL)groupedItemsDisplayInReversedOrder:(BLTGroupedItems *)groupedItems
{
  return YES;
}

@end
