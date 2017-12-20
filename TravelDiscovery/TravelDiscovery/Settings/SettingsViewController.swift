//
//  SettingsViewController.swift
//  TravelDiscovery
//
//  Created by Jan on 25.11.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit
import FirebaseAuth
import Eureka
import HealthKit
import SwiftLocation
import UserNotifications

class SettingsViewController: FormViewController {

    @IBOutlet weak var stepLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let userSettings = UserDefaults.standard

        form +++ Section("Account Details")
            <<< EmailRow(){ row in
                row.title = "E-Mail Address"
                row.disabled = true
                row.placeholder = "traveldiscovery@example.com"
                row.value = FirebaseController.getMailAdress()
            }
            <<< ButtonRow(){ row in
                row.title = "Logout"
                row.onCellSelection(self.logOut)
            }
            <<< ButtonRow(){ row in
                row.title = "Delete Account"
                row.onCellSelection(self.deleteAccount)
            }
        +++ Section("Scratch Settings")
            <<< SliderRow("scratchPercentRow") { row in
                row.title = "ScratchPercent-Finish"
                row.minimumValue = 1
                row.maximumValue = 99
                row.steps = UInt(row.maximumValue - row.minimumValue)
                row.value = userSettings.float(forKey: "scratchPercent") != 0 ? userSettings.float(forKey: "scratchPercent") : 90.0
                row.onChange({row in
                    Timer.scheduledTimer(timeInterval: 0.5, target: FirebaseController.self, selector: #selector(FirebaseController.saveSettingsToFirebase), userInfo: ["key": "scratchPercent"], repeats: false) //need to use a timer to avoid too many changes
                    userSettings.set(row.value, forKey: "scratchPercent")
                })
            }
        +++ Section("Feed Settings")
            <<< NameRow("feedNameRow"){ row in
                row.title = "Your Name"
                row.placeholder = "John Doe"
                row.value = userSettings.string(forKey: "username")
                row.onChange({row in
                    Timer.scheduledTimer(timeInterval: 0.5, target: FirebaseController.self, selector: #selector(FirebaseController.saveSettingsToFirebase), userInfo: ["key": "username"], repeats: false) //need to use a timer to avoid too many changes
                    userSettings.set(row.value, forKey: "username")
                    
                })
            }
            <<< SwitchRow("postVisibilityRow") { row in
                row.value = userSettings.bool(forKey: "visibility") /*If not existing, returns false*/
                row.title = row.value! ? "Standard Visibility: Public" : "Standard Visibility: Private"
                row.onChange({row in
                    row.title = row.value! ? "Standard Visibility: Public" : "Standard Visibility: Private"
                    row.updateCell()
                    Timer.scheduledTimer(timeInterval: 0.5, target: FirebaseController.self, selector: #selector(FirebaseController.saveSettingsToFirebase), userInfo: ["key": "visibility"], repeats: false) //need to use a timer to avoid too many changes
                    userSettings.set(row.value, forKey: "visibility")
                })
            }
            <<< SliderRow("feedRangeRow") { row in
                row.title = "Feed Range (km)"
                row.minimumValue = 1
                row.maximumValue = 50
                row.steps = UInt(row.maximumValue - row.minimumValue)
                row.value = userSettings.float(forKey: "feedRange") != 0 ? userSettings.float(forKey: "feedRange") : 1.0
                row.onChange({row in
                    userSettings.set(row.value, forKey: "feedRange")
                    Timer.scheduledTimer(timeInterval: 0.5, target: FirebaseController.self, selector: #selector(FirebaseController.saveSettingsToFirebase), userInfo: ["key": "feedRange"], repeats: false) //need to use a timer to avoid too many changes
                })
            }
        
        +++ Section("Developers Corner")
            <<< SwitchRow("backgroundLocationRow"){ row in
                row.title = "Background Location Updates"
                row.value = false
                row.onChange({row in
                    self.backgroundLocationUpdates(enabled: row.value!)
                })
            }
            <<< SwitchRow("backgroundLocationNotificationRow"){ row in
                row.title = "Location Notifications"
                row.value = false
                row.onChange({row in
                    if(row.value!) {
                        let options: UNAuthorizationOptions = [.alert, .badge, .sound];
                        UNUserNotificationCenter.current().requestAuthorization(options: options) {
                            (granted, error) in
                            if !granted {
                                print("Something went wrong")
                            }
                        }
                    }
                    userSettings.set(row.value, forKey: "locationNotification")
                })
            }
            <<< ButtonRow(){ row in
                row.title = "Draw Route on Map"
                row.onCellSelection(self.drawLineOnMap)
            }
            <<< SwitchRow("devStepData"){ row in
                row.title = "Show Steps (req. Health Permission)"
                row.value = false
                row.hidden = Condition.function(["devStepData"], { form in
                    return row.value!
                })
            }
            <<< LabelRow("devStepDataLabel"){ row in
                row.hidden = Condition.function(["devStepData"], { form in
                    
                    let showData = (form.rowBy(tag: "devStepData") as? SwitchRow)?.value!
                    if (showData!) {
                        self.stepCounter()
                    }
                    return !showData!
                })
                

                row.title = "Steps today:"
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateSettings),
            name: Notification.Name("updateSettings"),
            object: nil)
        // Do any additional setup after loading the view.
    }
    
    func backgroundLocationUpdates(enabled: Bool) {
        let userSettings = UserDefaults.standard
        userSettings.set(enabled, forKey: "backgroundLocationUpdates")
        if (enabled) {
            if Locator.authorizationStatus != .authorizedAlways {
                let locationInfoAlert = UIAlertController(title: "LocationService", message: "You do not have background location enabled for TravelDiscovery. Please do so in the settings app to use background location updates.", preferredStyle: .alert)
                locationInfoAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                    DispatchQueue.main.async(execute: {
                        let backgroundLocationRow: SwitchRow? = self.form.rowBy(tag: "backgroundLocationRow")
                        backgroundLocationRow?.value = false
                        backgroundLocationRow?.updateCell()
                    })
                }))
                self.present(locationInfoAlert, animated: true, completion: nil)
                return
            }
            Locator.subscribeSignificantLocations(onUpdate: { location in
                FirebaseController.handleBackgroundLocationData(location: location)
            }) { (err, lastLocation) -> (Void) in
                print("Failed with err: \(err)")
            }
        } else {
            Locator.completeAllLocationRequests()
        }
    }
    
    func stepCounter() {
        
        guard let healthStore: HKHealthStore? = {
            if HKHealthStore.isHealthDataAvailable() {
                return HKHealthStore()
            } else {
                return nil
            }
            }() else {
                return
        }
        
        let stepsCount = HKQuantityType.quantityType(forIdentifier: .stepCount)
        
        let dataTypesToRead : Set<HKObjectType> = [stepsCount!]
        
        healthStore?.requestAuthorization(toShare: nil, read: dataTypesToRead) { (success, error) in
            if let error = error {
                print("Failed authorization = \(error.localizedDescription)")
                DispatchQueue.main.async(execute: {
                    let stepDataLabelRow: LabelRow? = self.form.rowBy(tag: "devStepDataLabel")
                    stepDataLabelRow?.value = "Error getting health data."
                    stepDataLabelRow?.updateCell()
                })
            }
            if (success) {
                let now = Date()
                let startOfDay = Calendar.current.startOfDay(for: now)
                let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
                
                let stepsSampleQuery = HKStatisticsQuery(quantityType: stepsCount!, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
                    var resultCount = 0.0
                    
                    guard let result = result else {
                        print("Failed to fetch steps = \(error?.localizedDescription ?? "N/A")")
                        return
                    }
                    
                    if let sum = result.sumQuantity() {
                        resultCount = sum.doubleValue(for: HKUnit.count())
                    }
                    DispatchQueue.main.async(execute: {
                        let stepDataLabelRow: LabelRow? = self.form.rowBy(tag: "devStepDataLabel")
                        stepDataLabelRow?.value = String(resultCount)
                        stepDataLabelRow?.updateCell()
                    })
                }
                // Don't forget to execute the Query!
                healthStore?.execute(stepsSampleQuery)
            }
        }
    }
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func updateSettings() {
        let userSettings = UserDefaults.standard
        
        let feedNameRow: NameRow? = form.rowBy(tag: "feedNameRow")
        feedNameRow?.value = userSettings.string(forKey: "username")
        feedNameRow?.updateCell()
        let postVisibilityRow: SwitchRow? = form.rowBy(tag: "postVisibilityRow")
        postVisibilityRow?.value = userSettings.bool(forKey: "visibility")
        postVisibilityRow?.updateCell()
        let feedRangeRow: SliderRow? = form.rowBy(tag: "feedRangeRow")
        feedRangeRow?.value = userSettings.float(forKey: "feedRange") != 0 ? userSettings.float(forKey: "feedRange") : 1.0
        feedRangeRow?.updateCell()
        let scratchPercentRow: SliderRow? = form.rowBy(tag: "scratchPercentRow")
        scratchPercentRow?.value = userSettings.float(forKey: "scratchPercent") != 0 ? userSettings.float(forKey: "scratchPercent") : 90.0
        scratchPercentRow?.updateCell()
    }
    
    /**
     * Logging the user out
     */
    func logOut(cell: ButtonCellOf<String>, row: ButtonRow) {
        FirebaseController.removeObservers()
        do {
            try Auth.auth().signOut()
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
        } catch {
            //error handling logout error
        }
        self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
    }
    /**
     * Ask for confirmation before deletion
     * removes all user data and removes the account.
     * Cannot be undone
     */
    func deleteAccount(cell: ButtonCellOf<String>, row: ButtonRow) {
        let deleteConfirmationAlert = UIAlertController(title: "WARNING: Account Deletion", message: "Are you sure you wish to delete your account? This cannot be undone!", preferredStyle: .alert)
        deleteConfirmationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
            FirebaseController.removeObservers()
            FirebaseController.removeUserData()
            Auth.auth().currentUser?.delete(completion: { (err) in
                if let err = err {
                    print(err.localizedDescription)
                    return
                }
                self.view.window!.rootViewController?.dismiss(animated: true, completion: {
                    /*TODO: Doesn't display so far, find out why not.*/
                    let deletedConfirmationAlert = UIAlertController(title: "Account deleted", message: "Your account has been deleted.", preferredStyle: .alert)
                    deletedConfirmationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(deletedConfirmationAlert, animated: true, completion: nil)
                })
            })
        }))
        deleteConfirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        deleteConfirmationAlert.view.tintColor = UIColor.red
        self.present(deleteConfirmationAlert, animated: true, completion: nil)
    }
    
    
    func drawLineOnMap(cell: ButtonCellOf<String>, row: ButtonRow) {
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
