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
import GSMessages

class FirebaseController {
    //locks for uploads
    static var uploadingImages: Bool = false
    static var uploadingVideo: Bool = false
    static var uploadingVideoThumbnail: Bool = false
    
    /**
     * saving/removing the scratched country to/from the Firebase database
     * replacing '.' with the string DOT, as Firebase keys cannot have '.'
     */
    public static func countryToFirebase(countryName: String, add: Bool) {
        if let user = Auth.auth().currentUser {
            initDatabase()
            let regex = try! NSRegularExpression(pattern: "\\.")
            let country = regex.stringByReplacingMatches(in: countryName, options: [], range: NSRange(0..<countryName.utf16.count), withTemplate: "DOT")
            if (add) {
                FirebaseData.ref.child("users").child(user.uid).child("visitedCountries").child(country).setValue(true)
            } else {
                FirebaseData.ref.child("users").child(user.uid).child("visitedCountries").child(country).removeValue()
            }
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
           retrievePublicPinsFromFirebase()
        }
    }
    
    /**
     * save user settings to Firebase database
     */
    @objc public static func saveSettingsToFirebase(timer:Timer) {
        if let user = Auth.auth().currentUser {
            initDatabase()
            let userSettings = UserDefaults.standard
            let userInfo = timer.userInfo as! Dictionary<String, String>
            let key : String = userInfo["key"]!
            FirebaseData.ref.child("users").child(user.uid).child("settings").child(key).setValue(userSettings.string(forKey: key))
        }
    }
    
    /**
     * remove all userdata, for when a user deletes the account
     */
    public static func removeUserData() {
        if let user = Auth.auth().currentUser {
            FirebaseData.ref.child("users").child(user.uid).removeValue()
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
        }
    }
    
    /**
     * saves background location updates to firebase
     */
    @objc public static func handleBackgroundLocationData(location: CLLocation, isPin: Bool) {
        if let user = Auth.auth().currentUser {
            initDatabase()
            
            guard let activeTravel = FirebaseData.getActiveTravel() else {
                print("no active travel")
                return
            }
            
           if (!activeTravel.routeData.isEmpty && !isPin) {
                /*if current location is too close to last location, don't record it, as this can make the map-route look weird*/
               let lastLocation: CLLocation = CLLocation(latitude: (activeTravel.routeData[String(activeTravel.routeData.count-1)]?.latitude)!, longitude: (activeTravel.routeData[String(activeTravel.routeData.count-1)]?.longitude)!)
                if (location.distance(from: lastLocation) < 1000) {
                    return
                }
            }
         
            let userSettings = UserDefaults.standard
            let travelID = userSettings.string(forKey: "activeTravelID") ?? ""
            
            if (travelID.count < 1) {
                return
            }
            
            activeTravel.routeData[String(activeTravel.routeData.count)] = location.coordinate
            
            let locDict : Dictionary<String, Double> = ["latitude":location.coordinate.latitude, "longitude":location.coordinate.longitude]
            FirebaseData.ref.child("users").child(user.uid).child("travels").child(travelID).child("routeData").child(String(activeTravel.routeData.count - 1)).setValue(["coordinates": locDict])
        } else {
            print("oops")
        }
    }
    
    fileprivate static func uploadImages(_ pin: Pin, _ user: User, _ travel: Travel) {
        self.uploadingImages = true
        var count = 0
        
        //loop over images
        for image in pin.photos! {
            // name image after random name
            let imageName = UUID().uuidString + ".jpeg"
            let storageRef = Storage.storage().reference().child("images").child(imageName)
            
            if let uploadData = UIImageJPEGRepresentation(image, 1) {
                // upload image
                storageRef.putData(uploadData, metadata:nil, completion: {
                    (metadata, error) in
                    if error != nil {
                        print(error!)
                        self.uploadingImages = false
                        //notify of error
                        NotificationCenter.default.post(name: Notification.Name("uploadError"), object: nil, userInfo: ["type":"image"])
                        return
                    }
                    
                    //UPLOAD SUCCESS
                    //retrieve URL of uploaded image
                    if let imageURL = metadata?.downloadURL()?.absoluteString {
                        pin.imageURLs?.append(imageURL)
                        
                        count += 1
                        //save pin after last image was uploaded
                        if count == (pin.photos!.count) {
                            self.uploadingImages = false
                            self.savePinToFirebase(pin: pin, user: user, travel: travel)
                            NotificationCenter.default.post(name: Notification.Name("uploadSuccess"), object: nil, userInfo: ["type":"Image"])
                        }
                    }
                })
            }
        }
    }
    
