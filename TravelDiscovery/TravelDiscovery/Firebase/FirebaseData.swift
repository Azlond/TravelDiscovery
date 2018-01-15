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

//TODO: Build logic for DatePickers in Travels or replace them with textLabels -> Hyerim
//TODO: New Trip: no empty input should be possible -> Hyerim
//TODO: Trips table view: deactivate sorting -> Hyerim
//TODO: Travels: update sort index on delete -> Jan
//TODO: Route Visualisation: following with camera, design -> Laura
//TODO: On end trip, "on traveling" doesn't disappear until the view is changed
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
