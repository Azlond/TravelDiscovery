//
//  TravelAddViewController.swift
//  TravelDiscovery
//
//  Created by Hyerim Park on 19/12/2017.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit

class TravelAddViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    let countryData : [String] = Array(CountriesDict.Countries.keys).sorted {$0 < $1}
       
    @IBOutlet weak var countryPicker: UIPickerView!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var countrySelectButton: UIButton!
    
    @IBOutlet weak var doneItem: UIBarButtonItem!
    
  
    override func viewDidLoad() {
        super.viewDidLoad()
        countryPicker.dataSource = self
        countryPicker.delegate = self
        
        countryPicker.isHidden = true

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // Column count: use one column
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // Row count: rows equals with array length
        return countryData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return countryData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedCountry = countryData[row]
        countrySelectButton.setTitle(selectedCountry, for: UIControlState.normal)
    }
    
    @IBAction func showCountryPickerAction(_ sender: UIButton) {
        if countryPicker.isHidden == false {
            countryPicker.isHidden = true
        } else {
            countryPicker.isHidden = false
        }
    }
    
    @IBAction func countryAddDoneItem(_ sender: UIBarButtonItem) {
        
        countries.append(countrySelectButton.currentTitle!)
         _ = navigationController?.popViewController(animated: true)
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        countryPicker.isHidden = true
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
