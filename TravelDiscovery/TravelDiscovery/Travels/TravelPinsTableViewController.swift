
//
//  TravelPinsTableViewController.swift
//  Copy of FeedTableViewController.swift
//  TravelDiscovery
//
//  Created by Hyerim on 13.01.18.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftLocation

class TravelPinsTableViewController: UITableViewController {
    var travelId : String = ""
    var privatePins: [Pin] = []
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //include Nib in TableView
        let nib = UINib.init(nibName: "PinTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "PinTableViewCell")
        
        self.tableView.estimatedRowHeight = 320
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.refreshControl?.addTarget(self, action: #selector(self.handleRefresh), for: UIControlEvents.valueChanged)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateFeed),
            name: Notification.Name("updateFeed"),
            object: nil)
        
        if let travelCount = FirebaseData.travels[self.travelId]?.pins.count {
            outer: for index in 1 ..< travelCount + 1 {
                for pin in (FirebaseData.travels[self.travelId]?.pins)! {
                    if (pin.value.number == index) {
                        privatePins.append(pin.value)
                        continue outer
                    }
                }
            }
        }
        
        if let nav = self.navigationController, let item = nav.navigationBar.topItem {
            item.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action:nil)
        }
       
        self.tableView.reloadData()
        
        handleRefresh()
        self.title = FirebaseData.travels[self.travelId]?.name
    }
    
    
    /**
     * reload data view, end refresh
     */
    @objc func updateFeed() {
        if (self.refreshControl!.isRefreshing) {
            self.refreshControl?.endRefreshing()
        }
        self.tableView.reloadData()
    }
    
    
    /**
     * refresh public pins, get new data from server
     */
    @objc func handleRefresh() {
        self.tableView.reloadData()
        FirebaseController.retrieveTravelsFromFirebase()
        //timeout in case no data can be retrieved
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(updateFeed), userInfo: nil, repeats: false)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    /**
     * if no pins are available, display error message
     */
    override func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSections: Int = 0
        if (FirebaseData.travels[self.travelId]?.pins.count != 0) {
            tableView.separatorStyle = .singleLine
            numOfSections            = 1
            tableView.backgroundView = nil
        } else {
            let formattedString = NSMutableAttributedString()
            formattedString
                .bold("No 📍 available for this travel")
            let noDataLabel: UILabel     = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.attributedText = formattedString
            noDataLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
            noDataLabel.textColor     = UIColor.black
            noDataLabel.textAlignment = .center
            noDataLabel.numberOfLines = 0
            tableView.backgroundView  = noDataLabel
            tableView.separatorStyle  = .none
        }
        return numOfSections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (FirebaseData.travels[self.travelId]?.pins.count)!
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PinTableViewCell", for: indexPath) as? PinTableViewCell else {
            fatalError("The dequeued cell is not an instance of PinTableViewCell.")
        }

        let pin = privatePins[indexPath.row] 
        let geoCoder = CLGeocoder()
        let location: CLLocation = CLLocation.init(latitude: pin.latitude, longitude: pin.longitude)
        geoCoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
            if let placemark = placemarks?[0]  {
                if let cityName = placemark.locality {
                    cell.usernameLabel.text = cityName
                } else {
                    cell.usernameLabel.text = pin.username
                }
            }
        })
        
        cell.pinNameLabel.text = pin.name
        
        var previewText : String = ""
        if let text = pin.text {
            if (text.count > 0) {
                previewText = text
            }
        }
        cell.textView.text = previewText
        cell.imgView.image = nil
        cell.imgView.setRandomBackgroundColor()
        
        if ((pin.imageURLs?.count ?? 0) > 0) {
            cell.imgView.loadImageUsingCache(withUrl: pin.imageURLs![0], tableview: tableView, indexPath: indexPath)
        }
        else if pin.videoThumbnailURL != nil {
            cell.imgView.loadImageUsingCache(withUrl: pin.videoThumbnailURL!, tableview: tableView, indexPath: indexPath)
        }
        else {
            cell.imgView.image = UIImage(named: "default2")
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 320
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pin = privatePins[indexPath.row]
        let storyBoard = UIStoryboard(name: "PinDetailView", bundle: nil)
        let pinDetailVC = storyBoard.instantiateViewController(withIdentifier: "PinDetail") as! PinDetailViewController
        pinDetailVC.pin = pin
        pinDetailVC.isFeedPin = false
        navigationController?.pushViewController(pinDetailVC, animated: true)
        
    }
}
