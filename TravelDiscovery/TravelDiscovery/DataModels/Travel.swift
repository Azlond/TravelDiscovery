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
    
    //MARK: Properties
    
    /*required*/
    var id: String
    var name: String
    /*optionals*/
    var pins: Dictionary<String,Pin> = [:]
    var active: Bool?
    var begin: String?
    var end: String?
    var steps: Int?
    var km: Double?

    //var videos:
    
    
    
    
    //MARK: Initialization
    
    init?(id: String, name: String) {
        // Initialization should fail if there is no name
        guard !name.isEmpty else {
            return nil
        }
        
        // Initialize stored properties.
        self.id = id
        self.name = name
        self.begin = ""
        self.end = ""
        self.active = true
    }
    
    
    //init Travel from FirebaseDictionary
    init?(dict: (Dictionary<String,Any>))  {
        self.id =  dict["id"] as! String
        self.name = dict["name"] as! String
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
    }
    
    
    func prepareDictForFirebase() -> Dictionary<String, Any>{
        var dict = [String:Any]()
        
        dict = ["id":self.id,
                "name":self.name,
                "begin":self.begin ?? "",
                "end":self.end ?? "",
                "active": self.active ?? false]
        
        return dict
    }
    
    
}
