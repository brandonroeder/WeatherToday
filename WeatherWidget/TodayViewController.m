//
//  TodayViewController.m
//  WeatherWidget
//
//  Created by Brandon Roeder on 9/25/14.
//  Copyright (c) 2014 Brandon Roeder. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

const NSString *kWundergroundKey = @"da8c1b0d02f335f8";

@interface TodayViewController () <NCWidgetProviding>

@end

@implementation TodayViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.preferredContentSize = CGSizeMake(600, 100);
    [self retrieveWeatherForZipCode:@"75081"];
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler
{

    completionHandler(NCUpdateResultNewData);
}

- (IBAction)refresh:(id)sender
{
    [self widgetPerformUpdateWithCompletionHandler:^(NCUpdateResult result)
    {
        [self retrieveWeatherForZipCode:@"75081"];
    }];
}

#pragma mark - Methods for retrieving weather from Wunderground

- (void)retrieveWeatherForZipCode:(NSString *)zipCode
{
    NSString *urlString;
    
    if ([zipCode length] == 5)
    {
        urlString = [NSString stringWithFormat:@"http://api.wunderground.com/api/%@/conditions/q/%@.json",
                     kWundergroundKey,
                     zipCode];
    }
    
    NSData *weatherData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
    
    NSError *error;
    id weatherResults = [NSJSONSerialization JSONObjectWithData:weatherData options:0 error:&error];
    
    NSDictionary *currentObservation = weatherResults[@"current_observation"];
    NSDictionary *locationInfo = currentObservation[@"display_location"];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setMaximumFractionDigits:0];

    NSString *weatherDescription = currentObservation[@"weather"];
    NSNumber *tempF = currentObservation[@"temp_f"];
    NSString *feelsLikeF = currentObservation[@"feelslike_f"];
    NSNumber *windSpeed = currentObservation[@"wind_mph"];
    NSString *windDirection = currentObservation[@"wind_dir"];
    NSString *windSpeedSpaced = [[windSpeed stringValue] stringByAppendingString:@" mph "];
    NSString *humidity = currentObservation[@"relative_humidity"];
    NSString *updatedTime = currentObservation[@"observation_time"];
    
    self.lastUpdated.text = updatedTime;
    self.locationLabel.text = locationInfo[@"full"];
    self.feelsLikeLabel.text = [feelsLikeF stringByAppendingString:@"°"];
    self.windLabel.text = [windSpeedSpaced stringByAppendingString:windDirection];
    self.humidityLabel.text = humidity;
    self.tempLabel.text = [[formatter stringFromNumber:tempF] stringByAppendingString:@"°"];
}


@end
