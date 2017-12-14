//
//  SettingsViewController.swift
//  TravelDiscovery
//
//  Created by Jan on 25.11.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit
import FirebaseAuth

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     * Logging the user out
     * TODO: Move function to better UI, logout can stay the same though
     * TODO: Potentially upload/save everything to firebase before logout
     */
    @IBAction func temporaryLogoutTapped(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            let storyBoard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "LoginVC")
            self.present(newViewController, animated: true, completion: nil)
        } catch {
            //error handling logout error
        }
    }
    
    
    @IBAction func drawLineOnMap(_ sender: UIButton) {
        NotificationCenter.default.post(name: Notification.Name("drawLine"), object: nil)        
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
