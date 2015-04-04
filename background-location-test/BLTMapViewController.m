//
//  BLTMapViewController.m
//  background-location-test
//
//  Created by Brian Dewey on 4/3/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "BLTMapViewController.h"

@interface BLTMapViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation BLTMapViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.mapView.centerCoordinate = _coordinate;
  self.mapView.region = MKCoordinateRegionMakeWithDistance(_coordinate, 500, 500);
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
