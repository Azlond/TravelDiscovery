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
    //locks for uploads
    static var uploadingImages: Bool = false
    static var uploadingVideo: Bool = false
    static var uploadingVideoThumbnail: Bool = false
    
    
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
                FirebaseData.locationData.removeAll()
                FirebaseData.locationData = lD
            })
            
           retrievePublicPinsFromFirebase()
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
    
    
    @objc public static func handleBackgroundLocationData(location: CLLocation) {
        if let user = Auth.auth().currentUser {
            if (FirebaseData.ref == nil) {
                // initialize database
                FirebaseData.ref = Database.database().reference()
            }
            
            if (!FirebaseData.locationData.isEmpty) {
                //if current location is too close to last location, don't record it
                let lastLocation: CLLocation = CLLocation(latitude: (FirebaseData.locationData[FirebaseData.locationData.count-1]?.latitude)!, longitude: (FirebaseData.locationData[FirebaseData.locationData.count-1]?.longitude)!)
                if (location.distance(from: lastLocation) < 1000) {
                    return
                }
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
    
    public static func savePinsToFirebaseOfTravel(travel: Travel) {
        if let user = Auth.auth().currentUser {
            if (FirebaseData.ref == nil) {
                // initialize database
                FirebaseData.ref = Database.database().reference()
            }
            // loop over pins
            let pinsCopy = travel.pins
            for pinEntry in pinsCopy {
                let pin = pinEntry.value
                
                // check if images or videos have to be uploaded
                if  ((pin.imageURLs?.isEmpty ?? true) && !(pin.photos?.isEmpty ?? true)) || (pin.videoUploadURL != nil && pin.videoDownloadURL == nil) {
                    
                    // IMGAGE UPLOAD: if a pin doesn't have imageURL entries but has photos -> upload images
                    if ((pin.imageURLs?.isEmpty ?? true) && !(pin.photos?.isEmpty ?? true)) {
                        self.uploadingImages = true
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
                                        self.uploadingImages = false
                                        return
                                        //TODO fehlermanagement uploading error
                                    }
                                    
                                    //UPLOAD SUCCESS
                                    //retrieve URL of uploaded image
                                    if let imageURL = metadata?.downloadURL()?.absoluteString {
                                        pin.imageURLs?.append(imageURL)
                                        
                                        //save pin after last image was uploaded
                                        if index == (pin.photos!.count-1) {
                                            self.uploadingImages = false
                                            self.savePinToFirebase(pin: pin, user: user, travel: travel)
                                        }
                                    }
                                })
                            }
                        }
                    }
                    
                    //upload video if pin only has an uploadURL saved but no downloadURL
                    if pin.videoUploadURL != nil && pin.videoDownloadURL == nil {
                        self.uploadingVideo = true
                        
                        let videoName = UUID().uuidString + ".mov"
                        let storageRef = Storage.storage().reference().child("videos").child(videoName)
                        
                        //upload video
                        storageRef.putFile(from: pin.videoUploadURL!, metadata:nil, completion: {
                            (metadata, error) in
                            if error != nil {
                                print(error!)
                                self.uploadingVideo = false
                                return
                                //TODO fehlermanagement uploading error
                            }
                            //UPLOAD SUCCESS
                            //retrieve URL of uploaded video
                            if let videoURL = metadata?.downloadURL()?.absoluteString {
                                pin.videoDownloadURL = videoURL
                                self.uploadingVideo = false
                                self.savePinToFirebase(pin: pin, user: user, travel: travel)
                            }
                        })
                        //upload video thumbnail
                        let imageName = UUID().uuidString + ".jpeg"
                        let storageRefImages = Storage.storage().reference().child("images").child(imageName)
                        
                        if let uploadData = UIImageJPEGRepresentation(pin.videoThumbnail!, 1) {
                            self.uploadingVideoThumbnail = true
                            storageRefImages.putData(uploadData, metadata:nil, completion: {
                                (metadata, error) in
                                if error != nil {
                                    print("Error Uploading: ",error!)
                                    self.uploadingVideoThumbnail = false
                                    return
                                }
                                //UPLOAD SUCCESS
                                //retrieve URL of uploaded video thumbnail
                                if let imageURL = metadata?.downloadURL()?.absoluteString {
                                    pin.videoThumbnailURL = imageURL
                                    self.uploadingVideoThumbnail = false
                                    self.savePinToFirebase(pin: pin, user: user, travel: travel)
                                }
                            })
                        }
                        
                    }
                }
                    // no images or video to upload: save pin to firebase immediately
                else {
                    self.savePinToFirebase(pin: pin, user: user, travel: travel)
                }
            }
        }
    }
    
    public static func savePinToFirebase(pin: Pin, user: User, travel: Travel) {
        //check if all uploading processes are complete
        if !self.uploadingImages && !self.uploadingVideo && !self.uploadingVideoThumbnail{
            //save pin
            if FirebaseData.ref == nil {
                FirebaseData.ref = Database.database().reference()
            }
            let fbDict = pin.prepareDictForFirebase()
            FirebaseData.ref.child("users").child(user.uid).child("travels").child(travel.id).child("pins").child(pin.id).setValue(fbDict)
            NotificationCenter.default.post(name: Notification.Name("updatePins"), object: nil)
            
            //save public pin
            if (pin.visibilityPublic) {
                print("uploading to public pins")
                FirebaseData.ref.child("publicPins").child(pin.id).setValue(fbDict)
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
                    //create json object from data, preload images
                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        var pinsArray = [Pin]()
                        for element in json {
                            let value = element.value as! Dictionary<String, Any>
                            let pin = Pin.init(dict: value)
                            pinsArray.append(pin!)
                            if ((pin!.imageURLs?.count ?? 0) > 0) {
                                pin!.saveImageToDocuments(withUrl: pin!.imageURLs![0])
                            }
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
    
    public static func saveTravelsToFirebase() {
        if let user = Auth.auth().currentUser {
            if (FirebaseData.ref == nil) {
                // initialize database
                FirebaseData.ref = Database.database().reference()
            }
            // loop over travels
            let travelsCopy = FirebaseData.travels
            for travelEntry in travelsCopy {
                let travel = travelEntry.value
                let fbDict = travel.prepareDictForFirebase()
                FirebaseData.ref.child("users").child(user.uid).child("travels").child(travel.id).setValue(fbDict)
                
                //save pins
                savePinsToFirebaseOfTravel(travel: travel)
                
                NotificationCenter.default.post(name: Notification.Name("updateTravels"), object: nil)
            }
        }
    }
    
    public static func retrieveTravelsFromFirebase() {
        if let user = Auth.auth().currentUser {
            if (FirebaseData.ref == nil) {
                // initialize database
                FirebaseData.ref = Database.database().reference()
            }
            
            FirebaseData.ref.child("users").child(user.uid).child("travels").observeSingleEvent(of: .value, with: { (snapshot) in
                let fbD = snapshot.value as? Dictionary<String, Any> ?? [:]
                
                //create Travel Dictionary from firebase data
                var travelsDict: Dictionary<String, Travel> = [:]
                for travelEntry in fbD {
                    let value = travelEntry.value as! Dictionary<String, Any>
                    let travel = Travel.init(dict: value)
                    travelsDict[travelEntry.key] = travel
                }
                FirebaseData.travels = travelsDict
                NotificationCenter.default.post(name: Notification.Name("updateTravels"), object: nil)
                NotificationCenter.default.post(name: Notification.Name("updatePins"), object: nil)
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    public static func removeTravelFromFirebase(travelid: String) {
        if let user = Auth.auth().currentUser {
            if (FirebaseData.ref == nil) {
                // initialize database
                FirebaseData.ref = Database.database().reference()
            }
            FirebaseData.ref.child("users").child(user.uid).child("travels").child(travelid).removeValue()
        }
    }
    
    public static func populateCache() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            for fileName in fileURLs {
                guard let data = try? Data(contentsOf: fileName) else {
                   continue
                }
                FirebaseData.imageCache.setObject(UIImage(data: data)!, forKey: fileName.lastPathComponent as NSString)
                
            }
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
        
    }
}
