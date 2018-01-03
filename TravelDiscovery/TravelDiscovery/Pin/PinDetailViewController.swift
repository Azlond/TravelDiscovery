//
//  PinDetailViewController.swift
//  TravelDiscovery
//
//  Created by admin on 03.01.18.
//  Copyright © 2018 Jan. All rights reserved.
//

import UIKit

class PinDetailViewController: UIViewController {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var primaryImageView: UIImageView!
    @IBOutlet weak var pinNameLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imagesCV: UICollectionView!
    @IBOutlet weak var videoDisplay: UIImageView!
    
    
    var pin: Pin!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the navigation bar on the this view controller
        //self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        usernameLabel.text = "by " + pin.username
        pinNameLabel.text = pin.name
        
        textView.text = ""
        if let text = pin.text {
            textView.text = text
        }
        
        primaryImageView.image = primaryImageView.resizeImage(image: UIImage(named: "default2")!)
        
        if ((pin.imageURLs?.count ?? 0) > 0) {
            primaryImageView.loadImageUsingCache(withUrl: pin.imageURLs![0])
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigation bar on other view controllers
       // self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @IBAction func backPressed(_ sender: UIButton) {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
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
