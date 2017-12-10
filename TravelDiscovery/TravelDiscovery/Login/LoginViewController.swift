//
//  LoginViewController.swift
//  TravelDiscovery
//
//  Created by Jan on 22.11.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit
import FirebaseAuth

// TODO: Beautify UI for all login screens

class LoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                
                // if available, get user data from server
                FirebaseController.retrieveFromFirebase()

                //User is already logged in, no need to show login storyboard
                let storyBoard: UIStoryboard = UIStoryboard(name: "NavigationTabBar", bundle: nil)
                let newViewController = storyBoard.instantiateViewController(withIdentifier: "NavigationTabBarController") as! UITabBarController
                self.present(newViewController, animated: true, completion: nil)
                /*
                let vc = storyBoard.instantiateViewController(withIdentifier: "NavigationTabBarController") as! UITabBarController
                let navigationController = UINavigationController(rootViewController: vc)
                self.present(navigationController, animated: true, completion: nil)*/
            }
        }
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
