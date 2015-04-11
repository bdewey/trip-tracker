//
//  BLTMapViewController.m
//  background-location-test
//
//  Created by Brian Dewey on 4/3/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "BLTMapViewController.h"

@interface BLTMapViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation BLTMapViewController
{
  MKCoordinateRegion _annotationRegion;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self.delegate mapViewController:self willAppearWithMapView:self.mapView];
  _annotationRegion = self.mapView.region;
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.mapView setRegion:_annotationRegion animated:animated];
}

@end
