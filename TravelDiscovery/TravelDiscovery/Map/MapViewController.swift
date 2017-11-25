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
        mapView = MGLMapView(frame: view.bounds, styleURL: MGLStyle.lightStyleURL())
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
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        
        // Get the CGPoint where the user tapped.
        let spot = gesture.location(in: mapView)
        // Access the features at that point within the state layer.
        let features = mapView.visibleFeatures(at: spot, styleLayerIdentifiers: Set(["state-layer"]))
        
        // Get the name of the selected state.
        if let feature = features.first, let state = feature.attribute(forKey: "name") as? String{
            changeOpacity(name: state)
        } else {
            changeOpacity(name: "")
        }
    }

    // Wait until the style is loaded before modifying the map style.
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        let url = URL(string: "mapbox://examples.69ytlgls")!
        let source = MGLVectorSource(identifier: "state-source", configurationURL: url)
        style.addSource(source)
        
        //---
        let layer = MGLFillStyleLayer(identifier: "state-layer", source: source)
        
        // Access the tileset layer.
        layer.sourceLayerIdentifier = "stateData_2-dx853g"
        
        // Create a stops dictionary. This defines the relationship between population density and a UIColor.
        let stops = [0: MGLStyleValue(rawValue: UIColor.yellow),
                     600: MGLStyleValue(rawValue: UIColor.red),
                     1200: MGLStyleValue(rawValue: UIColor.blue)]
        
        // Style the fill color using the stops dictionary, exponential interpolation mode, and the feature attribute name.
        layer.fillColor = MGLStyleValue(interpolationMode: .exponential, sourceStops: stops, attributeName: "density", options: [.defaultValue: MGLStyleValue(rawValue: UIColor.white)])
        
        // Insert the new layer below the Mapbox Streets layer that contains state border lines. See the layer reference for more information about layer names: https://www.mapbox.com/vector-tiles/mapbox-streets-v7/
        let symbolLayer = style.layer(withIdentifier: "admin-3-4-boundaries")
        style.insertLayer(layer, below: symbolLayer!)
        //----
    }
    
    func changeOpacity(name: String) {
        
        let layer = mapView.style?.layer(withIdentifier: "state-layer") as! MGLFillStyleLayer
        
        // Check if a state was selected, then change the opacity of the states that were not selected.
        if name.count > 0 {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Scratchcard", bundle: nil)
            let scratchVC = storyBoard.instantiateViewController(withIdentifier: "ScratchcardVC") as! ScratchcardViewController
            scratchVC.country = "USA"
            self.present(scratchVC, animated: true, completion: nil)
            layer.fillOpacity = MGLStyleValue(interpolationMode: .categorical, sourceStops: [name: MGLStyleValue<NSNumber>(rawValue: 1)], attributeName: "name", options: [.defaultValue: MGLStyleValue<NSNumber>(rawValue: 0)])
        } else {
            // Reset the opacity for all states if the user did not tap on a state.
            layer.fillOpacity = MGLStyleValue(rawValue: 1)
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
