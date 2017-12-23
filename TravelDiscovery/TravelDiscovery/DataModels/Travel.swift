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
    var begin: String?
    var active: Bool?
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
    }
    
    
    //init Travel from FirebaseDictionary
    init?(dict: (Dictionary<String,Any>))  {
        self.id =  dict["id"] as! String
        self.name = dict["name"] as! String
    }
    
    func prepareDictForFirebase() -> Dictionary<String, Any>{
        var dict = [String:Any]()
        
        dict =     ["id":self.id,
                    "name":self.name]
        
        return dict
    }
}
