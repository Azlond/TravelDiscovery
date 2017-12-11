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
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let center = UNUserNotificationCenter.current()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        let options: UNAuthorizationOptions = [.alert, .badge, .sound];
        center.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                print("Something went wrong")
            }
        }

        /* Locator.subscribeSignificantLocations(onUpdate: { (newLocation) -> (Void) in
            print("ho")
            print(newLocation)
            Locator.location(fromCoordinates: newLocation.coordinate, onSuccess: { places in
                    print(places)
                }, onFail: { err in
                    print("\(err)")
                })
            }, onFail: { (err, loc) -> (Void) in
                print("Failed to get location: \(err)")
            })*/
        
        Locator.subscribeSignificantLocations(onUpdate: { newLocation in
            print("New location \(newLocation)")
            Locator.location(fromCoordinates: newLocation.coordinate, onSuccess: { places in
                print(places)
                let content = UNMutableNotificationContent()
                content.title = "New Location Update"
                content.body = "You're somewhere new: \(places)"
                content.sound = UNNotificationSound.default()
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
                let identifier = "UYLLocalNotification"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                self.center.add(request, withCompletionHandler: { (error) in
                    if let error = error {
                        print("\(error)")
                    }
                })
            }, onFail: { err in
                print("\(err)")
            })
        }) { (err, lastLocation) -> (Void) in
            print("Failed with err: \(err)")
        }
        
        return true
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

