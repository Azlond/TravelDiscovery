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
    var id: String
    var number: Int
    var name: String
    var longitude: Double
    var latitude: Double
    var visibilityPublic: Bool
    var date: String
    var username: String
    
    /*optionals*/
    var text: String?
    var photos: [UIImage]? = []
    var imageURLs: [String]? = []
    var videoUploadURL: URL?
    var videoDownloadURL : String?
    var videoThumbnail: UIImage?
    var videoThumbnailURL : String?
    
    
    //MARK: Initialization
    
    init?(id: String, number: Int, name: String, longitude: Double, latitude: Double, visibilityPublic: Bool, date: String, photos: [UIImage]?, videoURL: URL?, videoThumbnail: UIImage?, text: String?) {
        // Initialization should fail if there is no name
        guard !name.isEmpty else {
            return nil
        }
        
        // Initialize stored properties.
        self.id = id
        self.name = name
        self.longitude = longitude
        self.latitude = latitude
        self.visibilityPublic = visibilityPublic
        self.date = date
        self.photos = photos
        self.videoUploadURL = videoURL
        self.videoThumbnail = videoThumbnail
        self.text = text
        self.number = number
        self.username = UserDefaults.standard.string(forKey: "username") ?? "Anonymous"
        
    }
    
    //init Pin from FirebaseDictionary
    init?(dict: (Dictionary<String,Any>))  {
        self.id =  dict["id"] as! String
        self.name = dict["name"] as! String
        self.longitude = dict["long"] as! Double
        self.latitude = dict["lat"] as! Double
        self.visibilityPublic = dict["visibilityPublic"] as! Bool
        self.date = dict["date"] as! String
        self.number = dict["number"] as! Int
        self.username = dict["username"] as? String ?? "Anonymous"
        
        if let text = dict["text"] as? String {
            self.text = text
        }
        
        // create imageURLs array from URLs in dict
        var count = 1
        while let imageURL = dict["imageURL" + String(count)] {
            self.imageURLs?.append(imageURL as! String)
            count = count + 1
        }
        
        if let videoURL = dict["videoDownloadURL"] as? String {
            self.videoDownloadURL = videoURL
            if let thumbnailURL = dict["videoThumbnailURL"] as? String {
                self.videoThumbnailURL = thumbnailURL
            }
        }
        
    }
    
    // MARK: Firebase
    
    func prepareDictForFirebase() -> Dictionary<String, Any>{
        var dict = [String:Any]()
        
        dict =     ["id":self.id,
                    "name":self.name,
                    "long":self.longitude,
                    "lat":self.latitude,
                    "visibilityPublic":self.visibilityPublic,
                    "date":self.date,
                    "number":self.number,
                    "username":self.username]
        
        //optionals
        if text != nil {
            dict["text"] = self.text
        }
        if imageURLs != nil {
            var count = 1
            for imageURL in imageURLs! {
                dict["imageURL" + String(count)] = imageURL
                count = count + 1
            }
        }
        
        if videoDownloadURL != nil {
            dict["videoDownloadURL"] = self.videoDownloadURL
        }
        if videoThumbnailURL != nil {
            dict["videoThumbnailURL"] = self.videoThumbnailURL
        }
        
        return dict
    }
}
