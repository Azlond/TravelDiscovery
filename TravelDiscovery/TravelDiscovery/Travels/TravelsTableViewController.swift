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
    @IBOutlet var travelsTableView: UITableView!
   
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        self.refreshControl?.addTarget(self, action: #selector(self.handleRefresh), for: UIControlEvents.valueChanged)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTravels),
            name: Notification.Name("updateTravels"),
            object: nil)
        self.tableView.reloadData()
        
        handleRefresh()
    }

    /**
     * reload data view, end refresh
     */
    @objc func updateTravels() {
        self.tableView.reloadData()
    }
    
    /**
     * refresh public pins, get new data from server
     */
    @objc func handleRefresh() {
        self.tableView.reloadData()
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
        return FirebaseData.travels.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "travelCell", for: indexPath)
        
        let k = Array(FirebaseData.travels.keys)[row]
        let name = FirebaseData.travels[k]!.name
        
        cell.textLabel?.text = name
        //cell.textLabel?.text = countries[row]
       // cell.imageView!.image = countryImages[row]
        
        return cell
    }
    

    // MARK: Tableview Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        let k = Array(FirebaseData.travels.keys)[row]
        let name = FirebaseData.travels[k]!.name
        print(name)
    }
    
    
    // MAR: Add New Countries
    
    @IBAction func addButtonPressed() {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Travels", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add", style: .default) { (action) in
            
            
            let id = "Travel_" + UUID().uuidString
            let name = textField.text!
            let travel : Travel = Travel.init(id: id, name: name)!
            
            // save pin to firebase
            FirebaseData.travels[travel.id] = travel
            FirebaseController.saveTravelsToFirebase()
            
            
            
            self.tableView.reloadData()
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new travel"
            textField = alertTextField
            
        }
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
        
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
        guard editingStyle == .delete else { return }
            // Delete the row from the data source
            //tableView.deleteRows(at: [indexPath], with: .fade)
        let row = indexPath.row
        let k = Array(FirebaseData.travels.keys)[row]
        FirebaseData.travels.removeValue(forKey: k)
        FirebaseController.removeTravelFromFirebase(travelid: k)
            //countries.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        }    

   

    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        //let countryToMove = countries[(fromIndexPath as NSIndexPath).row]
        print("position ändern fehlt")
        //countries.remove(at: (fromIndexPath as NSIndexPath).row)
        //countries.insert(countryToMove, at: (to as NSIndexPath).row)
    }
    

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
   
    override func viewDidAppear(_ animated: Bool) {
        travelsTableView.reloadData()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
  /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
       
        if segue.identifier == "travelDetail" {
            let cell = sender as! UITableViewCell
            let indexPath = self.travelsTableView.indexPath(for: cell)
            let countryDetailView = segue.destination as! TravelDetailViewController
            countryDetailView.setCountryName(countries[((indexPath as NSIndexPath?)?.row)!])
    
        }

    }
 */
}
