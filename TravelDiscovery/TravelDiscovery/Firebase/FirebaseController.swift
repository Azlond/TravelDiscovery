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
import FirebaseStorage

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
    
    /**
     * Retrieves user values from Firebase and activates listener for changes
     */
    public static func retrieveFromFirebase() {
        if let user = Auth.auth().currentUser {
            initDatabase()
            
            /*Countries*/
            FirebaseData.ref.child("users").child(user.uid).child("visitedCountries").observe(.value, with: { (snapshot) in
                let value = snapshot.value as? Dictionary<String, Bool> ?? [:]
                var vC : Dictionary<String, Bool> = [:]
                let regex = try! NSRegularExpression(pattern: "DOT")
                for country in value {
                    let key = regex.stringByReplacingMatches(in: country.key, options: [], range: NSRange(0..<country.key.utf16.count), withTemplate: ".")
                    vC[key] = true
                }
                FirebaseData.visitedCountries = vC
                NotificationCenter.default.post(name: Notification.Name("updateMap"), object: nil)
            })
            
            /*settings*/
            FirebaseData.ref.child("users").child(user.uid).child("settings").observe(.value, with: { (snapshot) in
                let userSettings = UserDefaults.standard
                let loadedSettings = snapshot.value as? Dictionary<String, String> ?? FirebaseData.defaultSettings
                let feedRangeValue = loadedSettings["feedRange"] ?? FirebaseData.defaultSettings["feedRange"]
                userSettings.set(feedRangeValue, forKey: "feedRange")
                let usernameValue = loadedSettings["username"] ?? FirebaseData.defaultSettings["username"]
                userSettings.set(usernameValue, forKey: "username")
                let postVisibilityValue = loadedSettings["visibility"] ?? FirebaseData.defaultSettings["visibility"]
                userSettings.set(postVisibilityValue, forKey: "visibility")
                let scratchPercentValue = loadedSettings["scratchPercent"] ?? FirebaseData.defaultSettings["scratchPercent"]
                userSettings.set(scratchPercentValue, forKey: "scratchPercent")
                Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.sendSettingsNotification), userInfo: nil, repeats: false) //need to use a timer to avoid too many changes
            })
            
            /*locationData*/
            FirebaseData.ref.child("users").child(user.uid).child("activeTravelLocations").observe(.value, with: { (snapshot) in
                var lD : Dictionary<Int, CLLocationCoordinate2D> = [:]
                let value = snapshot.value as? NSArray ?? []
                for element in value {
                    let coordinates : Dictionary<String, Dictionary<String, Double>> = element as! Dictionary<String, Dictionary<String, Double>>
                    let lat : Double = coordinates["coordinates"]!["latitude"]!
                    let long: Double = coordinates["coordinates"]!["longitude"]!
                    let coordinate : CLLocationCoordinate2D = CLLocationCoordinate2D.init(latitude: lat, longitude: long)
                    lD[lD.count] = coordinate
                }
                FirebaseData.locationData = lD
            })
        }
    }
    
    @objc private static func sendSettingsNotification() {
        NotificationCenter.default.post(name: Notification.Name("updateSettings"), object: nil)
    }
    
    @objc public static func saveSettingsToFirebase(timer:Timer) {
        if let user = Auth.auth().currentUser {
            initDatabase()
            let userSettings = UserDefaults.standard
            let userInfo = timer.userInfo as! Dictionary<String, String>
            let key : String = userInfo["key"]!
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
            FirebaseData.ref.keepSynced(true)
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
            let userSettings = UserDefaults.standard
            if (userSettings.bool(forKey: "locationNotification")) {
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
            }
        } else {
            print("oops")
        }
    }
    
    
    public static func savePinsToFirebase() {
        if let user = Auth.auth().currentUser {
            if (FirebaseData.ref == nil) {
                // initialize database
                FirebaseData.ref = Database.database().reference()
            }
            // loop over pins
            let pinsCopy = FirebaseData.pins
            for pinEntry in pinsCopy {
                let pin = pinEntry.value
                
                // if a pin doesn't have imageURL entries but has photos -> upload images
                let noImageURLs = (pin.imageURLs?.isEmpty ?? true)
                let hasPhotos = !(pin.photos?.isEmpty ?? true)
                if  noImageURLs && hasPhotos {
                    
                    //loop over images
                    for (index,image) in pin.photos!.enumerated() {
                        
                        // name image after random name
                        let imageName = UUID().uuidString + ".jpeg"
                        let storageRef = Storage.storage().reference().child("images").child(imageName)
                        
                        if let uploadData = UIImageJPEGRepresentation(image, 1) {
                            // upload image
                            //TODO: start spinning animation
                            storageRef.putData(uploadData, metadata:nil, completion: {
                                (metadata, error) in
                                if error != nil {
                                    print(error!)
                                    return
                                    //TODO fehlermanagement
                                }
                                
                                //UPLOAD SUCCESS
                                //retrieve URL of uploaded image
                                if let imageURL = metadata?.downloadURL()?.absoluteString {
                                    pin.imageURLs?.append(imageURL)
                                    
                                    //save pin after last image was uploaded
                                    if index == (pin.photos!.count-1) {
                                        let fbDict = pin.prepareDictForFirebase()
                                        FirebaseData.ref.child("users").child(user.uid).child("pins").child(pin.id).setValue(fbDict)
                                        NotificationCenter.default.post(name: Notification.Name("updatePins"), object: nil)
                                        if (pin.visibilityPublic) {
                                            print("uploading")
                                            FirebaseData.ref.child("publicPins").child(pin.id).setValue(fbDict)
                                        }
                                    }
                                }
                            })
                        }
                    }
                }
                    // no images to upload: save pin to firebase immediately
                else {
                    let fbDict = pin.prepareDictForFirebase()
                    FirebaseData.ref.child("users").child(user.uid).child("pins").child(pin.id).setValue(fbDict)
                    NotificationCenter.default.post(name: Notification.Name("updatePins"), object: nil)
                    if (pin.visibilityPublic) {
                        print("uploading")
                        FirebaseData.ref.child("publicPins").child(pin.id).setValue(fbDict)
                    }
                }
            }
        }
    }
    
    public static func retrievePinsFromFirebase() {
        if let user = Auth.auth().currentUser {
            if (FirebaseData.ref == nil) {
                // initialize database
                FirebaseData.ref = Database.database().reference()
            }

            FirebaseData.ref.child("users").child(user.uid).child("pins").observeSingleEvent(of: .value, with: { (snapshot) in
                let fbD = snapshot.value as? Dictionary<String, Any> ?? [:]
                
                //create Pin Dictionary from firebase data
                var pinsDict: Dictionary<String, Pin> = [:]
                for pinEntry in fbD {
                    let value = pinEntry.value as! Dictionary<String, Any>
                    let pin = Pin.init(dict: value)
                    pinsDict[pinEntry.key] = pin
                }
                FirebaseData.pins = pinsDict
                
                NotificationCenter.default.post(name: Notification.Name("updatePins"), object: nil)
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    public static func retrievePublicPinsFromFirebase(){
        //TODO: change/add feed UI based on error message, e.g. no network, no location data
        Locator.currentPosition(accuracy: .neighborhood, timeout: .delayed(7.0), onSuccess: { location in
            let url = URL(string: "https://us-central1-traveldiscovery-63134.cloudfunctions.net/getPublicPins")!
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = "POST"
            let postParams = ["range":String(UserDefaults.standard.float(forKey: "feedRange")), "lat":String(location.coordinate.latitude), "long":String(location.coordinate.longitude)]
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: postParams, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
            } catch let error {
                print(error.localizedDescription)
            }
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {                                                 // check for fundamental networking error
                    print("error=\(String(describing: error))")
                    FirebaseData.publicPins.removeAll()
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name("updateFeed"), object: nil)
                    }
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                    print("statusCode should be 200, but is \(httpStatus.statusCode)")
                    print("response = \(String(describing: response))")
                    //TODO: If statuscode == 400, no location or range was sent to the server. Tell user about it.
                }
                
                do {
                    //create json object from data
                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        var pinsArray = [Pin]()
                        for element in json {
                            let value = element.value as! Dictionary<String, Any>
                            let pin = Pin.init(dict: value)
                            pinsArray.append(pin!)
                        }
                        FirebaseData.publicPins = pinsArray
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name("updateFeed"), object: nil)
                        }
                    }
                } catch let error {
                    FirebaseData.publicPins.removeAll()
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name("updateFeed"), object: nil)
                    }
                    print(error.localizedDescription)
                }
            }
            task.resume()
        }, onFail: { (err, loc) -> (Void) in
            FirebaseData.publicPins.removeAll()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("updateFeed"), object: nil)
            }
            print(err)
        })
    }
}
