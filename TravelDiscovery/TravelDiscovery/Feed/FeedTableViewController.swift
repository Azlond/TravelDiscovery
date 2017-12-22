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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell", for: indexPath) as? FeedTableViewCell else {
            fatalError("The dequeued cell is not an instance of FeedTableViewCell.")
        }
        let pin = FirebaseData.publicPins[indexPath.row]
        
        cell.usernameLabel.text = pin.name
        
        var previewText : String = "No impression available."
        if let text = pin.text {
            if (text.count > 0) {
                previewText = text
            }
        }

        cell.previewTextLabel.text = previewText
        cell.previewTextLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.previewTextLabel.numberOfLines = 0
        
        if ((pin.imageURLs?.count ?? 0) > 0) {
            cell.previewImage.image = UIImage(named: "default")
            cell.previewImage.loadImageUsingCache(withUrl: pin.imageURLs![0]) //Int(arc4random_uniform(UInt32(pin.imageURLs!.count)))])
        } else {
            cell.previewImage.image = UIImage(named: "default")
        }
        
        return cell
    }
    
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

}
extension NSMutableAttributedString {
    @discardableResult func bold(_ text: String) -> NSMutableAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont(name: "AvenirNext-Medium", size: 20)!]
        let boldString = NSMutableAttributedString(string:text, attributes: attrs)
        append(boldString)
        
        return self
    }
    
    @discardableResult func normal(_ text: String) -> NSMutableAttributedString {
        let normal = NSAttributedString(string: text)
        append(normal)
        
        return self
    }
}

let imageCache = NSCache<NSString, AnyObject>()

extension UIImageView {
    func loadImageUsingCache(withUrl urlString : String) {
        let url = URL(string: urlString)
        
        // check cached image
        if let cachedImage = imageCache.object(forKey: urlString as NSString) as? UIImage {
            self.image = UIImage(named: "default")
            self.image = self.resizeImage(image: cachedImage, targetSize: CGSize(width: 120, height: 120))
            return
        }
        
        // if not, download image from url
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            if error != nil {
                print(error!)
                return
            }
            
            DispatchQueue.main.async {
                if let image = UIImage(data: data!) {
                    imageCache.setObject(image, forKey: urlString as NSString)
                    self.image = UIImage(named: "default")
                    self.image = self.resizeImage(image: image, targetSize: CGSize(width: 120, height: 120))
                }
            }
            
        }).resume()
    }
    
    /**
     * resize downloaded image to fit into the UIImageView
     */
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
