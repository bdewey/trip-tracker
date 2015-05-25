//
//  BLTGraphViewController.m
//  background-location-test
//
//  Created by Brian Dewey on 5/24/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "BLTDatabase.h"
#import "BLTGraphViewController.h"
#import "BLTLocation.h"

#import "JBChartView.h"
#import "JBLineChartView.h"

@interface BLTGraphViewController () <JBLineChartViewDataSource, JBLineChartViewDelegate>

@property (nonatomic, readwrite, copy) NSArray *speeds;

@end

@implementation BLTGraphViewController
{
  JBLineChartView *_lineChartView;
}

- (void)dealloc
{
  _lineChartView.delegate = nil;
  _lineChartView.dataSource = nil;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  _lineChartView = [[JBLineChartView alloc] initWithFrame:CGRectZero];
  _lineChartView.delegate = self;
  _lineChartView.dataSource = self;
  _lineChartView.translatesAutoresizingMaskIntoConstraints = NO;
  _lineChartView.showsVerticalSelection = YES;
  [self.view addSubview:_lineChartView];
  
  id topLayoutGuide = self.topLayoutGuide;
  id bottomLayoutGuide = self.bottomLayoutGuide;
  NSDictionary *views = NSDictionaryOfVariableBindings(_lineChartView, topLayoutGuide, bottomLayoutGuide);
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide]-[_lineChartView]-[bottomLayoutGuide]"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:views]];
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_lineChartView]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:views]];
  [self.view layoutSubviews];
  [self _refresh];
}

- (void)viewDidLayoutSubviews
{
  [_lineChartView reloadData];
}

#pragma mark - Properties

- (void)setStartDate:(NSDate *)startDate
{
  if (![_startDate isEqualToDate:startDate]) {
    _startDate = startDate;
    [self _refresh];
  }
}

- (void)setEndDate:(NSDate *)endDate
{
  if (![_endDate isEqualToDate:endDate]) {
    _endDate = endDate;
    [self _refresh];
  }
}

- (void)setDatabase:(BLTDatabase *)database
{
  if (_database != database) {
    _database = database;
    [self _refresh];
  }
}

- (void)setSpeeds:(NSArray *)speeds
{
  if (_speeds != speeds) {
    _speeds = [speeds copy];
    [_lineChartView reloadData];
  }
}

#pragma mark - Private

- (void)_refresh
{
  if ((_startDate == nil) || (_endDate == nil) || (_database == nil) || !self.isViewLoaded) {
    return;
  }
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"BLTLocation"];
  NSSortDescriptor *sortByTimestamp = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
  fetchRequest.sortDescriptors = @[sortByTimestamp];
  fetchRequest.predicate = [NSPredicate predicateWithFormat:@"timestamp >= %@ AND timestamp <= %@", _startDate, _endDate];
  NSManagedObjectContext *moc = _database.defaultBackgroundManagedObjectContext;
  [moc performBlock:^{
    NSArray *results = [moc executeFetchRequest:fetchRequest error:NULL];
    NSMutableArray *speeds = [[NSMutableArray alloc] initWithCapacity:results.count];
    for (BLTLocation *location in results) {
      [speeds addObject:@(location.speed)];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      self.speeds = speeds;
    });
  }];
}

#pragma mark - JBChartViewDataSource

- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView
{
  return 1;
}

- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex
{
  return _speeds.count;
}

#pragma mark - JBLineChartViewDelegate

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView
verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex
             atLineIndex:(NSUInteger)lineIndex
{
  double speed = [[_speeds objectAtIndex:horizontalIndex] doubleValue];
  return (speed == -1) ? NAN : speed;
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView widthForLineAtLineIndex:(NSUInteger)lineIndex
{
  return 1;
}

@end
