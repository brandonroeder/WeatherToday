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
    @IBOutlet weak var updatedLabel: UILabel!
    @IBOutlet weak var refreshButton: UIVisualEffectView!
    
    @IBOutlet weak var refresh: UIButton!
    
    var latitude: AnyObject?
    var longitude: AnyObject?
    var vibrantLabel = UILabel()

    required init(coder aDecoder: (NSCoder!))
    {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        preferredContentSize = CGSizeMake(view.frame.size.width, 140)
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        

//        if (self.latitude != nil && self.longitude != nil)
//        {
//            if (isFirstLaunch())
//            {
//                updateWeatherInfo(self.latitude as CLLocationDegrees, longitude: self.longitude as CLLocationDegrees, completion: nil)
//            }
//            else
//            {
//                if (secondsSinceUpdate > 3600) //if last update was more than 1 hour ago, update weather
//                {
//                    updateWeatherInfo(self.latitude as CLLocationDegrees, longitude: self.longitude as CLLocationDegrees, completion: nil)
//                }
//            }
//        }
        
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!)
    {
        locationManager.requestAlwaysAuthorization() // Ask for authorization from the User.
        locationManager.startUpdatingLocation()
        
        self.latitude = defaults?.objectForKey("latitude")
        self.longitude = defaults?.objectForKey("longitude")

        var location: String? = defaults?.stringForKey("Location")
        var temp: String? = defaults?.stringForKey("Temp")
        var humidity: String? = defaults?.stringForKey("Humidity")
        var windSpeed: String? = defaults?.stringForKey("WindSpeed")
        var weatherDescription: String? = defaults?.stringForKey("Description")
        var updateTime: Double? = defaults?.doubleForKey("UpdatedTime")
        let secondsSinceUpdate = NSDate().timeIntervalSince1970 - updateTime!
        
        if (secondsSinceUpdate > 3600) //if last update was more than 1 hour ago, update weather
        {
            updateWeatherInfo(self.latitude as! CLLocationDegrees, longitude: self.longitude as! CLLocationDegrees, completion:
                {
                    (value: Bool) in
            })
            completionHandler(.NewData)
        }

        if (temp == nil)
        {
            if (self.latitude != nil && self.longitude != nil)
            {
                updateWeatherInfo(self.latitude as! CLLocationDegrees, longitude: self.longitude as! CLLocationDegrees, completion:
                    {
                        (value: Bool) in
                    }
                )
            }
        }
        else
        {
            let dateFormatter = NSDateFormatter()
            let formattedTime = NSDate(timeIntervalSince1970: updateTime!)
            dateFormatter.dateFormat = "h:mm a"
            
            updatedLabel.text = dateFormatter.stringFromDate(formattedTime)
            locationLabel.text = location
            tempLabel.attributedText = plainStringToAttributedUnits(temp!)
            humidityLabel.text = humidity
            windLabel.text = windSpeed
        }
        
        completionHandler(.NewData)

    }

    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)
    {
        var currentLocation:CLLocationCoordinate2D = manager.location.coordinate
        
        self.latitude = currentLocation.latitude
        self.longitude = currentLocation.longitude
        
        defaults?.setValue(currentLocation.latitude, forKey: "latitude")
        defaults?.setValue(currentLocation.longitude, forKey: "longitude")
        defaults?.synchronize()
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
                defaults?.synchronize()
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
                    .responseJSON { (_, _, JSON, _) in
                        self.updateUISuccess(JSON as! NSDictionary)
                        if (completion != nil)
                        {
                            completion!(true)
                        }
        }
    }
    
    func plainStringToAttributedUnits(stringToConvert: NSString) -> NSAttributedString
    {
        var attString = NSMutableAttributedString(string: stringToConvert as String)
        var smallFont = UIFont.systemFontOfSize(33.0)
        
        attString.beginEditing()
        attString.addAttribute(NSFontAttributeName, value: (smallFont), range: NSMakeRange(stringToConvert.length - 1, 1))
        attString.addAttribute("kCTSuperscriptAttributeName", value: (1), range: NSMakeRange(stringToConvert.length - 1, 1))
        attString.addAttribute("kCTForegroundColorAttributeName", value: UIColor.blackColor(), range: NSMakeRange(0, stringToConvert.length - 1))
        attString.endEditing()

        return attString;
    }
    
    func updateUISuccess(jsonResult: NSDictionary!)
    {
        var formatter = NSNumberFormatter()
        formatter.maximumFractionDigits = 0;
        
        if let
            current_observation = jsonResult["current_observation"] as! NSDictionary?,
            display_location = current_observation["display_location"] as! NSDictionary?,
            name = display_location["full"] as! String?,
            temp_f = current_observation["temp_f"] as! Double?,
            wind = current_observation["wind_mph"] as! Double?,
            wind_dir = current_observation["wind_dir"] as! String?,
            humidity = current_observation["relative_humidity"] as! String?,
            updateTime = current_observation["observation_epoch"] as! String?
        {
            
            
            locationLabel.text = name
            defaults?.setObject(name, forKey:"Location")
            
            let tempString = formatter.stringFromNumber(temp_f)! + "°"
            tempLabel.attributedText = self.plainStringToAttributedUnits(tempString)
            defaults?.setObject(tempString, forKey:"Temp")
            
            windLabel.text = "\(wind) MPH " + wind_dir
            defaults?.setObject("\(wind) MPH " + wind_dir, forKey:"WindSpeed")

            humidityLabel.text = humidity
            defaults?.setObject(humidity, forKey:"Humidity")

            let dateFormatter = NSDateFormatter()
            let formattedTime = NSDate(timeIntervalSince1970: (updateTime as NSString).doubleValue)
            dateFormatter.dateFormat = "h:mm a"
            updatedLabel.text = dateFormatter.stringFromDate(formattedTime)
            
            defaults?.setObject(updateTime, forKey:"UpdatedTime")
        }
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets)
    {
        return UIEdgeInsetsZero
    }
}