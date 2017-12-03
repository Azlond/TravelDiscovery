//
//  Pin.swift
//  TravelDiscovery
//
//  Created by Jan Kaiser on 03.12.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import Foundation
import UIKit

class Pin {
    
    //MARK: Properties
    
    /*required*/
    // var id: Int do we really need this?
    var name: String
    var longitude: Double
    var latitude: Double
    var visibilityPublic: Bool
    var date: String
    /*optionals*/
    var text: String?
    var photos: [UIImage]?
    
    /*TODO: Find out how videos are stored*/
    //var videos:
    
    
    
    
    //MARK: Initialization
    
    init?(name: String, longitude: Double, latitude: Double, visibilityPublic: Bool, date: String, photos: [UIImage]?, text: String?) {
        // Initialization should fail if there is no name
        guard !name.isEmpty else {
            return nil
        }
        
        // Initialize stored properties.
        self.name = name
        self.longitude = longitude
        self.latitude = latitude
        self.visibilityPublic = visibilityPublic
        self.date = date
        self.photos = photos
        self.text = text
        
    }
    

    
}
