//
//  BLTGraphViewController.h
//  background-location-test
//
//  Created by Brian Dewey on 5/24/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BLTDatabase;

@interface BLTGraphViewController : UIViewController

@property (nonatomic, readwrite, strong) NSDate *startDate;
@property (nonatomic, readwrite, strong) NSDate *endDate;
@property (nonatomic, readwrite, strong) BLTDatabase *database;

@end
