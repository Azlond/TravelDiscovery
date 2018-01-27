//
//  TravelDetailTableViewController.swift
//  TravelDiscovery
//
//  Created by Hyerim Park on 19/12/2017.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit
import Firebase

class TravelDetailTableViewController: UITableViewController {
    
    var travelId : String = ""
 
    @IBOutlet var infoTableView: UITableView!
    @IBOutlet weak var beginDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
 
    @IBOutlet weak var kmLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = FirebaseData.travels[self.travelId]?.name
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = Travel.dateStyle
        dateFormatter.timeStyle = Travel.timeStyle
        let begin = FirebaseData.travels[self.travelId]?.begin
        let convertedBeginDate = dateFormatter.date(from: begin!)
        if (convertedBeginDate != nil) {
            beginDateLabel.text = DateFormatter.localizedString(from: convertedBeginDate!, dateStyle: Travel.dateStyle, timeStyle: Travel.timeStyle)
        }
        let end   = FirebaseData.travels[self.travelId]?.end
        let convertedEndDate = dateFormatter.date(from: end!)
        if (convertedEndDate != nil) {
            endDateLabel.text = DateFormatter.localizedString(from:convertedEndDate!, dateStyle: Travel.dateStyle, timeStyle: Travel.timeStyle)
        }
       
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateSteps),
            name:Notification.Name("updateSteps"),
            object: nil)
       
        let steps = Int((FirebaseData.travels[self.travelId]?.getSteps())!)
        let km = (FirebaseData.travels[self.travelId]?.getKm())!
        self.stepsLabel.text = String(describing: steps)
        self.kmLabel.text = String(describing: km) + " km"
        
    }
    
    @objc func updateSteps(_ notification: NSNotification) {
        DispatchQueue.main.async {
            if let travel = FirebaseData.travels[self.travelId] {
                self.stepsLabel.text = String(describing: Int(travel.steps))
            }
        }
    }

    
    @IBAction func drawRouteClicked(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name("drawLine"), object: nil, userInfo: ["travelID":self.travelId])
        tabBarController?.selectedIndex = 0
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "sequeTravelPins" {
            let travelPinsView = segue.destination as! TravelPinsTableViewController
            travelPinsView.travelId = self.travelId
        }
        
    }
    
}
