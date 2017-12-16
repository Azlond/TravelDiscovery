//
//  FirebaseController.swift
//  TravelDiscovery
//
//  Created by Jan Kaiser on 08.12.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

class FirebaseController {
    
    public static func saveCountriesToFirebase() {
        if let user = Auth.auth().currentUser {
            initDatabase()
            var vC : Dictionary<String, Bool> = [:]
            let regex = try! NSRegularExpression(pattern: "\\.")
            for country in FirebaseData.visitedCountries {
                let key = regex.stringByReplacingMatches(in: country.key, options: [], range: NSRange(0..<country.key.utf16.count), withTemplate: "DOT")
                vC[key] = true
            }
            FirebaseData.ref.child("users").child(user.uid).setValue(["visitedCountries": vC])
        }
    }
    
    public static func retrieveCountriesFromFirebase() {
        if let user = Auth.auth().currentUser {
            initDatabase()
            FirebaseData.ref.child("users").child(user.uid).observe(.value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                var vC : Dictionary<String, Bool> = [:]
                let fbD = value?["visitedCountries"] as? Dictionary<String, Bool> ?? [:]
                let regex = try! NSRegularExpression(pattern: "DOT")
                for country in fbD {
                    let key = regex.stringByReplacingMatches(in: country.key, options: [], range: NSRange(0..<country.key.utf16.count), withTemplate: ".")
                    vC[key] = true
                }
                FirebaseData.visitedCountries = vC
                NotificationCenter.default.post(name: Notification.Name("updateMap"), object: nil)
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    private static func initDatabase() {
        if (FirebaseData.ref == nil) {
            // initialize database
            FirebaseData.ref = Database.database().reference()
        }
    }
    
    public static func removeObservers() {
        initDatabase()
        FirebaseData.ref.removeAllObservers()
    }
    
    public static func removeUserData() {
        if let user = Auth.auth().currentUser {
            FirebaseData.ref.child("users").child(user.uid).removeValue()
        }
    }
}
