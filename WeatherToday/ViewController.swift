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

class ViewController: UIViewController, UITextFieldDelegate
{
    @IBOutlet weak var zipcodeField: UITextField!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.zipcodeField.delegate = self;
        self.zipcodeField.borderStyle = UITextBorderStyle.None
        self.zipcodeField.setNeedsDisplay()
        self.zipcodeField.becomeFirstResponder()
    }
    
    @IBAction func fetch(sender: AnyObject)
    {
        self.zipcodeField.resignFirstResponder()
        self.getLocation(self.zipcodeField.text)

    }
    func getLocation(zipcode: String)
    {
        var fetchURL = "http://maps.google.com/maps/api/geocode/json?address=" + zipcode + "&sensor=false"
        
        Alamofire.request(.GET, fetchURL)
            .responseJSON
            {
                (_, _, JSON, _) in
                self.updateUISuccess(JSON as NSDictionary)                
            }
    }
    
    func updateUISuccess(jsonResult: NSDictionary!)
    {
        let defaults = NSUserDefaults(suiteName: "group.brandonroeder.WeatherToday")

        var results: NSArray = jsonResult["results"] as NSArray
        var components = results[0] as NSDictionary
        let formattedAddress = components["formatted_address"]? as String?
        
        if let coordinates = components["geometry"]? as NSDictionary?
        {
            if let location = coordinates["location"]? as NSDictionary?
            {
                let latitude: AnyObject? = location["lat"]? as AnyObject?
                let longitude: AnyObject? = location["lng"]? as AnyObject?
                
                defaults?.setValue(latitude, forKey: "latitude")
                defaults?.setValue(longitude, forKey: "longitude")
                defaults?.synchronize()
            }
        }
    }
    
    func textField(textField: UITextField!, shouldChangeCharactersInRange range: NSRange, replacementString string: String!) -> Bool
    {
        let maxLength = countElements(textField.text!) + countElements(string!) - range.length
        return maxLength <= 5 //Bool
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool
    {
        if (textField == self.zipcodeField)
        {
            textField.resignFirstResponder()
            self.getLocation(self.zipcodeField.text)
            return false;
        }
        return true
    }


}