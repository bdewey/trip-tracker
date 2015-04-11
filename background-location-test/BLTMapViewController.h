//
//  BLTMapViewController.h
//  background-location-test
//
//  Created by Brian Dewey on 4/3/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class MKPolyline;

@protocol BLTMapViewControllerDelegate;

@interface BLTMapViewController : UIViewController

@property (nonatomic, readwrite, weak) id<BLTMapViewControllerDelegate> delegate;

@end

@protocol BLTMapViewControllerDelegate <MKMapViewDelegate, NSObject>

- (void)mapViewController:(BLTMapViewController *)mapViewController willAppearWithMapView:(MKMapView *)mapView;

@end
