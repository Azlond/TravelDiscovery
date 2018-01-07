//
//  AppDelegate.swift
//  TravelDiscovery
//
//  Created by Jan on 22.11.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit
import Firebase
import SwiftLocation
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        
        let userSettings = UserDefaults.standard
        let enableBackgroundLocationUpdates = userSettings.bool(forKey: "backgroundLocationUpdates")
        if (enableBackgroundLocationUpdates) {
            Locator.subscribeSignificantLocations(onUpdate: { location in
                //short delay to make sure all other location data is loaded correctly
                Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.sendBackgroundLocationData), userInfo: location, repeats: false)
            }) { (err, lastLocation) -> (Void) in
                print("Failed with err: \(err)")
            }
        }
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let vc: UIViewController
        if (UserDefaults.standard.bool(forKey: "loggedIn")) {
            let storyBoard: UIStoryboard = UIStoryboard(name: "NavigationTabBar", bundle: nil)
            vc = storyBoard.instantiateViewController(withIdentifier: "NavigationTabBarController") as! UITabBarController
            Auth.auth().addStateDidChangeListener { (auth, user) in
                if user != nil {
                    FirebaseController.retrieveFromFirebase()
                }
            }
        } else {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
            vc = storyBoard.instantiateViewController(withIdentifier: "LoginVC")
        }
        
        self.window?.rootViewController = vc
        return true
    }
    
    @objc func sendBackgroundLocationData(timer: Timer) {
        let location = timer.userInfo as! (CLLocation)
        FirebaseController.handleBackgroundLocationData(location: location)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

