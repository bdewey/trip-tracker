//
//  BLTLocationRecordsTableViewController.h
//  background-location-test
//
//  Created by Brian Dewey on 5/11/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BLTLocationRecordsTableViewController : UITableViewController

@property (nonatomic, readwrite, strong) NSPredicate *predicate;
@property (nonatomic, readwrite, copy) NSArray *sortDescriptors;

@end
