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
import SwiftLocation
import CoreLocation
import UserNotifications

class FirebaseController {
    
    public static func saveCountriesToFirebase() {
        if let user = Auth.auth().currentUser {
            if (FirebaseData.ref == nil) {
                // initialize database
                FirebaseData.ref = Database.database().reference()
            }
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
            if (FirebaseData.ref == nil) {
                // initialize database
                FirebaseData.ref = Database.database().reference()
            }
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
    
    public static func handleBackgroundLocationData(location: CLLocation) {
        if let user = Auth.auth().currentUser {
            if (FirebaseData.ref == nil) {
                // initialize database
                FirebaseData.ref = Database.database().reference()
            }
            
            FirebaseData.locationData[FirebaseData.locationData.count] = location.coordinate
            
            for loc in FirebaseData.locationData {
                let locDict : Dictionary<String, Double> = ["latitude":loc.value.latitude, "longitude":loc.value.longitude]
                FirebaseData.ref.child("users").child(user.uid).child("activeTravelLocations").child(String(loc.key)).setValue(["coordinates": locDict])
            }            
            
            /* Send push message with location name*/
            Locator.location(fromCoordinates: location.coordinate, onSuccess: { places in
                print(places)
                let content = UNMutableNotificationContent()
                content.title = "New Location Update"
                content.body = "You're somewhere new: \(places)"
                content.sound = UNNotificationSound.default()
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
                let identifier = "UYLLocalNotification"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
                    if let error = error {
                        print("\(error)")
                    }
                })
            }, onFail: { err in
                print("\(err)")
            })
        } else {
            print("oops")
        }
    }
}
