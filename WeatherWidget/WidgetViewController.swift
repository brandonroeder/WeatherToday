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
    let defaults =  NSUserDefaults(suiteName: "group.brandonroeder.WeatherToday")

    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var windLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var updatedLabel: UILabel!
    @IBOutlet weak var refreshButton: UIVisualEffectView!
    
    @IBOutlet weak var refresh: UIButton!
    
    var latitude: AnyObject?
    var longitude: AnyObject?
    
    required init(coder aDecoder: (NSCoder!))
    {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.preferredContentSize = CGSizeMake(self.view.frame.size.width, 110)
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.latitude = self.defaults?.objectForKey("latitude")
        self.longitude = self.defaults?.objectForKey("longitude")

        var location: String? = self.defaults?.stringForKey("Location")
        var temp: String? = self.defaults?.stringForKey("Temp")
        var humidity: String? = self.defaults?.stringForKey("Humidity")
        var windSpeed: String? = self.defaults?.stringForKey("WindSpeed")
        var weatherDescription: String? = self.defaults?.stringForKey("Description")
        var updateTime: Double? = self.defaults?.doubleForKey("UpdatedTime")
        
        let dateFormatter = NSDateFormatter()
        let formattedTime = NSDate(timeIntervalSince1970: updateTime!)
        dateFormatter.dateFormat = "MMM d — h:m a"
        
        self.updatedLabel.text = dateFormatter.stringFromDate(formattedTime)
        self.locationLabel.text = location;
        self.tempLabel.text = temp;
        self.humidityLabel.text = humidity;
        self.windLabel.text = windSpeed;
    }

    @IBAction func refresh(sender: AnyObject)
    {
        var rotate : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotate.removedOnCompletion = false
        rotate.fillMode = kCAFillModeForwards
        
        var angle = -20*M_PI
        
        rotate.toValue = angle
        rotate.duration = 10
        rotate.repeatCount = 11
        rotate.cumulative = true
        rotate.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        self.refresh.layer.addAnimation(rotate, forKey: "rotateAnimation")

        updateWeatherInfo(self.latitude as CLLocationDegrees, longitude: self.longitude as CLLocationDegrees, completion:
            {
                (value: Bool) in
                println("IT WORKED")
                self.refresh.layer.removeAllAnimations()
        })
    }
    
    
    @IBAction func launchApp(sender: AnyObject)
    {
        var appURL: NSURL = NSURL(string: "mainapp://" )!
        self.extensionContext?.openURL(appURL, completionHandler: nil)
    }
    
    func updateWeatherInfo(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: ((Bool) -> Void)?)
    {
        Alamofire.request(.GET, "http://api.openweathermap.org/data/2.5/weather", parameters: ["lat":latitude, "lon":longitude, "cnt":0, "APPID":kWeatherAPIKey])
            .responseJSON { (_, _, JSON, _) in
                self.updateUISuccess(JSON as NSDictionary)
                completion!(true)
                println(JSON as NSDictionary)
        }
    }
    
    func updateUISuccess(jsonResult: NSDictionary!)
    {
        let appDomain = NSBundle .mainBundle().bundleIdentifier
        self.defaults?.removePersistentDomainForName(appDomain!)
        
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
                        
                        self.defaults?.setObject(formatter.stringFromNumber(temperature)! + "°", forKey:"Temp")
                        self.defaults?.synchronize()
                        
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
                    let dateFormatter = NSDateFormatter()
                    let formattedTime = NSDate(timeIntervalSince1970: updateTime)
                    dateFormatter.dateFormat = "MMM d — h:m a"
                    self.updatedLabel.text = dateFormatter.stringFromDate(formattedTime)

                    self.defaults?.setObject(updateTime, forKey:"UpdatedTime")
                    self.defaults?.synchronize()
                }
                
                if let name = jsonResult["name"] as? String
                {
                    self.locationLabel.text = name + ", TX";
                    
                    self.defaults?.setObject(name + ", TX", forKey:"Location")
                    self.defaults?.synchronize()
                }

                if let main = jsonResult["main"]? as? NSDictionary
                {
                    var humidity = main["humidity"] as Double
                    var pressure = main["pressure"] as Double
                    
                    self.humidityLabel.text = "Humidity: " + formatter.stringFromNumber(humidity)! + "%"
                    
                    self.defaults?.setObject("Humidity: " + formatter.stringFromNumber(humidity)! + "%", forKey:"Humidity")
                    self.defaults?.synchronize()
                }
                
                if let wind = jsonResult["wind"]? as? NSDictionary
                {
                    var windSpeed = wind["speed"] as Double
                    self.windLabel.text = "Wind: " + formatter.stringFromNumber(windSpeed)! + " MPH"
                    
                    self.defaults?.setObject("Wind: " + formatter.stringFromNumber(windSpeed)! + " MPH", forKey:"WindSpeed")
                    self.defaults?.synchronize()
                }

                if let weather = jsonResult["weather"]? as? NSArray
                {
                    var condition = (weather[0] as NSDictionary)["id"] as Int
                    var weatherDescription = (weather[0] as NSDictionary)["description"] as String
                    var sunrise = sys["sunrise"] as Double
                    var sunset = sys["sunset"] as Double
                }
            }
        }
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets)
    {
        return UIEdgeInsetsZero
    }
}