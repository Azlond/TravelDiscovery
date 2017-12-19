//
//  TravelsDateViewController.swift
//  
//
//  Created by Hyerim Park on 19/12/2017.
//

import UIKit

class TravelsDateViewController: UIViewController {

    @IBOutlet weak var departureDateButton: UIButton!
    @IBOutlet weak var returnDateButton: UIButton!
    
    @IBOutlet weak var returnDateLabel: UILabel!
    @IBOutlet weak var travelDatePicker: UIDatePicker!
    @IBOutlet weak var travelDateDoneItem: UIBarButtonItem!
    
    var buttonTag: Int = 1
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        returnDateButton.isHidden = true
        returnDateLabel.isHidden = true
        travelDatePicker.isHidden = true

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

   
    @IBAction func travelDateDone(_ sender: UIBarButtonItem) {
       
        _ = navigationController?.popViewController(animated: true)
    }
    
   
    
    @IBAction func showTravelDatePicker(_ sender: UIButton) {
        if travelDatePicker.isHidden == false {
            travelDatePicker.isHidden = true
        } else {
            travelDatePicker.isHidden = false
        }
        
        buttonTag = sender.tag
        
    }
    
    
    @IBAction func showReturnDate(_ sender: UISwitch) {
        returnDateButton.isHidden = !sender.isOn
        returnDateLabel.isHidden = !sender.isOn
        if buttonTag == 1 {
            buttonTag = 2
        } else {
            buttonTag = 1
        }
    }
    
   
    @IBAction func showDatePicker(_ sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-YY"
        
        let dateString = formatter.string(from: sender.date)
        
        if buttonTag == 1 {
            departureDateButton.setTitle(dateString, for: UIControlState.normal)
            
        } else {
            returnDateButton.setTitle(dateString, for: UIControlState.normal)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        travelDatePicker.isHidden = true
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
