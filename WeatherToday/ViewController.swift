//
//  ViewController.swift
//  WeatherToday
//
//  Created by Brandon Roeder on 9/29/14.
//  Copyright (c) 2014 Brandon Roeder. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import Alamofire
import CoreLocation
import CoreText

let kWundergroundAPIKey = "da8c1b0d02f335f8"

class ViewController: UIViewController, CLLocationManagerDelegate
{
    let defaults =  NSUserDefaults(suiteName: "group.brandonroeder.WeatherToday")
    let locationManager = CLLocationManager()
    var latitude = CLLocationDegrees()
    var longitude = CLLocationDegrees()
    
    @IBOutlet weak var locationLabel: UILabel!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        locationManager.requestAlwaysAuthorization() // Ask for authorization from the User.
        locationManager.requestWhenInUseAuthorization()

        let location = self.defaults?.stringForKey("location")
        locationLabel.text = location
        
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            locationManager.distanceFilter = 1000.0
            locationManager.startUpdatingLocation()            
        }
        
        view.backgroundColor = UIColor(patternImage: UIImage(named: "background_alt.png")!)
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)
    {
        let currentLocation = manager.location.coordinate
        
        self.latitude = currentLocation.latitude
        self.longitude = currentLocation.longitude
        
        self.updateWeatherInfo(currentLocation.latitude, longitude: currentLocation.longitude, completion: nil)

        self.defaults?.setValue(currentLocation.latitude, forKey: "latitude")
        self.defaults?.setValue(currentLocation.longitude, forKey: "longitude")
    }
    
    func updateWeatherInfo(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: ((Bool) -> Void)?)
    {
        let coordinates = "\(latitude),\(longitude)"
        Alamofire.request(.GET, "http://api.wunderground.com/api/" + kWundergroundAPIKey + "/forecast/geolookup/conditions/q/" + coordinates + ".json")
            .responseJSON { (_, _, JSON, _) in
                self.storeJson(JSON as! NSDictionary)
        }
    }
    
    func storeJson(jsonResult: NSDictionary!)
    {
        let appDomain = NSBundle .mainBundle().bundleIdentifier
        self.defaults?.removePersistentDomainForName(appDomain!)
        
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
            let tempString = formatter.stringFromNumber(temp_f)
            
            defaults?.setObject(name, forKey:"location")
            defaults?.setObject(highTemp, forKey:"high")
            defaults?.setObject(lowTemp, forKey:"low")
            defaults?.setObject(conditions, forKey:"conditions")
            defaults?.setObject(tempString, forKey:"temp")
            defaults?.setObject("\(wind) MPH " + wind_dir, forKey:"wind")
            defaults?.setObject(humidity, forKey:"humidity")
            
            let dateFormatter = NSDateFormatter()
            let formattedTime = NSDate(timeIntervalSince1970: (updateTime as NSString).doubleValue)
            dateFormatter.dateFormat = "h:mm a"
            
            let date = NSDate()
            defaults?.setObject(date, forKey:"lastUpdatedTime")
        }
    }
    
    func textField(textField: UITextField!, shouldChangeCharactersInRange range: NSRange, replacementString string: String!) -> Bool
    {
        let maxLength = count(textField.text!) + count(string!) - range.length
        return maxLength <= 5 //Bool
    }
}
