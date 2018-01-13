//
//  TravelsInfomation.swift
//  TravelDiscovery
//
//  Created by Hyerim Park on 10/12/2017.
//  Copyright © 2017 Jan. All rights reserved.
//

import Foundation

class TravelsInformation {
    var country: String
    var departureDate: Int
    var returnDate: Int
    
    init(country: String, dDate: Int, rDate: Int){
        self.country = country
        self.departureDate = dDate
        self.returnDate = rDate
        
    }
}
