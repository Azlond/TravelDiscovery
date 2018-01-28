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
    public static var publicPins = [Pin]()
    public static var travels: Dictionary<String, Travel> = [:]
    public static let imageCache = NSCache<NSString, AnyObject>()
    
    static func getActiveTravel() -> Travel? {
        for travelEntry in FirebaseData.travels{
            let travel = travelEntry.value
            if(travel.active){
                return travel
            }
        }
        return nil
    }
    
    static func getHighestSortIndex() -> Int {
        // in case there are no travels we should return -1 instead of 0 since 0 is a valid sortIndex
        // the function to add a new travel add 1 to this return value
        var highestIndex = -1
        for travelEntry in FirebaseData.travels{
            let travel = travelEntry.value
            if(travel.sortIndex > highestIndex){
                highestIndex = travel.sortIndex
            }
        }
        return highestIndex
    }
}
