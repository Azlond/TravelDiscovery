//
//  MapViewController.swift
//  TravelDiscovery
//
//  Created by Jan on 25.11.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit
import Mapbox
import GSMessages

class MapViewController: UIViewController, MGLMapViewDelegate, UIGestureRecognizerDelegate {
    
    var mapView : MGLMapView!
    
    @IBOutlet weak var buttonAddPin: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a new map view using the Mapbox Light style.
        let styleURL = URL(string: "mapbox://styles/iostravelcrew/cjamqrp7r1cg92rphoiyqqhmm")
        let navigationBarHeight: CGFloat = self.navigationController!.navigationBar.frame.height
        let mapFrame = CGRect(x: 0, y: navigationBarHeight, width: view.bounds.width, height: view.bounds.height-navigationBarHeight)
        mapView = MGLMapView(frame: mapFrame, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.tintColor = .darkGray
        mapView.allowsRotating = false
        mapView.allowsTilting = false
        mapView.showsUserLocation = true
        
        // Set the map’s center coordinate and zoom level.
        mapView.setCenter(CLLocationCoordinate2D(latitude:39.23225, longitude:-97.91015), zoomLevel: 2, animated: true)
        
        view.addSubview(mapView)
        mapView.delegate = self
        
        // Add a tap gesture recognizer to the map view.
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gesture.delegate = self
        mapView.addGestureRecognizer(gesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.delegate = self
        mapView.addGestureRecognizer(longPressGesture)
        
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showUploadErrorAlert),
            name:Notification.Name("uploadError"),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showUploadSuccessMessage),
            name:Notification.Name("uploadSuccess"),
            object: nil)
        
        
        FirebaseController.retrieveTravelsFromFirebase()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        buttonAddPin!.title = (FirebaseData.getActiveTravel() != nil) ? "📍" : "New Trip"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //prevents Pin/New Trip button from staying highlighted
        buttonAddPin.isEnabled = false
        buttonAddPin.isEnabled = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        if (gesture.state == .began) {
            // Get the CGPoint where the user tapped.
            let spot = gesture.location(in: mapView)
            // Access the features at that point within the country layer.
            let features = mapView.visibleFeatures(at: spot, styleLayerIdentifiers: Set(["countries copy"]))
            
            // get the selected country name
            if let feature = features.first, let country = feature.attribute(forKey: "name") as? String{
                if (FirebaseData.visitedCountries[country] == true) {
                    let alert = UIAlertController(title: "Remove Country", message: "Do you want to reset " + country + "?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        FirebaseData.visitedCountries.removeValue(forKey: country)
                        self.updateMap()
                        FirebaseController.countryToFirebase(countryName: country, add: false)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // required to allow tap on map and tap on annotations at the same time
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func showUploadErrorAlert(_ notification: NSNotification) {
        let type = notification.userInfo?["type"] as? String
        let message = "An error occurred during " + type! + " upload"
        self.showMessage(message, type: .error)
    }
    
    @objc func showUploadSuccessMessage(_ notification: NSNotification) {
        let type = notification.userInfo?["type"] as? String
        let message = type! + " upload complete"
        self.showMessage(message, type: .success, options: [.autoHideDelay(2.0)])
    }
    
    
    // MARK: Map
    
    // Wait until the style is loaded before modifying the map style.
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        updateMap()
        addLayer(to: style)
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        let userLocation: CLLocationCoordinate2D = (mapView.userLocation?.coordinate)!
        
        //animate camera to zoom and center to user location
        let camera = MGLMapCamera(lookingAtCenter: userLocation, fromEyeCoordinate: mapView.centerCoordinate, eyeAltitude: 10000000)
        mapView.setCamera(camera, withDuration: 2, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut), completionHandler: {
            mapView.setDirection(0.0, animated: true)
        })
        UserDefaults.standard.set(userLocation.latitude, forKey: "latitude")
        UserDefaults.standard.set(userLocation.longitude, forKey: "longitude")
    }
    
    // MARK: Add markers/Pins
    
    /*
     * performs segue to the NewPinScene / PinViewController while setting the current location
     */
    @IBAction func addMarker(_ sender: UIBarButtonItem) {
        // add Pin to current active Travel if one exists
        if (FirebaseData.getActiveTravel() != nil) {
            //save current location in user defaults
            let userLocation: CLLocationCoordinate2D = (mapView.userLocation?.coordinate)!
            UserDefaults.standard.set(userLocation.longitude, forKey: "longitude")
            UserDefaults.standard.set(userLocation.latitude, forKey: "latitude")
            
            performSegue(withIdentifier: "addPin", sender: nil)
        }
        else {
            //go to Travels Tab
            tabBarController?.selectedIndex = 1
        }
    }
    
    /*
     * adds the user's private pins to the map
     */
    @objc func displayPinsOnMap() {
        // set Navigation Bar Button item
        buttonAddPin!.title = (FirebaseData.getActiveTravel() != nil) ? "📍" : "New Trip"
        
        //remove pins before redrawing them
        if let markers = mapView.annotations {
            mapView.removeAnnotations(markers)
        }
        
        for travelEntry in FirebaseData.travels {
            let travel = travelEntry.value
            
            for pinEntry in travel.pins{
                let pin = pinEntry.value
                let marker = MGLPointAnnotation()
                marker.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                marker.title = pin.name
                
                mapView.addAnnotation(marker)
            }
        }
    }
    
    /**
     * Show pin details on annotation (i) click
     */
    func mapView(_ mapView: MGLMapView, annotation: MGLAnnotation, calloutAccessoryControlTapped control: UIControl) {
        for travelEntry in FirebaseData.travels {
            let travel = travelEntry.value            
            for pinEntry in travel.pins{
                let pin = pinEntry.value
                //annotation != nil: preventing crash in rare cases where annotation is already removed right after it was clicked
                if ((annotation != nil) && annotation.coordinate.latitude == pin.latitude && annotation.coordinate.longitude == pin.longitude && annotation.title! == pin.name) {
                    let storyBoard = UIStoryboard(name: "PinDetailView", bundle: nil)
                    let pinDetailVC = storyBoard.instantiateViewController(withIdentifier: "PinDetail") as! PinDetailViewController
                    pinDetailVC.pin = pin
                    navigationController?.pushViewController(pinDetailVC, animated: true)
                    return
                }
            }
        }
    }
    
    /*
     * creates markers / pins for the map with colors according to longitude
     */
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        guard annotation is MGLPointAnnotation else {
            return nil
        }
        
        // Use the point annotation’s longitude value (as a string) as the reuse identifier for its view.
        let reuseIdentifier = "\(annotation.coordinate.longitude)"
        
        // try to reuse existing annotations.
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if annotationView == nil {
            annotationView = CustomAnnotationView(reuseIdentifier: reuseIdentifier)
            annotationView!.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
            
            // Set the annotation view’s background color to a value determined by its longitude.
            let hue = abs(CGFloat(annotation.coordinate.longitude)) / 180
            annotationView!.backgroundColor = UIColor(hue: hue, saturation: 0.5, brightness: 1, alpha: 1)
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        // Always allow callouts to popup when annotations are tapped.
        return true
    }
    
    func mapView(_ mapView: MGLMapView, rightCalloutAccessoryViewFor annotation: MGLAnnotation) -> UIView? {
        return UIButton(type: .detailDisclosure) 
    }
    
    // MARK: ScratchCard
    
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
        
        //only load scratchCard if there is a valid country code, and the country's image asset exists
        if scratchVC.countryCode != nil, let _ = UIImage(named: scratchVC.countryCode) {
            self.present(scratchVC, animated: true, completion: nil)
        }
    }
    
    
    /**
     * Parameter: countryname
     * Mark a country in a color
     */
    @objc public func markCountry(name: String) {
        if name.count > 0 {
            FirebaseData.visitedCountries[name] = true
            updateMap()
            FirebaseController.countryToFirebase(countryName: name, add: true)
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
    
    
    // MARK: Draw Route
    
    var timer: Timer?
    var polylineSource: MGLShapeSource?
    var currentIndex = 1
    
    /*
     * adds polyline to map
     */
    func addLayer(to style: MGLStyle) {
        // Add an empty MGLShapeSource, we’ll keep a reference to this and add points to this later.
        let source = MGLShapeSource(identifier: "polyline", shape: nil, options: nil)
        style.addSource(source)
        polylineSource = source
        
        // Add a layer to style our polyline.
        let layer = MGLLineStyleLayer(identifier: "polyline", source: source)
        layer.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        layer.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        layer.lineColor = MGLStyleValue(rawValue: UIColor.black.withAlphaComponent(0.5))
        layer.lineWidth = MGLStyleFunction(interpolationMode: .exponential,
                                           cameraStops: [14: MGLConstantStyleValue<NSNumber>(rawValue: 5),
                                                         18: MGLConstantStyleValue<NSNumber>(rawValue: 20)],
                                           options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.5)])
        
        let airportLayer = style.layer(withIdentifier: "airport-label")
        style.insertLayer(layer, below: airportLayer!)
    }
    
    
    @objc func animateTravel(_ notification: NSNotification) {
        guard let travelId = notification.userInfo?["travelID"] as? String else {
            return
        }
        currentIndex = 1
        startAnimation(travelId: travelId)
    }
    
    func startAnimation(travelId: String) {
        let numberTripLocations = FirebaseData.travels[travelId]?.routeData.count
        
        if numberTripLocations == nil || numberTripLocations! < 2 {
            let alert = UIAlertController(title: "Unable to draw route",
                                          message: "You don't have enough locations saved to draw a route",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        if currentIndex > numberTripLocations! {
            mapView.setDirection(0.0, animated: true)
            return
        }
        
        var coordinates = [CLLocationCoordinate2D]()
        for index in 0..<currentIndex {
            coordinates.append((FirebaseData.travels[travelId]?.routeData[String(index)])!)
        }
        
        // Update our MGLShapeSource with the current locations.
        updatePolylineWithCoordinates(coordinates: coordinates)
        
        // follow route with camera
        let currentLocation = CLLocation(latitude: coordinates[currentIndex-1].latitude, longitude: coordinates[currentIndex-1].longitude)
        
        if currentIndex == 1 {
            //animate camera to zoom and center to first location point
            let camera = MGLMapCamera(lookingAtCenter: currentLocation.coordinate, fromEyeCoordinate: mapView.centerCoordinate, eyeAltitude: 15000)
            mapView.setCamera(camera, withDuration: 2, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn), completionHandler: {
                self.mapView.setDirection(0.0, animated: true)
                self.currentIndex += 1
                self.startAnimation(travelId: travelId)
            })
        } else {
            // calculate the duration of the animation considering the distance
            let previousLocation = CLLocation(latitude: coordinates[currentIndex-2].latitude, longitude: coordinates[currentIndex-2].longitude)
            let distance = currentLocation.distance(from: previousLocation)
            let duration = getCameraRideDuration(distance: distance)
            
            let camera = MGLMapCamera(lookingAtCenter: currentLocation.coordinate, fromEyeCoordinate: mapView.centerCoordinate, eyeAltitude: 15000)
            
            if distance < 100000 {
                mapView.setCamera(camera, withDuration: duration, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear), completionHandler: {
                    self.currentIndex += 1
                    self.startAnimation(travelId: travelId)
                })
            } else {
                mapView.fly(to: camera, withDuration: duration, completionHandler: {
                    self.currentIndex += 1
                    self.startAnimation(travelId: travelId)
                })
            }
        }
    }
    
    /*
     * adjusts speed of camera ride in respect of the distance:
     * levels: the further two points are away from each other, the faster the speed
     */
    func getCameraRideDuration(distance: Double) -> Double {
        var duration: Double = 0.0
        // level: 0-3km
        if distance < 3000 {
            duration = distance / 2000 // 2000m/s
        }
            // level: 3-8km
        else if distance < 8000 {
            duration =  distance / 3000
        }
            // level: 8-20km
        else if distance < 20000 {
            duration = distance / 10000
        }
            // level: 20-50km
        else if distance < 50000 {
            duration = distance / 15000
        }
            // level: 50-100km
        else if distance < 100000 {
            duration = distance / 25000
        }
            // level: >= 100km -> flight
        else {
            duration = distance / 2000000
        }
        return duration
    }
    
    func updatePolylineWithCoordinates(coordinates: [CLLocationCoordinate2D]) {
        var mutableCoordinates = coordinates
        
        let polyline = MGLPolylineFeature(coordinates: &mutableCoordinates, count: UInt(mutableCoordinates.count))
        
        // Updating the MGLShapeSource’s shape will have the map redraw our polyline with the current coordinates.
        polylineSource?.shape = polyline
    }
    
}

