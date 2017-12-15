//
//  PinViewController.swift
//  TravelDiscovery
//
//  Created by Laura on 13.12.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import Foundation
import UIKit

class PinViewController: UITableViewController {
    
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var commentsTextView: UITextView!
    @IBOutlet weak var publicSwitch: UISwitch!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBorderToTextView()
        
    }
    
    func addBorderToTextView() {
        let color = UIColor.init(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
        commentsTextView.layer.borderWidth = 0.5
        commentsTextView.layer.borderColor = color.cgColor
        commentsTextView.layer.cornerRadius = 5.0
        
    }
    
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableViewAutomaticDimension
//    }
//
//    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableViewAutomaticDimension
//    }
    
    @IBAction func clickedCancel(_ sender: UIBarButtonItem) {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func clickedSave(_ sender: UIBarButtonItem) {
        //required parameters
        let name = locationTextField.text
        let date = dateTextField.text
        let longitude = 0.123
        let latitude = 0.456
        
        //TODO: error handling: required fields not filled out
        
        let visibility = publicSwitch.isOn
        let text = commentsTextView.text
        
        let pin : Pin = Pin.init(name: name!, longitude: longitude, latitude: latitude,
                           visibilityPublic: visibility, date: date!,
                           photos: <#T##[UIImage]?#>, text: text!)!
        savePin(pin: pin)
        
    }
    
    func savePin(pin: Pin) {
        //
    }
    
    

}

