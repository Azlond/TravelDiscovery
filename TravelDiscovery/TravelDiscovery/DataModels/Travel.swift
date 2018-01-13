//
//  Travel.swift
//  TravelDiscovery
//
//  Created by Jan Kaiser on 03.12.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import Foundation
import UIKit

class Travel {
    public static var dateStyle = DateFormatter.Style.long
    public static var timeStyle = DateFormatter.Style.none
    
    //MARK: Properties
    
    /*required*/
    var id: String
    var name: String
    var sortIndex: Int
    
    /*optionals*/
    var pins: Dictionary<String,Pin> = [:]
    var active: Bool?
    var begin: String?
    var end: String?
    var steps: Int?
    var km: Double?

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
    }
    
    
    //init Travel from FirebaseDictionary
    init?(dict: (Dictionary<String,Any>))  {
        self.id =  dict["id"] as! String
        self.name = dict["name"] as! String
        self.sortIndex = dict["sortIndex"] as! Int
        self.begin = dict["begin"] as? String
        self.end = dict["end"] as? String
        self.active = dict["active"] as? Bool
        
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
    }
    
    
    func prepareDictForFirebase() -> Dictionary<String, Any>{
        var dict = [String:Any]()
        
        dict = ["id":self.id,
                "name":self.name,
                "begin":self.begin ?? "",
                "end":self.end ?? "",
                "active": self.active ?? false,
                "sortIndex": self.sortIndex]
        
        return dict
    }
    
}
