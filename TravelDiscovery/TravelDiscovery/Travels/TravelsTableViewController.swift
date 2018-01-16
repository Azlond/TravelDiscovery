//
//  TravelsTableViewController.swift
//  TravelDiscovery
//
//  Created by Jan on 25.11.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit
import Firebase


class TravelsTableViewController: UITableViewController {
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var travelId : String = ""
    var travels: [Travel] = []
    override func viewDidLoad() {
        
        super.viewDidLoad()
       
       
         tableView.estimatedRowHeight = 80
         tableView.rowHeight = UITableViewAutomaticDimension
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        self.refreshControl?.addTarget(self, action: #selector(self.handleRefresh), for: UIControlEvents.valueChanged)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTravels),
            name: Notification.Name("updateTravels"),
            object: nil)
        
        populateTravels()       
        handleRefresh()
        self.updateAddButton()
    }

    func populateTravels() {
        if (travels.count > 0) {
            travels.removeAll()
        }
        outer: for index in 0 ..< FirebaseData.travels.count {
            for travel in FirebaseData.travels {
                if (travel.value.sortIndex == index) {
                    travels.append(travel.value)
                    continue outer
                }
            }
        }
        travels = travels.reversed()
    }
    
    /**
     * reload data view, end refresh
     */
    @objc func updateTravels() {
        tableView.reloadData()
    }
    
    /**
     * refresh public pins, get new data from server
     */
    @objc func handleRefresh() {
        tableView.reloadData()
        FirebaseController.retrieveTravelsFromFirebase()
        //timeout in case no data can be retrieved
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(updateTravels), userInfo: nil, repeats: false)
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    // MARK: Tableview Datasource Methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.travels.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        //let travel = FirebaseData.travels[Array(FirebaseData.travels.keys)[row]]
        let travel = travels[row] //TODO: use this line and comment out the two lines above once deleting travels is no longer possible / we're updating the sortIndex for all travels

        //let pin = travel!.pins
        //let photos = FirebaseData.pins[pKey]!.photos

        let cell = tableView.dequeueReusableCell(withIdentifier: "travelCell", for: indexPath) as! TravelsTableViewCell
        cell.travelImageView.setRadius(borderWidth: (travel.active ? 3 : 0))
        //  cell.travelImageView.layoutSubviews()
        cell.travelNameLabel.text = travel.name
        let beginDate = "From " + travel.begin! + "  "
        let onTraveling = "⇨   On traveling ✈️"
   
        
        
        
        if(travel.end! != ""){
            cell.travelDateLabel.text = beginDate + "⇨   To " + travel.end!
        } else {
             cell.travelDateLabel.text = beginDate + onTraveling
        }
        
        // set images
        cell.travelImageView.image = UIImage(named: "default2")
        if (travel.pins.count > 0) {
            let pinKey = Array(travel.pins.keys)[0]
            let pin = travel.pins[pinKey]
            if ((pin!.imageURLs?.count ?? 0) > 0) {
                cell.travelImageView.loadImageUsingCache(withUrl: pin!.imageURLs![0], tableview: tableView, indexPath: indexPath)
            }
        }

