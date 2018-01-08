//
//  FeedTableViewController.swift
//  TravelDiscovery
//
//  Created by Jan on 25.11.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit

class FeedTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //include Nib in TableView
        let nib = UINib.init(nibName: "PinTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "PinTableViewCell")

//        self.tableView.estimatedRowHeight = 100
//        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.rowHeight = 300
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.refreshControl?.addTarget(self, action: #selector(self.handleRefresh), for: UIControlEvents.valueChanged)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateFeed),
            name: Notification.Name("updateFeed"),
            object: nil)

        self.tableView.reloadData()
        
        handleRefresh()
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
        FirebaseController.retrievePublicPinsFromFirebase()
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
        if (FirebaseData.publicPins.count != 0) {
            tableView.separatorStyle = .singleLine
            numOfSections            = 1
            tableView.backgroundView = nil
        } else {
            let formattedString = NSMutableAttributedString()
            formattedString
                .bold("No public 📍 available near you. \n\n")
                .normal("Try increasing your radius or be the first to publish a 📍 here!")
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
        // #warning Incomplete implementation, return the number of rows
        return FirebaseData.publicPins.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PinTableViewCell", for: indexPath) as? PinTableViewCell else {
            fatalError("The dequeued cell is not an instance of PinTableViewCell.")
        }
        let pin = FirebaseData.publicPins[indexPath.row]
        
        cell.usernameLabel.text = pin.username
        cell.pinNameLabel.text = pin.name

        var previewText : String = ""
        if let text = pin.text {
            if (text.count > 0) {
                previewText = text
            }
        }
        cell.textView.text = previewText

        if ((pin.imageURLs?.count ?? 0) > 0) {
            cell.imgView.loadImageUsingCache(withUrl: pin.imageURLs![0]) //Int(arc4random_uniform(UInt32(pin.imageURLs!.count)))])
        } else {
            cell.imgView.image = cell.imgView.resizeImage(image: UIImage(named: "default2")!)
        }
        
        //TODO (nice to have): if multiple images are available: show multi image preview
        
        return cell
    }
    
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableViewAutomaticDimension
//    }
//
//    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 300
//    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pin = FirebaseData.publicPins[indexPath.row]

        let storyBoard = UIStoryboard(name: "PinDetailView", bundle: nil)
        let pinDetailVC = storyBoard.instantiateViewController(withIdentifier: "PinDetail") as! PinDetailViewController
        pinDetailVC.pin = pin
        navigationController?.pushViewController(pinDetailVC, animated: true)

    }

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

}
