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

class SettingsViewController: FormViewController {

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
                    userSettings.set(row.value, forKey: "scratchPercent")
                    FirebaseController.saveSettingsToFirebase(key: "scratchPercent")
                })
            }
        +++ Section("Feed Settings")
            <<< NameRow("feedNameRow"){ row in
                row.title = "Your Name"
                row.placeholder = "John Doe"
                row.value = userSettings.string(forKey: "username")
                row.onChange({row in
                    userSettings.set(row.value, forKey: "username")
                    FirebaseController.saveSettingsToFirebase(key: "username")
                })
            }
            <<< SwitchRow("postVisibilityRow") { row in
                row.value = userSettings.bool(forKey: "visibility") /*If not existing, returns false*/
                row.title = row.value! ? "Standard Visibility: Public" : "Standard Visibility: Private"
                row.onChange({row in
                    row.title = row.value! ? "Standard Visibility: Public" : "Standard Visibility: Private"
                    row.updateCell()
                    userSettings.set(row.value, forKey: "visibility")
                    FirebaseController.saveSettingsToFirebase(key: "visibility")
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
                    FirebaseController.saveSettingsToFirebase(key: "feedRange")
                })
            }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateSettings),
            name: Notification.Name("updateSettings"),
            object: nil)
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
