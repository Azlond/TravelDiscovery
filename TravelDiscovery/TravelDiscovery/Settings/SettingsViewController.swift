//
//  SettingsViewController.swift
//  TravelDiscovery
//
//  Created by Jan on 25.11.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit
import FirebaseAuth
import HealthKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var stepLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        stepCounter()
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
            }
        }
        
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
                self.stepLabel.text = String(Int(resultCount))
            })
        }
        
        // Don't forget to execute the Query!
        healthStore?.execute(stepsSampleQuery)
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
