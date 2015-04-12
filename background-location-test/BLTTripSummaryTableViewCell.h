//
//  BLTTripSummaryTableViewCell.h
//  background-location-test
//
//  Created by Brian Dewey on 4/12/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BLTTrip;

@interface BLTTripSummaryTableViewCell : UITableViewCell

@property (nonatomic, readwrite, strong) BLTTrip *trip;

@end
