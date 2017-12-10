//
//  TravelDetailViewController.swift
//  TravelDiscovery
//
//  Created by Hyerim Park on 02.12.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit

class TravelDetailViewController: UIViewController {
    
    var setCountryName = ""
    var countryFlag: UIImage?
    var flagName = ""
    var departureDate = ""
    
    @IBOutlet weak var countryNameLabel: UILabel!
    @IBOutlet weak var countryFlagImageView: UIImageView!
    @IBOutlet weak var departureDateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        countryNameLabel.text = setCountryName
        
       // countryFlagImageView.image = UIImage(named: "\(String(describing: countryNameLabel.text))")
        countryFlagImageView.image = UIImage(named: "\(setCountryName)")
        departureDateLabel.text = departureDate
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setCountryName(_ country: String) {
        setCountryName = country
    }
    
    func setDepartureDate (_ date: String){
        departureDate = date
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
