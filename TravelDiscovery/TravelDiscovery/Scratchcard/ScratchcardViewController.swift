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
    
    @IBOutlet var scratchView: UIView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    /*
     * Hide the status bar during scratchview
     */
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Country: " + country)
        print(UIScreen.main.nativeBounds.width)
        
        //TODO: change hardcoded coupon "USA" to country variable once dataset for map is implemented
        scratchCard  = ScratchUIView(frame: CGRect(x:5, y:navigationBar.bounds.height+5, width:scratchView.bounds.width-10, height:scratchView.bounds.height-navigationBar.bounds.height-10),Coupon: "USA", MaskImage: "mask.png", ScratchWidth: CGFloat(40))
        scratchCard.delegate = self
        self.view.addSubview(scratchCard)
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
     * TODO: change hardcoded value to user defined setting
     */
    func checkForCompletion() {
        let scratchPercent: Double = scratchCard.getScratchPercent()
        if scratchPercent > 0.9 {
            finishSuccess()
        }
    }
    
    /**
     * Cancel scratchcard without coloring the selected country
     */
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    /**
     * automatically finish scratching for the user
     */
    @IBAction func autocompleteButtonTaped(_ sender: UIBarButtonItem) {
        finishSuccess()
    }
    
    /**
     * Call function in parent to color the scratched country
     * Dismiss scratch view
     */
    func finishSuccess() {
        parentVC.markCountry(name: country)
        self.dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
