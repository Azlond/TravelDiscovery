//
//  Travel.swift
//  TravelDiscovery
//
//  Created by Jan Kaiser on 03.12.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import Foundation

class Travel {
    
    //MARK: Properties
    
    /*required*/
    var id: Int? //TODO
    var name: String
    var pins: Dictionary<String,Pin> = [:]
    var begin: String
    var active: Bool
    /*optionals*/
    var end: String?
    var steps: Int?
    var km: Double?

    //var videos:
    
    
    
    
    //MARK: Initialization
    
    init?(name: String, pin: Pin, begin: String) {
        // Initialization should fail if there is no name
        guard !name.isEmpty else {
            return nil
        }
        
        // Initialize stored properties.
        self.name = name
        self.pins[pin.id] = pin
        self.begin = begin
        self.active = true
    }
    

}
