//
//  TravelsTableViewController.swift
//  TravelDiscovery
//
//  Created by Jan on 25.11.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit

var countries = [String]()
// var countryImages = [UIImage]()
var dateInfos = [String]()

class TravelsTableViewController: UITableViewController, UISearchBarDelegate {

    @IBOutlet var travelsTableView: UITableView!
   
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    // MARK: - Table view data source

  
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countries.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell =
          //  UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil )
        tableView.dequeueReusableCell(withIdentifier: "countryCell", for: indexPath)
        cell.textLabel!.text = countries[row]
       // cell.imageView!.image = countryImages[row]
        // Configure the cell...

        return cell
    }
    

    /*
    
    @IBAction func countryAddTapped() {
        let alert = UIAlertController(title: "Add Country", message: nil, preferredStyle: .alert)
        alert.addTextField{(countryTF) in countryTF.placeholder = "Enter Country"
        }
        let action = UIAlertAction(title: "Add", style: .default) { (_) in
            guard let country = alert.textFields?.first?.text else { return }
            print(country)
            self.countries.append(country)
            self.tableView.reloadData()
        }
        alert.addAction(action)
        present(alert, animated: true)
    }
 */
    
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
            countries.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }    

   

    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let countryToMove = countries[(fromIndexPath as NSIndexPath).row]
        countries.remove(at: (fromIndexPath as NSIndexPath).row)
        countries.insert(countryToMove, at: (to as NSIndexPath).row)
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
}
