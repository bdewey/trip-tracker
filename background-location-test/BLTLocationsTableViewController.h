//
//  BLTLocationsTableViewController.h
//  background-location-test
//
//  Created by Brian Dewey on 4/1/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BLTDatabase;

@interface BLTLocationsTableViewController : UITableViewController

@property (nonatomic, readwrite, strong) NSPredicate *locationFilterPredicate;

@end
