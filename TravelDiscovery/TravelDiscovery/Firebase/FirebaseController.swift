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
import FirebaseStorage

class FirebaseController {
    
    public static func saveToFirebase() {
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
            print(vC)
            FirebaseData.ref.child("users").child(user.uid).setValue(["visitedCountries": vC])
        }
    }
    
    
    public static func retrieveFromFirebase() {
        if let user = Auth.auth().currentUser {
            if (FirebaseData.ref == nil) {
                // initialize database
                FirebaseData.ref = Database.database().reference()
            }
            FirebaseData.ref.child("users").child(user.uid).observeSingleEvent(of: .value, with: { (snapshot) in
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
                        let imageName = UUID().uuidString + ".png"
                        let storageRef = Storage.storage().reference().child("images").child(imageName)
                        
                        if let uploadData = UIImagePNGRepresentation(image) {
                            // upload image
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
                                        FirebaseData.ref.child("users").child(user.uid).child("pins").setValue([pin.id: fbDict])
                                    }
                                }
                            })
                        }
                    }
                }
                    // no images to upload: save pin to firebase immediately
                else {
                    let fbDict = pin.prepareDictForFirebase()
                    FirebaseData.ref.child("users").child(user.uid).setValue([pin.id: fbDict])
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

            FirebaseData.ref.child("users").child(user.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                let fbD = value?["pins"] as? Dictionary<String, Pin> ?? [:]
                FirebaseData.pins = fbD
                
                NotificationCenter.default.post(name: Notification.Name("updatePins"), object: nil)
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
}
