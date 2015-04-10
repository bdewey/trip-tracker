//
//  BLTMapViewController.h
//  background-location-test
//
//  Created by Brian Dewey on 4/3/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MKPolyline;

@interface BLTMapViewController : UIViewController

@property (nonatomic, readwrite, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, readwrite, strong) MKPolyline *route;

@end