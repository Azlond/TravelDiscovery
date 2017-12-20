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
    //TODO: implement properly
    var activeTrip : Bool! = true
    
    @IBOutlet weak var buttonAddPin: UIBarButtonItem!
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set Navigation Bar Button item
        buttonAddPin!.title = activeTrip ? "📍" : "New Trip"

        // Create a new map view using the Mapbox Light style.
        let styleURL = URL(string: "mapbox://styles/iostravelcrew/cjamqrp7r1cg92rphoiyqqhmm")
        let navigationBarHeight: CGFloat = self.navigationController!.navigationBar.frame.height
        let mapFrame = CGRect(x: 0, y: navigationBarHeight, width: view.bounds.width, height: view.bounds.height-navigationBarHeight)
        mapView = MGLMapView(frame: mapFrame, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.tintColor = .darkGray
        
        // Set the map’s center coordinate and zoom level.
        mapView.setCenter(CLLocationCoordinate2D(latitude:39.23225, longitude:-97.91015), zoomLevel: 2, animated: true)
        
        view.addSubview(mapView)
        mapView.delegate = self
        
        // Add a tap gesture recognizer to the map view.
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gesture.delegate = self
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.delegate = self
        mapView.addGestureRecognizer(gesture)
        mapView.addGestureRecognizer(longPressGesture)
        mapView.allowsRotating = false
        mapView.allowsTilting = false
        mapView.showsUserLocation = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMap),
            name: Notification.Name("updateMap"),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(animateTravel),
            name: Notification.Name("drawLine"),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayPinsOnMap),
            name:Notification.Name("updatePins"),
            object: nil)
        
        FirebaseController.retrievePinsFromFirebase()
        
    }
    
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        
        // Get the CGPoint where the user tapped.
        let spot = gesture.location(in: mapView)
        // Access the features at that point within the country layer.
        let features = mapView.visibleFeatures(at: spot, styleLayerIdentifiers: Set(["countries copy"]))
        
        // Get the name of the selected state.
        if let feature = features.first, let country = feature.attribute(forKey: "name") as? String{
            if (FirebaseData.visitedCountries[country] != true) {
                loadScratchcard(name: country)
            }
        }
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        // Get the CGPoint where the user tapped.
        let spot = gesture.location(in: mapView)
        // Access the features at that point within the country layer.
        let features = mapView.visibleFeatures(at: spot, styleLayerIdentifiers: Set(["countries copy"]))
        
        // Get the name of the selected state.
        if let feature = features.first, let country = feature.attribute(forKey: "name") as? String{
            if (FirebaseData.visitedCountries[country] == true) {
                //TODO: needs more user interaction/confirmation
                let alert = UIAlertController(title: "Remove Country", message: "Do you want to reset " + country + "?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    FirebaseData.visitedCountries.removeValue(forKey: country)
                    self.updateMap()
                    FirebaseController.saveCountriesToFirebase()
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    // Wait until the style is loaded before modifying the map style.
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        updateMap()
        addLayer(to: style)
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(animateTravel), userInfo: nil, repeats: false)
        
        
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        let userLocation: CLLocationCoordinate2D = (mapView.userLocation?.coordinate)!
        
        //animate camera to zoom and center to user location
        let camera = MGLMapCamera(lookingAtCenter: userLocation, fromEyeCoordinate: mapView.centerCoordinate, eyeAltitude: 10000000)
        mapView.setCamera(camera, withDuration: 2, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        
        //save current location to user defaults
        UserDefaults.standard.set(userLocation.longitude, forKey: "longitude")
        UserDefaults.standard.set(userLocation.latitude, forKey: "latitude")
    }
    

    
    @objc func displayPinsOnMap() {
        //remove pins before redrawing them
        if let markers = mapView.annotations {
            mapView.removeAnnotations(markers)
        }
        
        for pinEntry in FirebaseData.pins{
            let pin = pinEntry.value
            let marker = MGLPointAnnotation()
            marker.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            marker.title = pin.name
            //onclick: kleines pop up name/bild? pfeil zu pin in Travels->Pins
            
            mapView.addAnnotation(marker)
        }
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
            FirebaseController.saveCountriesToFirebase()
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
    
    
    var timer: Timer?
    var polylineSource: MGLShapeSource?
    var currentIndex = 1
    
    
    func addLayer(to style: MGLStyle) {
        // Add an empty MGLShapeSource, we’ll keep a reference to this and add points to this later.
        let source = MGLShapeSource(identifier: "polyline", shape: nil, options: nil)
        style.addSource(source)
        polylineSource = source
        
        // Add a layer to style our polyline.
        let layer = MGLLineStyleLayer(identifier: "polyline", source: source)
        layer.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        layer.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        layer.lineColor = MGLStyleValue(rawValue: UIColor.red)
        layer.lineWidth = MGLStyleFunction(interpolationMode: .exponential,
                                           cameraStops: [14: MGLConstantStyleValue<NSNumber>(rawValue: 5),
                                                         18: MGLConstantStyleValue<NSNumber>(rawValue: 20)],
                                           options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.5)])
        style.addLayer(layer)
    }
    
    @IBAction func addMarker(_ sender: UIBarButtonItem) {
        if activeTrip {
            //save current location in user defaults
            let userLocation: CLLocationCoordinate2D = (mapView.userLocation?.coordinate)!
            UserDefaults.standard.set(userLocation.longitude, forKey: "longitude")
            UserDefaults.standard.set(userLocation.latitude, forKey: "latitude")
            
            performSegue(withIdentifier: "addPin", sender: nil)
        }
        else {
            //openAddTravelView()
        }
    }
    
   @objc func animateTravel() {
        currentIndex = 1
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    }
    
    
    @objc func tick() {
        if currentIndex > FirebaseData.locationData.count {
            timer?.invalidate()
            timer = nil
            return
        }
        var coordinates = [CLLocationCoordinate2D]()
        for index in 0..<currentIndex {
            coordinates.append(FirebaseData.locationData[index]!)
        }
        // Update our MGLShapeSource with the current locations.
        updatePolylineWithCoordinates(coordinates: coordinates)
        
        //TODO: follow coordinates with camera
        
        currentIndex += 1
    }
    
    func updatePolylineWithCoordinates(coordinates: [CLLocationCoordinate2D]) {
        var mutableCoordinates = coordinates
        
        let polyline = MGLPolylineFeature(coordinates: &mutableCoordinates, count: UInt(mutableCoordinates.count))
        
        // Updating the MGLShapeSource’s shape will have the map redraw our polyline with the current coordinates.
        polylineSource?.shape = polyline
    }
    
}
