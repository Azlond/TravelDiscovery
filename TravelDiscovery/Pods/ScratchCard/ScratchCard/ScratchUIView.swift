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
    open var interrupted: Bool!
    var couponImage: UIImageView!
    var coupon: String!
    open var scratchPosition: CGPoint!
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.Init()
    }
    
    open func getScratchPercent() -> Double {
        return scratchView.getAlphaPixelPercent()
    }
    
    open func autoScratch() {
        let viewSize = couponImage.bounds
        let screenWidth = Int(viewSize.width)
        let screenHeight = Int(viewSize.height)

        var xyArray = [(Int,Int)]()
        
        let lineWidth: CGFloat!
        lineWidth = 40
        
        scratchView.overrideLineCap(lineWidth: lineWidth)
        
        for i in 1 ... 2 {
            for x in 0 ..< screenHeight / Int(lineWidth) {
                for y in 0 ..< screenWidth / Int(lineWidth) {
                    xyArray.append((x * Int(lineWidth), y * Int(lineWidth) * i))
                }
            }
        }
        
        DispatchQueue.global(qos: .background).async {
            while (xyArray.count > 0 && self.getScratchPercent() < 1) {
                /*If interrupted, stop scratching*/
                if self.interrupted {
                    return
                }
                /*Get random array index*/
                let randomXY = Int(arc4random_uniform(UInt32(xyArray.count)))
                
                let startPoint = CGPoint(x: xyArray[randomXY].0, y: xyArray[randomXY].1)
                let endPoint = startPoint
                
                /*send render command to AsyncQueue*/
                DispatchQueue.main.async {
                    self.scratchView.renderLineFromPoint(startPoint, end: endPoint)
                }
                /*remove chosen index from array*/
                xyArray.remove(at: randomXY)
                
                usleep(500)
            }
        }
    }
    
    public init(frame: CGRect, Coupon: String, MaskImage: String, ScratchWidth: CGFloat) {
        super.init(frame: frame)
        coupon = Coupon
        maskImage = MaskImage
        uiScratchWidth = ScratchWidth
        self.Init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.InitXib()
    }
    
    fileprivate func Init() {
        couponImage = UIImageView(image: UIImage(named: coupon))
        scratchView = ScratchView(frame: self.frame, MaskImage: maskImage, ScratchWidth: uiScratchWidth)
        
        self.interrupted = false
        couponImage.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        scratchView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        scratchView.delegate = self
        self.addSubview(couponImage)
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
