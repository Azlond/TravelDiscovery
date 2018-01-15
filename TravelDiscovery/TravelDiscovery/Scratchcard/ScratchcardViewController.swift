//
//  ScratchcardViewController.swift
//  TravelDiscovery
//
//  Created by Jan on 25.11.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit
import ScratchCard

class ScratchcardViewController: UIViewController, ScratchUIViewDelegate {
    
    var scratchCard: ScratchUIView!
    var country: String!
    var countryCode: String!
    var parentVC: MapViewController!
    var userScratchPercent : Double!
    var lock = false
    
    @IBOutlet var scratchView: UIView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var autoCompleteButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    /*
     * Hide the status bar during scratchview
     */
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cardWidth = scratchView.bounds.width-10
        let cardHeight = scratchView.bounds.height-navigationBar.bounds.height-10
        
        scratchCard  = ScratchUIView(frame: CGRect(x:5, y:navigationBar.bounds.height+5,
                                                   width:cardWidth,
                                                   height:cardHeight),
                                     Coupon: countryCode,
                                     MaskImage: "mask.png",
                                     ScratchWidth: CGFloat(40))
        scratchCard.delegate = self
        navigationBar.topItem?.title = country
        self.view.addSubview(scratchCard)
        
        let userSettings = UserDefaults.standard
        userScratchPercent = userSettings.double(forKey: "scratchPercent")
    }
    
    /*
     * Event when a scratch event begins
     * only calls checkForCompletion
     */
    func scratchBegan(_ view: ScratchUIView) {
        checkForCompletion()
    }
    
    /**
     * Event when a scratch event moves
     * only calls checkForCompletion
     */
    func scratchMoved(_ view: ScratchUIView) {
        checkForCompletion()
    }
    
    /**
     * Event when a scratch event finishes
     * only calls checkForCompletion
     */
    func scratchEnded(_ view: ScratchUIView) {
        checkForCompletion()
    }
    
    /**
     * function that checks how much of the scratchcard the user has already cleared.
     * if scratched value is higher than user selected percentage, end scratching
     */
    func checkForCompletion() {
        let scratchPercent: Double = scratchCard.getScratchPercent()
        if (scratchPercent > (userScratchPercent / 100) && !lock) {
            lock = true
            finishSuccess(sleepTime: 0.006)
        }
    }
    
    /**
     * Cancel scratchcard without coloring the selected country
     */
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        scratchCard.interrupted = true
        self.dismiss(animated: true, completion: nil)
    }
    /**
     * automatically finish scratching for the user
     */
    @IBAction func autocompleteButtonTaped(_ sender: UIBarButtonItem) {
        autoCompleteButton.isEnabled = false
        cancelButton.isEnabled = false
        finishSuccess(sleepTime: 0.006)
    }
    
    
    /**
     * finish the scratching
     * receive notification from async thread to check if we can already dismiss the view
     */
    func finishSuccess(sleepTime: Double) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dismissToPrevious),
            name: Notification.Name("dismissScratch"),
            object: nil)
        
        var sleepyTime = sleepTime
        
        if (UIDevice.current.modelName == "iPhone 6" || UIDevice.current.modelName == "iPhone 6 Plus" || UIDevice.current.modelName == "Simulator") {
            scratchCard.scratchView.setScratchWidth(width: CGFloat(160))
            sleepyTime = sleepyTime * 3
        }
        
        scratchCard.autoScratch(sleepTime: sleepyTime)
    }
    
    /**
     * Call function in parent to color the scratched country
     * Dismiss scratch view
     */
    @objc func dismissToPrevious() {
        if (scratchCard.getScratchPercent() == 1) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                self.parentVC.markCountry(name: self.country)
                self.dismiss(animated: true, completion: nil)
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
