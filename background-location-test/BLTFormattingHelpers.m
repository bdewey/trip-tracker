//
//  BLTFormattingHelpers.m
//  background-location-test
//
//  Created by Brian Dewey on 5/10/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import "BLTFormattingHelpers.h"

NSDateFormatter *BLTDateFormatterWithDayOfWeekMonthDay(void)
{
  static NSDateFormatter *dateFormatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dateFormatter = [[NSDateFormatter alloc] init];
    NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"EEEEMMMMdd" options:0 locale:[NSLocale currentLocale]];
    dateFormatter.dateFormat = formatString;
  });
  return dateFormatter;
}

