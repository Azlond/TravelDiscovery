//
//  MapViewController.swift
//  TravelDiscovery
//
//  Created by Jan on 25.11.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit
import Mapbox

class MapViewController: UIViewController, MGLMapViewDelegate, UIGestureRecognizerDelegate {

    var mapView : MGLMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Create a new map view using the Mapbox Light style.
        let styleURL = URL(string: "mapbox://styles/iostravelcrew/cjamqrp7r1cg92rphoiyqqhmm")
        mapView = MGLMapView(frame: view.bounds, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.tintColor = .darkGray
        
        // Set the map’s center coordinate and zoom level.
        mapView.setCenter(CLLocationCoordinate2D(latitude:39.23225, longitude:-97.91015), animated: true)
        
        view.addSubview(mapView)
        mapView.delegate = self
        
        // Add a tap gesture recognizer to the map view.
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gesture.delegate = self
        mapView.addGestureRecognizer(gesture)
        mapView.allowsRotating = false
        mapView.allowsTilting = false
        mapView.showsUserLocation = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMap),
            name: Notification.Name("updateMap"),
            object: nil)
    }
    
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        
        // Get the CGPoint where the user tapped.
        let spot = gesture.location(in: mapView)
        // Access the features at that point within the country layer.
        let features = mapView.visibleFeatures(at: spot, styleLayerIdentifiers: Set(["countries copy"]))
        
        // Get the name of the selected state.
        if let feature = features.first, let country = feature.attribute(forKey: "name") as? String{
            if (FirebaseData.visitedCountries[country] == true) {
                //TODO: needs more user interaction/confirmation
                FirebaseData.visitedCountries.removeValue(forKey: country)
                updateMap()
                FirebaseController.saveToFirebase()
            } else {
                loadScratchcard(name: country)
            }
        }
    }

    // Wait until the style is loaded before modifying the map style.
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        updateMap()
    }
    
    /**
     * load the Scratchcard with the selected country
     * add self as viewcontroller to the scratchview, in order to be able to call the markCountry() function from scratchView
     * add countryname to scratchview to load the correct image
     */
    func loadScratchcard(name: String) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Scratchcard", bundle: nil)
        let scratchVC = storyBoard.instantiateViewController(withIdentifier: "ScratchcardVC") as! ScratchcardViewController
        scratchVC.parentVC = self
        scratchVC.country = name
        scratchVC.countryCode = CountriesDict.Countries[name]
        print("Country: " + name)
        
        //only load scratchCard if there is a valid country code, and the country's image asset exists
        if scratchVC.countryCode != nil, let _ = UIImage(named: scratchVC.countryCode) {
            self.present(scratchVC, animated: true, completion: nil)
        }
    }
    
    
    /**
     * Parameter: countryname
     * Mark a country in a color
     * TODO: save colored countries to firebase after edit
     */
    @objc public func markCountry(name: String) {
        if name.count > 0 {
            FirebaseData.visitedCountries[name] = true
            updateMap()
            FirebaseController.saveToFirebase()
        }
    }
    /**
     * Iterate through all visited countries, mark them on map
     */
    @objc func updateMap() {
        if let layer = mapView.style?.layer(withIdentifier: "countries copy") as! MGLFillStyleLayer? {
            var sourceStops : Dictionary<String, MGLStyleValue<NSNumber>> = [:]
            for country in FirebaseData.visitedCountries {
                sourceStops[country.key] = MGLStyleValue<NSNumber>(rawValue: 1)
            }
            
            if (sourceStops.count > 0) {
                layer.fillOpacity = MGLStyleValue(interpolationMode: .categorical, sourceStops: sourceStops, attributeName: "name", options: [.defaultValue: MGLStyleValue<NSNumber>(rawValue: 0)])
            } else {
                //if no countries have been scratched free yet, we need to pass an empty string as sourceStop to stop the app from crashing
                layer.fillOpacity = MGLStyleValue(interpolationMode: .categorical, sourceStops: ["": MGLStyleValue<NSNumber>(rawValue: 1)], attributeName: "name", options: [.defaultValue: MGLStyleValue<NSNumber>(rawValue: 0)])
            }
        } else {
            return
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
     */

}
