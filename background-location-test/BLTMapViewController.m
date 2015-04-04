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

- (void)viewDidLoad
{
  [super viewDidLoad];
  MKMapView *mapView = self.mapView;
  if (_route != nil) {
    [mapView addOverlay:_route level:MKOverlayLevelAboveRoads];
    mapView.centerCoordinate = _route.coordinate;
    mapView.region = MKCoordinateRegionMakeWithDistance(_route.coordinate, 500, 500);
  } else {
    mapView.centerCoordinate = _coordinate;
    mapView.region = MKCoordinateRegionMakeWithDistance(_coordinate, 500, 500);
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
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

@end
