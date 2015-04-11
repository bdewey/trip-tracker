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

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  MKMapView *mapView = self.mapView;
  MKCoordinateRegion region;
  if (_route != nil) {
    [mapView addOverlay:_route level:MKOverlayLevelAboveRoads];
    region = [[self class] _coordinateRegionForMultiPoint:_route];
  } else {
    region = MKCoordinateRegionMakeWithDistance(_coordinate, 500, 500);
  }
  [mapView setRegion:region animated:YES];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
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

@end
