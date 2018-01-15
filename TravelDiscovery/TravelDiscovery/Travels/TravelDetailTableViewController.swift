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
    var datePickerHidden = true
    var rowTag : Int = 0
    
    @IBOutlet var infoTableView: UITableView!
    @IBOutlet weak var beginDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
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
            datePicker.setDate(convertedBeginDate!, animated: false)
            self.rowTag = 0 // damit Begin Date geändert wird
            beginDateLabel.text = DateFormatter.localizedString(from: datePicker.date, dateStyle: Travel.dateStyle, timeStyle: Travel.timeStyle)
            //datePickerChanged()
        }
        let end   = FirebaseData.travels[self.travelId]?.end
        let convertedEndDate = dateFormatter.date(from: end!)
        if (convertedEndDate != nil) {
            datePicker.setDate(convertedEndDate!, animated: false)
            self.rowTag = 1 // damit End Date geändert wird
            endDateLabel.text = DateFormatter.localizedString(from: datePicker.date, dateStyle: Travel.dateStyle, timeStyle: Travel.timeStyle)
            //datePickerChanged()
        }
       
       
        let steps = Int((FirebaseData.travels[self.travelId]?.getSteps())!)
        let km = (FirebaseData.travels[self.travelId]?.getKm())!
        self.stepsLabel.text = String(describing: steps)
        self.kmLabel.text = String(describing: km)
        
       // infoTableView.estimatedRowHeight = 44.0
     //   infoTableView.rowHeight = UITableViewAutomaticDimension
        
       
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if datePickerHidden && indexPath.section == 2 && indexPath.row == 2 {
            return 0
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
        
        // return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // && self.datePickerHidden
        if indexPath.section == 2 && (indexPath.row == 0 || indexPath.row == 1) {
            
            let alert = UIAlertController(title: "Change Begin Date", message: "Are you sure you want to change the begin date?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
               
                self.toggleDatepicker ()
            }))
             self.rowTag = indexPath.row
            self.present(alert, animated: true, completion: nil)
            
        }
    }
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
    
    

    @IBAction func beginDatePickerValue(_ sender: UIDatePicker) {
        datePickerChanged()
    }
    
    func datePickerChanged () {
        if rowTag == 0 {
            beginDateLabel.text = DateFormatter.localizedString(from: datePicker.date, dateStyle: Travel.dateStyle, timeStyle: Travel.timeStyle)
            
            FirebaseData.travels[self.travelId]!.begin = beginDateLabel.text
        } else if rowTag == 1 {
            endDateLabel.text = DateFormatter.localizedString(from: datePicker.date, dateStyle: Travel.dateStyle, timeStyle: Travel.timeStyle)
            FirebaseData.travels[self.travelId]!.end = endDateLabel.text
        }
        FirebaseController.updateTravelInFirebase(travel: FirebaseData.travels[self.travelId]!)
    }
    
    func toggleDatepicker() {
        datePickerHidden = !datePickerHidden
     
        infoTableView.beginUpdates()
        infoTableView.endUpdates()
        
        
      
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        datePicker.isHidden = true
    }
    
}
