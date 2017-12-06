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
    
    @IBOutlet weak var countryNameLabel: UILabel!
    
    @IBOutlet weak var countryFlagImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        countryNameLabel.text = setCountryName
        
       // countryFlagImageView.image = UIImage(named: "\(String(describing: countryNameLabel.text))")
        countryFlagImageView.image = UIImage(named: "\(setCountryName)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setCountryName(_ country: String) {
        setCountryName = country
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
