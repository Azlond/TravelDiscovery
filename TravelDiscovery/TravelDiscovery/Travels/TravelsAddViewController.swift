//
//  TravelsAddViewController.swift
//  TravelDiscovery
//
//  Created by Hyerim Park on 10/12/2017.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit

class TravelsAddViewController: UIViewController {

    @IBOutlet weak var countryNameLabel: UILabel!
    @IBOutlet weak var countryNameTextField: UITextField!
    
    @IBOutlet weak var departureDateButton: UIButton!
    @IBOutlet weak var returnDateLabel: UILabel!
    @IBOutlet weak var returnDateButton: UIButton!
    @IBOutlet weak var selectDatePicker: UIDatePicker!
    
    var buttonTag: Int = 1
    var detailViewController = TravelDetailViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        returnDateLabel.isHidden = true
        returnDateButton.isHidden = true
        selectDatePicker.isHidden = true

       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func countryAddButton(_ sender: Any) {
        countries.append(countryNameTextField.text!)
        _ = navigationController?.popViewController(animated: true)
        
    }
    @IBAction func countryAddItem(_ sender: Any) {
        countries.append(countryNameTextField.text!)
        _ = navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func showDatePickerAction(_ sender: UIButton) {
       
        
        if selectDatePicker.isHidden == false {
            selectDatePicker.isHidden = true
        } else {
            selectDatePicker.isHidden = false
        }
        
        buttonTag = sender.tag
    }
    
    @IBAction func showReturnDateAction(_ sender: UISwitch) {
        returnDateButton.isHidden = !sender.isOn
        returnDateLabel.isHidden = !sender.isOn
    }
    
    @IBAction func selectedDateAction(_ sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-YY"
        
        let dateString = formatter.string(from: sender.date)
        if buttonTag == 1 {
             departureDateButton.setTitle(dateString, for: UIControlState.normal)
             detailViewController.setDepartureDate(dateString)
        } else {
            returnDateButton.setTitle(dateString, for: UIControlState.normal)
        }
       
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        selectDatePicker.isHidden = true
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