    fileprivate static func uploadVideo(_ pin: Pin, _ user: User, _ travel: Travel) {
        self.uploadingVideo = true
        
        let videoName = UUID().uuidString + ".mov"
        let storageRef = Storage.storage().reference().child("videos").child(videoName)
        
        //upload video
        storageRef.putFile(from: pin.videoUploadURL!, metadata:nil, completion: {
            (metadata, error) in
            if error != nil {
                print(error!)
                self.uploadingVideo = false
                //alert uploading error
                NotificationCenter.default.post(name: Notification.Name("uploadError"), object: nil, userInfo: ["type":"video"])
                return
                
            }
            //UPLOAD SUCCESS
            //retrieve URL of uploaded video
            if let videoURL = metadata?.downloadURL()?.absoluteString {
                pin.videoDownloadURL = videoURL
                self.uploadingVideo = false
                self.savePinToFirebase(pin: pin, user: user, travel: travel)
                NotificationCenter.default.post(name: Notification.Name("uploadSuccess"), object: nil, userInfo: ["type":"Video"])
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
                    NotificationCenter.default.post(name: Notification.Name("uploadError"), object: nil, userInfo: ["type":"video thumbnail"])
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
    
    /**
     * upload pin images and videos if necessary
     */
    public static func savePinToFirebaseOfTravel(pin: Pin, travel: Travel) {
        if let user = Auth.auth().currentUser {
            initDatabase()
            
            // check if images or videos have to be uploaded
            if  ((pin.imageURLs?.isEmpty ?? true) && !(pin.photos?.isEmpty ?? true)) || (pin.videoUploadURL != nil && pin.videoDownloadURL == nil) {
                
                // IMAGE UPLOAD: if the pin doesn't have imageURL entries but has photos -> upload images
                if ((pin.imageURLs?.isEmpty ?? true) && !(pin.photos?.isEmpty ?? true)) {
                    uploadImages(pin, user, travel)
                }
                
                // VIDEO UPLOAD: if pin only has a video uploadURL saved but no downloadURL
                if pin.videoUploadURL != nil && pin.videoDownloadURL == nil {
                    uploadVideo(pin, user, travel)
                }
            }
                // no images or video to upload: save pin to firebase immediately
            else {
                self.savePinToFirebase(pin: pin, user: user, travel: travel)
            }
            
        }
    }
    /**
     * save pins to travel
     */
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
            NotificationCenter.default.post(name: Notification.Name("updateTravels"), object: nil)
            //save public pin
            if (pin.visibilityPublic) {
                FirebaseData.ref.child("publicPins").child(pin.id).setValue(fbDict)
            }
        }
    }
    
    /**
     * Get all public pins based on current area.
     * Filtering of public pins is done on the server side
     * if the pins first image is not yet cached, the image is downloaded
     */
    public static func retrievePublicPinsFromFirebase(){
        Locator.currentPosition(accuracy: .neighborhood, timeout: .delayed(7.0), onSuccess: { location in
            let url = URL(string: "https://us-central1-traveldiscovery-63134.cloudfunctions.net/getPublicPins")!
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = "POST"
            let postParams = ["range":String(UserDefaults.standard.float(forKey: "feedRange")), "lat":String(location.coordinate.latitude), "long":String(location.coordinate.longitude)]
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: postParams, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name("serverError"), object: nil)
                }
            }
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("error=\(String(describing: error))")
                    FirebaseData.publicPins.removeAll()
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name("updateFeed"), object: nil)
                    }
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                    print("statusCode should be 200, but is \(httpStatus.statusCode)")
                    print("response = \(String(describing: response))")
                    // If statuscode == 400, no location or range was sent to the server.
                    if httpStatus.statusCode == 400 {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name("serverError"), object: nil)
                        }
                    }
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        var pinsArray = [Pin]()
                        for element in json {
                            let value = element.value as! Dictionary<String, Any>
                            let pin = Pin.init(dict: value)
                            pinsArray.append(pin!)
                            /*Download firs timage of pin to display in feed if necessary*/
                            if ((pin!.imageURLs?.count ?? 0) > 0) {
                                saveImageToDocuments(withUrl: URL(string: pin!.imageURLs![0])!, pinImage: nil)
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
    
    public static func addTravelToFirebase(travel: Travel) {
        if let user = Auth.auth().currentUser {
            initDatabase()
            let fbDict = travel.prepareDictForFirebase()
            FirebaseData.ref.child("users").child(user.uid).child("travels").child(travel.id).setValue(fbDict)
        }
    }
    
    public static func updateTravelInFirebase(travel: Travel) {
        if let user = Auth.auth().currentUser {
            initDatabase()
            let fbDict = travel.prepareDictForFirebase()
            
            let travelRef = FirebaseData.ref.child("users").child(user.uid).child("travels").child(travel.id)
            travelRef.updateChildValues(fbDict)

        }
    }
    
    /**
     * retrieving travels from firebase
     */
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
    /**
     * deleting travel
     */
    public static func removeTravelFromFirebase(travelid: String) {
        if let user = Auth.auth().currentUser {
            if (FirebaseData.ref == nil) {
                // initialize database
                FirebaseData.ref = Database.database().reference()
            }
            FirebaseData.ref.child("users").child(user.uid).child("travels").child(travelid).removeValue()
        }
    }
    
    public static func updateTravelSteps(travel: Travel) {
        if let user = Auth.auth().currentUser {
            initDatabase()
            FirebaseData.ref.child("users").child(user.uid).child("travels").child(travel.id).child("steps").setValue(travel.steps)
        }
    }
    
    public static func updateDistance(travel: Travel) {
        if let user = Auth.auth().currentUser {
            initDatabase()
            FirebaseData.ref.child("users").child(user.uid).child("travels").child(travel.id).child("km").setValue(travel.km)
        }
    }
    
   // MARK: Helper functions
    
    /**
     * send notification to update settings UI
     */
    @objc private static func sendSettingsNotification() {
        NotificationCenter.default.post(name: Notification.Name("updateSettings"), object: nil)
    }
    
    /**
     * get the current users email address
     */
    public static func getMailAddress() -> String {
        if let user = Auth.auth().currentUser {
            return user.email ?? "traveldiscovery@example.com"
        }
        return "traveldiscovery@example.com"
    }
    
    /**
     * initialize the database reference, if this hasn't been done already
     * keep local database synced to online database
     */
    private static func initDatabase() {
        if (FirebaseData.ref == nil) {
            FirebaseData.ref = Database.database().reference()
            FirebaseData.ref.keepSynced(true)
        }
    }
    
    /**
     * removes all database observers
     */
    public static func removeObservers() {
        initDatabase()
        FirebaseData.ref.removeAllObservers()
    }
    
    /**
     * adding downloaded images to local cache on app start
     */
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
    
    /**
     * updating travel indices for sorting
     */
    public static func updateTravelsIndices(index: Int) {
        if let user = Auth.auth().currentUser {
            initDatabase()
            for travel in FirebaseData.travels.values {
                if (travel.sortIndex > index) {
                    travel.sortIndex -= 1
                    FirebaseData.ref.child("users").child(user.uid).child("travels").child(travel.id).child("sortIndex").setValue(travel.sortIndex)
                }
            }
        }
    }
    
    public static func endTrip(travel: Travel) {
        if let user = Auth.auth().currentUser {
            initDatabase()
            FirebaseData.ref.child("users").child(user.uid).child("travels").child(travel.id).child("active").setValue(travel.active)
            FirebaseData.ref.child("users").child(user.uid).child("travels").child(travel.id).child("end").setValue(travel.end)
        }
    }
    
    /**
     * saving the first image of the pin to local documents for better caching
     */
    public static func saveImageToDocuments(withUrl url : URL, pinImage: UIImage?) {
        
        if (pinImage != nil) {
            savetoDocs(image: pinImage!, url: url)
        } else {
            // check cached image
            if (FirebaseData.imageCache.object(forKey: url.lastPathComponent as NSString) as? UIImage) != nil {
                return
            }
            
            // if not, download image from url
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                if error != nil {
                    print(error!)
                    return
                }
                if let image = UIImage(data: data!) {
                    self.savetoDocs(image: image, url: url)
                }
            }).resume()
        }
    }
    
    /**
     * actually saving to local file
     */
    private static func savetoDocs(image: UIImage, url: URL) {
        if let data = UIImageJPEGRepresentation(image, 0.8) {
            let fileManager = FileManager.default
            do {
                let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
                let fileURL = documentDirectory.appendingPathComponent(url.lastPathComponent)
                try data.write(to: fileURL)
            } catch {
                print(error)
            }
        }
        FirebaseData.imageCache.setObject(image, forKey: url.lastPathComponent as NSString)
    }
    
}
