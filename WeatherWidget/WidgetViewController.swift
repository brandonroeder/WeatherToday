//
//  WidgetViewController.swift
//  WeatherToday
//
//  Created by Brandon Roeder on 9/27/14.
//  Copyright (c) 2014 Brandon Roeder. All rights reserved.
//

import Foundation
import UIKit
import NotificationCenter
import Alamofire
import CoreLocation

var kWeatherAPIKey = "06f45665690ce19df795bd0ee5a164ac"

class WidgetViewController: UIViewController, NCWidgetProviding, CLLocationManagerDelegate
{
    let locationManager:CLLocationManager = CLLocationManager()

    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var windLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    let defaults:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        var location: String? = NSUserDefaults.standardUserDefaults().stringForKey("Location")
        var temp: String? = NSUserDefaults.standardUserDefaults().stringForKey("Temp")
        var humidity: String? = NSUserDefaults.standardUserDefaults().stringForKey("Humidity")
        var windSpeed: String? = NSUserDefaults.standardUserDefaults().stringForKey("WindSpeed")
        var weatherDescription: String? = NSUserDefaults.standardUserDefaults().stringForKey("Description")
        var updateTime: Double? = NSUserDefaults.standardUserDefaults().doubleForKey("UpdatedTime")
        
        println((NSDate().timeIntervalSince1970 - updateTime!)/60)
        

        if (location != nil && temp != nil && humidity != nil && windSpeed != nil)
        {
            if ((NSDate().timeIntervalSince1970 - updateTime!)/60 >= 15)
            {
                updateWeatherInfo(32.985678, longitude: -96.755612)
            }
            else
            {
                self.locationLabel.text = location;
                self.tempLabel.text = temp;
                self.humidityLabel.text = humidity;
                self.windLabel.text = windSpeed;
            }
        }
        else
        {
            updateWeatherInfo(32.985678, longitude: -96.755612)
        }
        
        self.preferredContentSize = CGSizeMake(self.view.frame.size.width, 110)
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!)
    {
        completionHandler(.NewData)        
    }

    @IBAction func refresh(sender: AnyObject)
    {
        updateWeatherInfo(32.985678, longitude: -96.755612)
    }
    
    func updateWeatherInfo(latitude: CLLocationDegrees, longitude: CLLocationDegrees)
    {
        Alamofire.request(.GET, "http://api.openweathermap.org/data/2.5/weather", parameters: ["lat":latitude, "lon":longitude, "cnt":0])
            .responseJSON { (_, _, JSON, _) in
                self.updateUISuccess(JSON as NSDictionary)
                println(JSON as NSDictionary)
        }
    }
    
    func updateUISuccess(jsonResult: NSDictionary!)
    {
        var formatter = NSNumberFormatter()
        formatter.maximumFractionDigits = 0;
        
        if let tempResult = ((jsonResult["main"]? as NSDictionary)["temp"] as? Double)
        {
            var temperature: Double
            
            if let sys = (jsonResult["sys"]? as? NSDictionary)
            {
                if let country = (sys["country"] as? String)
                {
                    if (country == "US")
                    {
                        // Convert temperature to Fahrenheit if user is within the US
                        temperature = round(((tempResult - 273.15) * 1.8) + 32)
                        
                        NSUserDefaults.standardUserDefaults().setObject(formatter.stringFromNumber(temperature)! + "°", forKey:"Temp")
                        NSUserDefaults.standardUserDefaults().synchronize()
                        
                        self.tempLabel.text = formatter.stringFromNumber(temperature)! + "°"
                    }
                    else
                    {
                        // Otherwise, convert temperature to Celsius
                        temperature = round(tempResult - 273.15)
                        self.tempLabel.text = formatter.stringFromNumber(temperature)! + "°"
                    }
                }
                
                if let updateTime = jsonResult["dt"] as? Double
                {
                    NSUserDefaults.standardUserDefaults().setObject(updateTime, forKey:"UpdatedTime")
                    NSUserDefaults.standardUserDefaults().synchronize()
                }
                
                if let name = jsonResult["name"] as? String
                {
                    self.locationLabel.text = name + ", TX";
                    
                    NSUserDefaults.standardUserDefaults().setObject(name + ", TX", forKey:"Location")
                    NSUserDefaults.standardUserDefaults().synchronize()
                }

                if let main = jsonResult["main"]? as? NSDictionary
                {
                    var humidity = main["humidity"] as Double
                    var pressure = main["pressure"] as Double
                    
                    self.humidityLabel.text = "Humidity: " + formatter.stringFromNumber(humidity)! + "%"
                    
                    NSUserDefaults.standardUserDefaults().setObject("Humidity: " + formatter.stringFromNumber(humidity)! + "%", forKey:"Humidity")
                    NSUserDefaults.standardUserDefaults().synchronize()
                }
                
                if let wind = jsonResult["wind"]? as? NSDictionary
                {
                    var windSpeed = wind["speed"] as Double
                    self.windLabel.text = "Wind: " + formatter.stringFromNumber(windSpeed)! + " MPH"
                    
                    NSUserDefaults.standardUserDefaults().setObject("Wind: " + formatter.stringFromNumber(windSpeed)! + " MPH", forKey:"WindSpeed")
                    NSUserDefaults.standardUserDefaults().synchronize()
                }

                if let weather = jsonResult["weather"]? as? NSArray
                {
                    var condition = (weather[0] as NSDictionary)["id"] as Int
                    var weatherDescription = (weather[0] as NSDictionary)["description"] as String
                    var sunrise = sys["sunrise"] as Double
                    var sunset = sys["sunset"] as Double
                
//                    self.descriptionLabel.text = weatherDescription;
//                    NSUserDefaults.standardUserDefaults().setObject(weatherDescription, forKey:"Description")
//                    NSUserDefaults.standardUserDefaults().synchronize()
                }
            }
        }
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets)
    {
        return UIEdgeInsetsZero
    }
}