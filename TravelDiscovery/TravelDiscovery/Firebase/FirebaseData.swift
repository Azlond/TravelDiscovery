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

//TODO: Capitalization of first letter in "new Travel Popup"
//TODO: Change "new trip/Pin" button when travel is created 
//TODO: Decide whether itS' called new Travel or new Trip
//TODO: value of "share in public feed" gets reset when selecting an image/video

class FirebaseData {
    public static var visitedCountries : Dictionary<String, Bool> = [:]
    public static var user : User?
    public static var ref: DatabaseReference!
    public static let defaultSettings: Dictionary<String, String> = ["feedRange":"1","username":"","visibility":"0","scratchPercent":"90"]
    public static var locationData : Dictionary<Int, CLLocationCoordinate2D> = [:]  /*TODO: Might no longer be needed once locationData is saved to travel*/
    public static var publicPins = [Pin]()
    public static var travels: Dictionary<String, Travel> = [:]
    public static let imageCache = NSCache<NSString, AnyObject>()
    
    /*TODO: does this belong to FirebaseData or FirebaseController? */
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
        var highestIndex = 0
        for travelEntry in FirebaseData.travels{
            let travel = travelEntry.value
            if(travel.sortIndex > highestIndex){
                highestIndex = travel.sortIndex
            }
        }
        return highestIndex
    }
}
