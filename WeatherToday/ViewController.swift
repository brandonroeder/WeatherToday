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

var kWundergroundAPIKey = *Inset Wunderground API Key here*

class ViewController: UIViewController, CLLocationManagerDelegate
{
    let defaults =  NSUserDefaults(suiteName: "group.brandonroeder.WeatherToday")
    let locationManager = CLLocationManager()
    let latitude = CLLocationDegrees()
    let longitude = CLLocationDegrees()
    
    @IBOutlet weak var locationLabel: UILabel!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.locationManager.requestAlwaysAuthorization() // Ask for authorization from the User.
        self.locationManager.requestWhenInUseAuthorization()

        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "background_alt.png")!)
        var location: String? = self.defaults?.stringForKey("Location")

        if (location != nil)
        {
            self.locationLabel.text = location
        }
        
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        self.updateWeatherInfo(self.latitude, longitude: self.longitude, completion: nil)
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)
    {
        var currentLocation:CLLocationCoordinate2D = manager.location.coordinate
        println("locations = \(currentLocation.latitude) \(currentLocation.longitude)")
        self.defaults?.setValue(currentLocation.latitude, forKey: "latitude")
        self.defaults?.setValue(currentLocation.longitude, forKey: "longitude")
        self.defaults?.synchronize()
    }
    
    func updateWeatherInfo(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: ((Bool) -> Void)?)
    {
        var coordinates = "\(latitude),\(longitude)"
        Alamofire.request(.GET, "http://api.wunderground.com/api/" + kWundergroundAPIKey + "/forecast/geolookup/conditions/q/" + coordinates + ".json")
            .responseJSON { (_, _, JSON, _) in
                self.storeJson(JSON as NSDictionary)
        }
    }
    
    func plainStringToAttributedUnits(stringToConvert: NSString) -> NSAttributedString
    {
        //function to superscript the temp degree symbol
        
        var attString = NSMutableAttributedString(string: stringToConvert)
        var smallFont = UIFont.systemFontOfSize(33.0)
        
        attString.beginEditing()
        attString.addAttribute(NSFontAttributeName, value: (smallFont), range: NSMakeRange(stringToConvert.length - 1, 1))
        attString.addAttribute(kCTSuperscriptAttributeName, value: (1), range: NSMakeRange(stringToConvert.length - 1, 1))
        attString.addAttribute(kCTForegroundColorAttributeName, value: UIColor.blackColor(), range: NSMakeRange(0, stringToConvert.length - 1))
        attString.endEditing()
        
        return attString;
    }
    
    func storeJson(jsonResult: NSDictionary!)
    {
        let appDomain = NSBundle .mainBundle().bundleIdentifier
        self.defaults?.removePersistentDomainForName(appDomain!)
        
        var formatter = NSNumberFormatter()
        formatter.maximumFractionDigits = 0;
        
        if let current_observation = ((jsonResult["current_observation"]? as? NSDictionary))
        {
            if let display_location = (current_observation["display_location"]? as? NSDictionary)
            {
                if let name = display_location["full"]? as String?
                {
                    self.locationLabel.text = name
                    
                    self.defaults?.setObject(name, forKey:"Location")
                    self.defaults?.synchronize()
                }
            }
            
            if let temp_f = current_observation["temp_f"]? as Double?
            {
                let tempString = formatter.stringFromNumber(temp_f)! + "°"
                
                self.defaults?.setObject(tempString, forKey:"Temp")
                self.defaults?.synchronize()
            }
            
            if let wind = current_observation["wind_mph"]? as Double?
            {
                if let wind_dir = current_observation["wind_dir"]? as? String
                {
                    self.defaults?.setObject("Wind: \(wind) MPH " + wind_dir, forKey:"WindSpeed")
                    self.defaults?.synchronize()
                }
            }
            
            if let humidity = current_observation["relative_humidity"]? as? String
            {
                self.defaults?.setObject("Humidity: " + humidity, forKey:"Humidity")
                self.defaults?.synchronize()
            }
            
            if let updateTime = current_observation["observation_epoch"]? as? String
            {
                let dateFormatter = NSDateFormatter()
                let formattedTime = NSDate(timeIntervalSince1970: (updateTime as NSString).doubleValue)
                dateFormatter.dateFormat = "MMM d — h:mm a"
                
                self.defaults?.setObject(updateTime, forKey:"UpdatedTime")
                self.defaults?.synchronize()
            }
        }
    }
    
    func textField(textField: UITextField!, shouldChangeCharactersInRange range: NSRange, replacementString string: String!) -> Bool
    {
        let maxLength = countElements(textField.text!) + countElements(string!) - range.length
        return maxLength <= 5 //Bool
    }
}
