//
//  Travel.swift
//  TravelDiscovery
//
//  Created by Jan Kaiser on 03.12.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import Foundation
import UIKit
import HealthKit
import SwiftLocation
import CoreLocation

class Travel {
    public static var dateStyle = DateFormatter.Style.medium
    public static var timeStyle = DateFormatter.Style.none
    
    //MARK: Properties
    
    /*required*/
    var id: String
    var name: String
    var sortIndex: Int
    
    /*optionals*/
    var pins: Dictionary<String,Pin> = [:]
    var active: Bool
    var begin: String?
    var end: String?
    var steps: Double
    var km: Double
    var routeData : Dictionary<String, CLLocationCoordinate2D> = [:]
    //var videos:
    
    
    
    
    //MARK: Initialization
    
    init?(id: String, name: String, sortIndex: Int) {
        // Initialization should fail if there is no name
        guard !name.isEmpty else {
            return nil
        }
        
        // Initialize stored properties.
        self.id = id
        self.name = name
        self.sortIndex = sortIndex
        self.begin = ""
        self.end = ""
        self.active = true
        self.steps = 0.0
        self.km = 0.0
        
        let userSettings = UserDefaults.standard
        userSettings.set(id, forKey: "activeTravelID")
        Locator.subscribeSignificantLocations(onUpdate: { location in
            FirebaseController.handleBackgroundLocationData(location: location)
        }) { (err, lastLocation) -> (Void) in
            print("Failed with err: \(err)")
        }
    }
    
    
    //init Travel from FirebaseDictionary
    init?(dict: (Dictionary<String,Any>))  {
        self.id =  dict["id"] as! String
        self.name = dict["name"] as! String
        self.sortIndex = dict["sortIndex"] as! Int
        self.begin = dict["begin"] as? String
        self.end = dict["end"] as? String
        self.active = dict["active"] as! Bool
        self.steps = dict["steps"] as! Double
        self.km = dict["km"] as! Double
        
        //load pins
        let tmpPins = dict["pins"] as? Dictionary<String, Any> ?? [:]
        for pinEntry in tmpPins{
            let value = pinEntry.value as! Dictionary<String, Any>
            let pin = Pin.init(dict: value)
            self.pins[pinEntry.key] = pin
        }
        
        let tmpLocs = dict["routeData"] as? NSArray ?? []
        for locEntry in tmpLocs {
            let coordinates : Dictionary<String, Dictionary<String, Double>> = locEntry as! Dictionary<String, Dictionary<String, Double>>
            let lat : Double = coordinates["coordinates"]!["latitude"]!
            let long: Double = coordinates["coordinates"]!["longitude"]!
            let coordinate : CLLocationCoordinate2D = CLLocationCoordinate2D.init(latitude: lat, longitude: long)
            routeData[String(routeData.count)] = coordinate
        }
        
        if (self.active) {
            let userSettings = UserDefaults.standard
            userSettings.set(id, forKey: "activeTravelID")
            Locator.subscribeSignificantLocations(onUpdate: { location in
                FirebaseController.handleBackgroundLocationData(location: location)
            }) { (err, lastLocation) -> (Void) in
                print("Failed with err: \(err)")
            }
        }
    }
    
    func endTrip(){
        self.active = false
        if (self.end == "") {
            self.end = DateFormatter.localizedString(from: Date(), dateStyle: Travel.dateStyle, timeStyle: Travel.timeStyle)
        }
        self.getSteps()
        self.getKm()
        
        Locator.completeAllLocationRequests()
        let userSettings = UserDefaults.standard
        userSettings.set("", forKey: "activeTravelID")
    }
    
    
    func prepareDictForFirebase() -> Dictionary<String, Any>{
        var dict = [String:Any]()
        
        var routeDict: Dictionary<String, Dictionary<String, Dictionary<String, Double>>> = [:]
        
        for loc in routeData {
            routeDict[loc.key] = ["coordinates": ["latitude":loc.value.latitude, "longitude":loc.value.longitude]]
        }
        
        dict = ["id":self.id,
                "name":self.name,
                "begin":self.begin ?? "",
                "end":self.end ?? "",
                "active": self.active,
                "sortIndex": self.sortIndex,
                "steps": self.steps,
                "km": self.km,
                "routeData": routeDict]
        
        return dict
    }
    
    func getSteps() -> Double {
        if (self.active) {
            self.stepCounter() // update steps
        }
        return self.steps
    }
    
    func getKm() -> Double {
        if (self.active) {
            // Eventually we need to calculate the km of the active travel
        }
        return self.km
    }
    
    // Copy of stepCounter from SettingsViewController
    func stepCounter() {
        
        guard let healthStore: HKHealthStore? = {
            if HKHealthStore.isHealthDataAvailable() {
                return HKHealthStore()
            } else {
                return nil
            }
            }() else {
                return
        }
        
        let stepsCount = HKQuantityType.quantityType(forIdentifier: .stepCount)
        
        let dataTypesToRead : Set<HKObjectType> = [stepsCount!]
        
        healthStore?.requestAuthorization(toShare: nil, read: dataTypesToRead) { (success, error) in
            if let error = error {
                print("Failed authorization = \(error.localizedDescription)")
            }
            if (success) {
                let userCalendar = Calendar.current // user calendar
                
                var dateComponentsStart = DateComponents()
                dateComponentsStart.year = 2017
                dateComponentsStart.month = 1
                dateComponentsStart.day = 1
                dateComponentsStart.timeZone = TimeZone(abbreviation: "CET") // Central European Time
                dateComponentsStart.hour = 0
                
                let startDate = userCalendar.date(from: dateComponentsStart)
                
                let dateComponentEnd = DateComponents()
                let endDate = Date()
                
                let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
                
                let stepsSampleQuery = HKStatisticsQuery(quantityType: stepsCount!, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
                    var resultCount = 0.0
                    
                    guard let result = result else {
                        print("Failed to fetch steps = \(error?.localizedDescription ?? "N/A")")
                        return
                    }
                    
                    if let sum = result.sumQuantity() {
                        resultCount = sum.doubleValue(for: HKUnit.count())
                    }
                    
                    // Save result in Travel object
                    self.steps = resultCount
                }
                // Don't forget to execute the Query!
                healthStore?.execute(stepsSampleQuery)
            }
        }
    }
}
