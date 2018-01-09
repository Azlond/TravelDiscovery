//
//  ScratchUIView.swift
//  ScratchCard
//
//  Created by JoeJoe on 2016/4/15.
//  Copyright © 2016年 JoeJoe. All rights reserved.
//

import Foundation
import UIKit


var uiScratchWidth: CGFloat!

@objc public protocol ScratchUIViewDelegate: class {
    @objc optional func scratchBegan(_ view: ScratchUIView)
    @objc optional func scratchMoved(_ view: ScratchUIView)
    @objc optional func scratchEnded(_ view: ScratchUIView)
}

open class ScratchUIView: UIView, ScratchViewDelegate {
    
    open weak var delegate: ScratchUIViewDelegate!
    public var scratchView: ScratchView!
    var maskImage: UIImageView!
    var maskPath: String!
    var coupponPath: String!
    open var scratchPosition: CGPoint!
    open var interrupted: Bool!
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.Init()
    }

    open func autoScratch(sleepTime: Double) {
        scratchView.isUserInteractionEnabled = false
        let viewSize = scratchView.getContentLayer().bounds
        let screenWidth = Int(viewSize.width)
        let screenHeight = Int(viewSize.height)
        var xyArray = [(Double,Double)]()
        
        let lineWidth: CGFloat!
        lineWidth = scratchView.getScratchWidth() / 2
        
        scratchView.overrideLineWidth(lineWidth: lineWidth)
        
        for x in 0 ..< (screenWidth / Int(lineWidth)) + 2  {
            for y in 0 ..< (screenHeight / Int(lineWidth)) + 2 {
                xyArray.append(((Double(x)-0.5) * Double(lineWidth), (Double(y)-0.5) * Double(lineWidth)))
            }
        }
        for index in 0 ..< xyArray.count {
            if self.interrupted {
                return
            }
            /*Get random array index*/
            let randomXY = Int(arc4random_uniform(UInt32(xyArray.count)))
            
            let startPoint = CGPoint(x: xyArray[randomXY].0, y: xyArray[randomXY].1)

            /*send render command to timer*/
            Timer.scheduledTimer(timeInterval: Double(index)*sleepTime, target: self, selector: #selector(self.delegateScratch), userInfo: startPoint, repeats: false)
            
            /*remove chosen index from array*/
            xyArray.remove(at: randomXY)
        }
    }
    
    @objc func delegateScratch(_ timer: Timer) {
        if (self.getScratchPercent() < 1) {
            let startPoint = timer.userInfo as! CGPoint
            self.scratchView.renderLineFromPoint(startPoint, end: startPoint)
            NotificationCenter.default.post(name: Notification.Name("dismissScratch"), object: nil)
        }
    }
    
    
    open func getScratchPercent() -> Double {
        return scratchView.getAlphaPixelPercent()
    }
    
    public init(frame: CGRect, Coupon: String, MaskImage: String, ScratchWidth: CGFloat) {
        super.init(frame: frame)
        coupponPath = Coupon
        maskPath = MaskImage
        uiScratchWidth = ScratchWidth
        self.interrupted = false
        self.Init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.InitXib()
    }
    
    fileprivate func Init() {
        maskImage = UIImageView(image: UIImage(named: maskPath))//UIImageView(image: processPixels(in: UIImage(named: maskPath)!))
        scratchView = ScratchView(frame: self.frame, CouponImage: coupponPath, ScratchWidth: uiScratchWidth)
        
        maskImage.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        scratchView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        scratchView.delegate = self
        self.addSubview(maskImage)
        self.addSubview(scratchView)
        self.bringSubview(toFront: scratchView)
        
    }
    
    internal func began(_ view: ScratchView) {
        if self.delegate != nil {
            guard self.delegate.scratchBegan != nil else {
                return
            }
            if view.position.x >= 0 && view.position.x <= view.frame.width && view.position.y >= 0 && view.position.y <= view.frame.height  {
                scratchPosition = view.position
            }
            self.delegate.scratchBegan!(self)
        }
    }
    
    internal func moved(_ view: ScratchView) {
        if self.delegate != nil {
            guard self.delegate.scratchMoved != nil else {
                return
            }
            if view.position.x >= 0 && view.position.x <= view.frame.width && view.position.y >= 0 && view.position.y <= view.frame.height  {
                scratchPosition = view.position
            }
            self.delegate.scratchMoved!(self)
        }
    }
    
    internal func ended(_ view: ScratchView) {
        if self.delegate != nil {
            guard self.delegate.scratchEnded != nil else {
                return
            }
            if view.position.x >= 0 && view.position.x <= view.frame.width && view.position.y >= 0 && view.position.y <= view.frame.height  {
                scratchPosition = view.position
            }
            self.delegate.scratchEnded!(self)
        }
    }
    
    fileprivate func InitXib() {
        
    }
}