        return cell
    }
    
    // MAR: Add New Countries
    
    @IBAction func addButtonPressed() {
        if (FirebaseData.getActiveTravel() == nil) {
            // no active travel => adding a new travel and switch button (in addNewTravel)
            self.addNewTravel()
        }
        else {
            // there is an active travel => end the current travel and switch button
            let alert = UIAlertController(title: "End Trip", message: "Are you sure you want to end your trip?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                let activeTravel = FirebaseData.getActiveTravel()!
                activeTravel.endTrip()
                FirebaseController.updateTravelInFirebase(travel: activeTravel)
                self.addButton.title = "New Trip"
                self.populateTravels()
                self.tableView.reloadData()
            }))
            self.present(alert, animated: true, completion: nil)
        }
        self.reloadInputViews()
    }
    
    func updateAddButton() {
        if (FirebaseData.getActiveTravel() == nil) {
            self.addButton.title = "New Trip"
        }
        else {
            self.addButton.title = "End Trip"
        }
    }
    
    func addNewTravel() {
        var textField = UITextField()
        let addAction = UIAlertAction(title: "Add", style: .default, handler: { _ in
            let id = "Travel_" + UUID().uuidString
            let name = textField.text!
            if name.isEmpty {} else {
                let travel : Travel = Travel.init(id: id, name: name, sortIndex: (FirebaseData.getHighestSortIndex()+1))!
                travel.begin = DateFormatter.localizedString(from: Date(), dateStyle: Travel.dateStyle, timeStyle: Travel.timeStyle)
                // save travel to firebase
                FirebaseData.travels[travel.id] = travel
                FirebaseController.addTravelToFirebase(travel: travel)
                self.populateTravels()
                self.tableView.reloadData()
                self.addButton.title = "End Trip"
            }
        })
        addAction.isEnabled = false
        
        let alert = UIAlertController(title: "Create New Trip", message: "", preferredStyle: .alert)
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "i.e. My trip to Disney World"
            alertTextField.autocapitalizationType = .words
            textField = alertTextField
            // Observe the UITextFieldTextDidChange notification to be notified in the below block when text is changed
            NotificationCenter.default.addObserver(forName: .UITextFieldTextDidChange, object: textField, queue: OperationQueue.main, using: {_ in
                    addAction.isEnabled = (!textField.text!.isEmpty)
            })
        }
        
        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
 
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        
        guard editingStyle == .delete  else {
            return
        }
    
        //tableView.deleteRows(at: [indexPath], with: .fade)
        let row = indexPath.row
        
        let travel = travels[row]
        // Show a confirm message before delete
        // wenn travel is active
        if (travel.active == true){
            
            let alert = UIAlertController(title: "Your are on traveling!", message: "Are you sure you want to delete your trip?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                FirebaseData.getActiveTravel()?.endTrip()
                // delete the travel row from the date source
                //let k = Array(FirebaseData.travels.keys)[row]
                let travel = self.travels[row]
                FirebaseData.travels.removeValue(forKey: travel.id)
                FirebaseController.removeTravelFromFirebase(travelid: travel.id)
                //tableView.deleteRows(at: [indexPath], with: .automatic)
                //FirebaseController.saveTravelsToFirebase()
              
                self.addButton.title = "New Trip"
                print(self.addButton.title)
                let userSettings = UserDefaults.standard
                userSettings.set("", forKey: "activeTravelID")
                
                self.populateTravels()
                self.tableView.reloadData()
            }))
            
             self.present(alert, animated: true, completion: nil)
            
            
        } else {
            // wenn travel is not active
            let alert = UIAlertController(title: "Delete Trip", message: "Are you sure you want to delete your trip?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                
                // Delete the travel row from the data source
                //let k = Array(FirebaseData.travels.keys)[row]
                let travel = self.travels[row]
                if let sortIndex = FirebaseData.travels[travel.id]?.sortIndex {
                    FirebaseController.updateTravelsIndices(index: sortIndex)
                }
                FirebaseData.travels.removeValue(forKey: travel.id)
                FirebaseController.removeTravelFromFirebase(travelid: travel.id)
                self.populateTravels()
                //tableView.deleteRows(at: [indexPath], with: .automatic)
                self.tableView.reloadData()
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
 
     
        
        }    

   

    
    // Override to support rearranging the table view.
    /*
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        //let countryToMove = countries[(fromIndexPath as NSIndexPath).row]
        print("position ändern fehlt")
        //countries.remove(at: (fromIndexPath as NSIndexPath).row)
        //countries.insert(countryToMove, at: (to as NSIndexPath).row)
        
    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
   
    
    override func viewDidAppear(_ animated: Bool) {
        self.populateTravels()
        self.tableView.reloadData()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
  
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
       
        if segue.identifier == "sequeTravelDetail" {
            let cell = sender as! UITableViewCell
            let indexPath = self.tableView.indexPath(for: cell)
            let travelDetailView = segue.destination as! TravelDetailTableViewController
            let row = indexPath!.row
            let k = travels[row].id
            travelDetailView.travelId = k
            //travelDetailView.setCountryName(countries[((indexPath as NSIndexPath?)?.row)!])
            
            
    
        }

    }
 
}

extension UIImageView {
    func setRadius(radius: CGFloat? = nil, borderWidth: CGFloat? = nil) {
        self.layer.cornerRadius = radius ?? self.frame.width / 2;
        self.layer.borderWidth = borderWidth ?? 1;
        //self.layer.borderColor = UIColor.green.cgColor
        self.layer.borderColor = UIColor(red: 85/255, green: 170/255, blue: 153/255, alpha: 0.8).cgColor
        self.layer.masksToBounds = true;
        
    }

}
