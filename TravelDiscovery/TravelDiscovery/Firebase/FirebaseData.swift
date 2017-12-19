//
//  Firebase.swift
//  TravelDiscovery
//
//  Created by Jan Kaiser on 08.12.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import CoreLocation

class FirebaseData {
    public static var visitedCountries : Dictionary<String, Bool> = [:]
    public static var user : User?
    public static var ref: DatabaseReference!
    public static let defaultSettings: Dictionary<String, String> = ["feedRange":"1","username":"","visibility":"0","scratchPercent":"90"]
    public static var locationData : Dictionary<Int, CLLocationCoordinate2D> = [:]  
    public static var pins: Dictionary<String, Pin> = [:]
}
