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
    // var id: Int do we really need this?
    var name: String
    var pins: [Pin]
    var begin: String
    var active: Bool
    /*optionals*/
    var end: String?
    var steps: Int?
    var km: Double?

    //var videos:
    
    
    
    
    //MARK: Initialization
    
    init?(name: String, pins: [Pin], begin: String) {
        // Initialization should fail if there is no name
        guard !name.isEmpty else {
            return nil
        }
        
        // Initialize stored properties.
        self.name = name
        self.pins = pins
        self.begin = begin
        self.active = true
    }
    

}
