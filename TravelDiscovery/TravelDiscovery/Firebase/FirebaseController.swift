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
            initDatabase()
            var vC : Dictionary<String, Bool> = [:]
            let regex = try! NSRegularExpression(pattern: "\\.")
            for country in FirebaseData.visitedCountries {
                let key = regex.stringByReplacingMatches(in: country.key, options: [], range: NSRange(0..<country.key.utf16.count), withTemplate: "DOT")
                vC[key] = true
            }
            FirebaseData.ref.child("users").child(user.uid).child("visitedCountries").setValue(vC)
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
                
                
                /*settings*/
                let userSettings = UserDefaults.standard
                let loadedSettings = value?["settings"] as? Dictionary<String, String> ?? FirebaseData.defaultSettings
                let feedRangeValue = loadedSettings["feedRange"] ?? FirebaseData.defaultSettings["feedRange"]
                userSettings.set(feedRangeValue, forKey: "feedRange")
                let usernameValue = loadedSettings["username"] ?? FirebaseData.defaultSettings["username"]
                userSettings.set(usernameValue, forKey: "username")
                let postVisibilityValue = loadedSettings["visibility"] ?? FirebaseData.defaultSettings["visibility"]
                userSettings.set(postVisibilityValue, forKey: "visibility")
                let scratchPercentValue = loadedSettings["scratchPercent"] ?? FirebaseData.defaultSettings["scratchPercent"]
                userSettings.set(scratchPercentValue, forKey: "scratchPercent")
                Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.sendSettingsNotification), userInfo: nil, repeats: false) //need to use a timer to avoid too many changes
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    @objc private static func sendSettingsNotification() {
        NotificationCenter.default.post(name: Notification.Name("updateSettings"), object: nil)
    }
    
    public static func saveSettingsToFirebase(key: String) {
        if let user = Auth.auth().currentUser {
            initDatabase()
            let userSettings = UserDefaults.standard
            FirebaseData.ref.child("users").child(user.uid).child("settings").child(key).setValue(userSettings.string(forKey: key))
        }
    }
    
    public static func getMailAdress() -> String {
        if let user = Auth.auth().currentUser {
            return user.email ?? "traveldiscovery@example.com"
        }
        return "traveldiscovery@example.com"
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
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
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
