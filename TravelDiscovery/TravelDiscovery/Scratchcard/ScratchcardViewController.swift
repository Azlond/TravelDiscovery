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
       
    @IBOutlet var scratchView: UIView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Country: " + country)
        print(UIScreen.main.nativeBounds.width)
        
        scratchCard  = ScratchUIView(frame: CGRect(x:0, y:navigationBar.bounds.height, width:scratchView.bounds.width, height:scratchView.bounds.height-20),Coupon: country, MaskImage: "mask.png", ScratchWidth: CGFloat(40))
        scratchCard.delegate = self
        self.view.addSubview(scratchCard)
    }
    
    
    //Scratch Began Event(optional)
    func scratchBegan(_ view: ScratchUIView) {
        print("scratchBegan")
        
        ////Get the Scratch Position in ScratchCard(coordinate origin is at the lower left corner)
        let position = Int(view.scratchPosition.x).description + "," + Int(view.scratchPosition.y).description
        print(position)
        
        let scratchPercent: Double = scratchCard.getScratchPercent()
        if scratchPercent > 0.9 {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    //Scratch Moved Event(optional)
    func scratchMoved(_ view: ScratchUIView) {
        let scratchPercent: Double = scratchCard.getScratchPercent()
        if scratchPercent > 0.9 {
                self.dismiss(animated: true, completion: nil)
        }
        print("scratchMoved")
        
        ////Get the Scratch Position in ScratchCard(coordinate origin is at the lower left corner)
     //   let position = Int(view.scratchPosition.x).description + "," + Int(view.scratchPosition.y).description
    //    print(position)
        print(scratchPercent)
    }
    
    //Scratch Ended Event(optional)
    func scratchEnded(_ view: ScratchUIView) {
        print("scratchEnded")
        
        ////Get the Scratch Position in ScratchCard(coordinate origin is at the lower left corner)
        let position = Int(view.scratchPosition.x).description + "," + Int(view.scratchPosition.y).description
        print(position)
        
        let scratchPercent: Double = scratchCard.getScratchPercent()
        if scratchPercent > 0.9 {
            self.dismiss(animated: true, completion: nil)
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
