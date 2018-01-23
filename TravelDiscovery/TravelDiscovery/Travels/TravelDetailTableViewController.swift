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
        
        
       // infoTableView.estimatedRowHeight = 44.0
     //   infoTableView.rowHeight = UITableViewAutomaticDimension
        
       
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    @objc func updateSteps(_ notification: NSNotification) {
        DispatchQueue.main.async {
            if let travel = FirebaseData.travels[self.travelId] {
                self.stepsLabel.text = String(describing: Int(travel.steps))
            }
        }
    }
   
    // MARK: - Table view data source
/*
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 4
    }
*/

    
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
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
