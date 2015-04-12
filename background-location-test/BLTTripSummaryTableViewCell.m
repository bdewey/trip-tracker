//
//  BLTTripSummaryTableViewCell.m
//  background-location-test
//
//  Created by Brian Dewey on 4/12/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import "BLTStatisticsSummary.h"
#import "BLTTrip.h"
#import "BLTTripSummaryTableViewCell.h"

static NSDateFormatter *_DateFormatter()
{
  static NSDateFormatter *dateFormatter = nil;
  if (dateFormatter == nil) {
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterNoStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
  }
  return dateFormatter;
}

static NSDateComponentsFormatter *_DurationFormatter()
{
  static NSDateComponentsFormatter *durationFormatter = nil;
  if (durationFormatter == nil) {
    durationFormatter = [[NSDateComponentsFormatter alloc] init];
    durationFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
  }
  return durationFormatter;
}

static NSLengthFormatter *_LengthFormatter()
{
  static NSLengthFormatter *lengthFormatter = nil;
  if (lengthFormatter == nil) {
    lengthFormatter = [[NSLengthFormatter alloc] init];
    lengthFormatter.unitStyle = NSFormattingUnitStyleLong;
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.usesSignificantDigits = YES;
    numberFormatter.minimumSignificantDigits = 1;
    numberFormatter.maximumSignificantDigits = 3;
    lengthFormatter.numberFormatter = numberFormatter;
  }
  return lengthFormatter;
}

static NSString *_ConvertLengthForcingYardsToFeet(double meters)
{
  static const double kFeetPerMeter = 3.28084;
  NSLengthFormatterUnit unit;
  NSLengthFormatter *formatter = _LengthFormatter();
  [formatter unitStringFromMeters:meters usedUnit:&unit];
  if (unit == NSLengthFormatterUnitYard) {
    double feet = meters * kFeetPerMeter;
    return [NSString stringWithFormat:@"%@ feet", [formatter.numberFormatter stringFromNumber:@(feet)]];
  } else {
    return [formatter stringFromMeters:meters];
  }
}

@interface BLTTripSummaryTableViewCell ()

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet UILabel *speedLabel;
@property (strong, nonatomic) IBOutlet UILabel *accelerationLabel;
@property (strong, nonatomic) IBOutlet UILabel *altitudeLabel;
@property (strong, nonatomic) IBOutlet UILabel *durationLabel;

@end

@implementation BLTTripSummaryTableViewCell

- (void)setTrip:(BLTTrip *)trip
{
  self.titleLabel.text = [_DateFormatter() stringFromDate:trip.startDate];
  NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute
                                                                     fromDate:trip.startDate
                                                                       toDate:trip.endDate
                                                                      options:0];
  self.durationLabel.text = [_DurationFormatter() stringFromDateComponents:dateComponents];
  self.distanceLabel.text = _ConvertLengthForcingYardsToFeet(trip.distance);
  self.speedLabel.text = [NSString stringWithFormat:@"Average speed: %0.2f m/s", trip.locationSpeedSummary.mean];
  self.accelerationLabel.text = [NSString stringWithFormat:@"Max acceleration: %0.2f m/s^2", trip.locationAccelerationSummary.max];
  self.altitudeLabel.text = [NSString stringWithFormat:@"Elevation gain: %@", _ConvertLengthForcingYardsToFeet(trip.altitudeGain)];
}

@end
