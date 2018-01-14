//
//  LoginViewController.swift
//  TravelDiscovery
//
//  Created by Jan on 22.11.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit
import FirebaseAuth

// TODO: potentially make status not opaque and visible

class LoginViewController: UIViewController {
    
    
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var appName: UILabel!
    @IBOutlet weak var subText: UILabel!
    @IBOutlet weak var loginOptionsView: UIView!
    
    @IBOutlet weak var logoHeight: NSLayoutConstraint!
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //init alpha values (start values of animation)
        subText.alpha = 1.0
        loginOptionsView.alpha = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // new location of constraint for app name and logo
        self.logoHeight.constant = 160
        
        UIView.animate(withDuration: 1.3, delay: 0, options: .curveEaseInOut, animations: {
            self.subText.alpha = 0
            self.view.layoutIfNeeded() // animates the constraint change
        })
        
        UIView.animate(withDuration: 1.2, delay: 0.5, options: .curveEaseInOut, animations: {
            self.loginOptionsView.alpha = 1
        })
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
