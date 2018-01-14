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
        
    }
    
    func endTrip(){
        self.active = false
        if (self.end == "") {
            self.end = DateFormatter.localizedString(from: Date(), dateStyle: Travel.dateStyle, timeStyle: Travel.timeStyle)
        }
        self.getSteps()
        self.getKm()
    }
    
    
    func prepareDictForFirebase() -> Dictionary<String, Any>{
        var dict = [String:Any]()
        dict = ["id":self.id,
                "name":self.name,
                "begin":self.begin ?? "",
                "end":self.end ?? "",
                "active": self.active,
                "sortIndex": self.sortIndex,
                "steps": self.steps,
                "km": self.km]
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
