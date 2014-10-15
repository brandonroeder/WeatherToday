//
//  ViewController.swift
//  WeatherToday
//
//  Created by Brandon Roeder on 9/29/14.
//  Copyright (c) 2014 Brandon Roeder. All rights reserved.
//

import Foundation
import UIKit

class WidgetViewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named:"weather.jpg")!)
    }
}