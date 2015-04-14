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
import QuartzCore
import CoreText
import Cartography

var kWundergroundAPIKey = "da8c1b0d02f335f8"

class WidgetViewController: UIViewController, NCWidgetProviding, CLLocationManagerDelegate
{
    let defaults =  NSUserDefaults(suiteName: "group.brandonroeder.WeatherToday")
    let locationManager = CLLocationManager()
    var flag = Bool()
    var result = false

    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var windLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet var maxTempLabel: UILabel!
    @IBOutlet var minTempLabel: UILabel!
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
        
        preferredContentSize = CGSizeMake(view.frame.size.width, 130)

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestAlwaysAuthorization() // Ask for authorization from the User.
        locationManager.startUpdatingLocation()
        
        self.latitude = defaults?.objectForKey("latitude")
        self.longitude = defaults?.objectForKey("longitude")
        
        if let
            location = defaults?.stringForKey("location") as String?,
            temp = defaults?.stringForKey("temp") as String?,
            high = defaults?.stringForKey("high") as String?,
            low  = defaults?.stringForKey("low") as String?,
            humidity = defaults?.stringForKey("humidity") as String?,
            windSpeed = defaults?.stringForKey("wind") as String?,
            conditions = defaults?.stringForKey("conditions") as String?,
            updateTime = defaults?.doubleForKey("updatedTime") as Double?,
            secondsSinceUpdate = NSDate().timeIntervalSince1970 - updateTime as Double?,
            formattedTime = NSDate(timeIntervalSince1970: updateTime) as NSDate?
        {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "h:mm a"
            
            updatedLabel.text = dateFormatter.stringFromDate(formattedTime)
            locationLabel.text = location
            descriptionLabel.text = conditions
            tempLabel.text = temp + "°"
            maxTempLabel.text = high + "°"
            minTempLabel.text = low + "°"
            humidityLabel.text = humidity
            windLabel.text = windSpeed
        }
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!)
    {
        let temp = defaults?.stringForKey("temp")

        let updateTime = defaults?.doubleForKey("updatedTime")
        let secondsSinceUpdate = NSDate().timeIntervalSince1970 - updateTime!
        
        if (secondsSinceUpdate > 3600) //if last update was more than 1 hour ago, update weather
        {
            updateWeatherInfo(self.latitude as! CLLocationDegrees, longitude: self.longitude as! CLLocationDegrees, completion:
                {
                    (value: Bool) in
            })
            completionHandler(.NewData)
        }

        if (temp == nil && self.latitude != nil && self.longitude != nil)
        {
            updateWeatherInfo(self.latitude as! CLLocationDegrees, longitude: self.longitude as! CLLocationDegrees, completion:
                {
                    (value: Bool) in
                    
                    completionHandler(.NewData)
                })
        }
    }

    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)
    {
        var currentLocation:CLLocationCoordinate2D = manager.location.coordinate
        
        self.latitude = currentLocation.latitude
        self.longitude = currentLocation.longitude
        
        defaults?.setValue(currentLocation.latitude, forKey: "latitude")
        defaults?.setValue(currentLocation.longitude, forKey: "longitude")
    }

    @IBAction func refresh(sender: AnyObject)
    {
        var angle = -20*M_PI
        var rotate : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotate.removedOnCompletion = false
        rotate.fillMode = kCAFillModeForwards
        rotate.toValue = angle
        rotate.duration = 10
        rotate.repeatCount = 11
        rotate.cumulative = true
        rotate.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        refresh.layer.addAnimation(rotate, forKey: "rotateAnimation")

        updateWeatherInfo(self.latitude as! CLLocationDegrees, longitude: self.longitude as! CLLocationDegrees, completion:
            {
                (value: Bool) in
                self.refresh.layer.removeAllAnimations()
        })
    }
    
    func isFirstLaunch() -> Bool
    {
        if (!flag)
        {
            if ((defaults?.boolForKey("hasLaunchedOnce")) != nil)
            {
                result = false
            }
            else
            {
                defaults?.setBool(true, forKey: "hasLaunchedOnce")
            }
            
            flag = true
        }
        
        return result
    }
    
    @IBAction func launchApp(sender: AnyObject)
    {
        var appURL: NSURL = NSURL(string: "mainapp://")!
        extensionContext?.openURL(appURL, completionHandler: nil)
    }
    
    func updateWeatherInfo(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: ((Bool) -> Void)?)
    {
        var coordinates = "\(latitude),\(longitude)"
        Alamofire.request(.GET, "http://api.wunderground.com/api/" + kWundergroundAPIKey + "/forecast/geolookup/conditions/q/" + coordinates + ".json")
                    .responseJSON { (_, _, json, _) in
                        self.updateUISuccess(json as! NSDictionary)
                        if (completion != nil)
                        {
                            completion!(true)
                        }
        }
    }
    
    func updateUISuccess(jsonResult: NSDictionary!)
    {
        let formatter = NSNumberFormatter()
        formatter.maximumFractionDigits = 0;
        
        if let
            forecast = jsonResult["forecast"] as! NSDictionary?,
            simpleForecast = forecast["simpleforecast"] as! NSDictionary?,
            dayForecast = simpleForecast["forecastday"] as! NSArray?,
            currentForecast = dayForecast.firstObject as! NSDictionary?,
            high = currentForecast["high"] as! NSDictionary?,
            low = currentForecast["low"] as! NSDictionary?,
            highTemp = high["fahrenheit"] as! String?,
            lowTemp = low["fahrenheit"] as! String?,
            current_observation = jsonResult["current_observation"] as! NSDictionary?,
            display_location = current_observation["display_location"] as! NSDictionary?,
            name = display_location["full"] as! String?,
            temp_f = current_observation["temp_f"] as! Double?,
            conditions = current_observation["weather"] as! String?,
            wind = current_observation["wind_mph"] as! Double?,
            wind_dir = current_observation["wind_dir"] as! String?,
            humidity = current_observation["relative_humidity"] as! String?,
            updateTime = current_observation["observation_epoch"] as! String?
        {
            locationLabel.text = name
            defaults?.setObject(name, forKey:"location")
            
            maxTempLabel.text = highTemp + "°"
            defaults?.setObject(highTemp, forKey:"high")

            minTempLabel.text = lowTemp + "°"
            defaults?.setObject(lowTemp, forKey:"low")

            let tempString = formatter.stringFromNumber(temp_f)
            tempLabel.text = tempString! + "°"
            defaults?.setObject(tempString, forKey:"temp")
            
            descriptionLabel.text = conditions
            defaults?.setObject(conditions, forKey: "conditions")
            
            windLabel.text = "\(wind) MPH " + wind_dir
            defaults?.setObject("\(wind) MPH " + wind_dir, forKey:"wind")

            humidityLabel.text = humidity
            defaults?.setObject(humidity, forKey:"humidity")

            let dateFormatter = NSDateFormatter()
            let formattedTime = NSDate(timeIntervalSince1970: (updateTime as NSString).doubleValue)
            dateFormatter.dateFormat = "h:mm a"
            updatedLabel.text = dateFormatter.stringFromDate(formattedTime)
            
            defaults?.setObject(updateTime, forKey:"updatedTime")
        }
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets)
    {
        return UIEdgeInsetsZero
    }
}