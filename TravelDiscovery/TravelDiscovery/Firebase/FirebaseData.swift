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
//TODO: Decide whether it's called new Travel or new Trip
//TODO: value of "share in public feed" gets reset when selecting an image/video
//TODO: private pins are appearing in public feed - might be related to TODO above
//TODO: maybe show pin-videos in fullscreen?
//TODO: opening a travel deletes and reuplods pins to Firebase for some reason
//TODO: Warnings are hidden/invisible behind NavigationBar in MapView
//TODO: Steps in the steplabel in travels are cut off at right screen
//TODO: HealthKit-Operations are async - correct amount of steps only gets shown on second visit to travel

class FirebaseData {
    public static var visitedCountries : Dictionary<String, Bool> = [:]
    public static var user : User?
    public static var ref: DatabaseReference!
    public static let defaultSettings: Dictionary<String, String> = ["feedRange":"1","username":"","visibility":"0","scratchPercent":"90"]
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
