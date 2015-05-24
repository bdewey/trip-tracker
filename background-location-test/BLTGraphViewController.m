//
//  BLTGraphViewController.m
//  background-location-test
//
//  Created by Brian Dewey on 5/24/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import "BLTGraphViewController.h"

#import "JBChartView.h"
#import "JBLineChartView.h"

@interface BLTGraphViewController () <JBLineChartViewDataSource, JBLineChartViewDelegate>

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
}

- (void)viewDidLayoutSubviews
{
  [_lineChartView reloadData];
}

#pragma mark - JBChartViewDataSource

- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView
{
  return 1;
}

- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex
{
  return 100;
}

#pragma mark - JBLineChartViewDelegate

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView
verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex
             atLineIndex:(NSUInteger)lineIndex
{
  return horizontalIndex * horizontalIndex;
}

@end
