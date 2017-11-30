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

        let stepSize = 6
        
        DispatchQueue.global(qos: .background).async {
            for heightIndex in 0 ..< screenHeight / stepSize {
                if (heightIndex % 2 != 0) {
                    for widthIndex in  (0 ..< screenWidth / stepSize).reversed() {
                        if self.interrupted {
                            return
                        }
                        let startPoint = CGPoint(x: widthIndex*stepSize, y: heightIndex)
                        let endPoint = CGPoint(x:widthIndex*stepSize+stepSize, y:heightIndex*stepSize+stepSize)
                        DispatchQueue.main.async {
                            self.scratchView.renderLineFromPoint(startPoint, end: endPoint)
                        }
                        usleep(25)                    }
                } else {
                    for widthIndex in 0 ..< screenWidth / stepSize {
                        if self.interrupted {
                            return
                        }
                        let startPoint = CGPoint(x: widthIndex*stepSize, y: heightIndex)
                        let endPoint = CGPoint(x:widthIndex*stepSize+stepSize, y:heightIndex*stepSize+stepSize)
                        DispatchQueue.main.async {
                            self.scratchView.renderLineFromPoint(startPoint, end: endPoint)
                        }
                        usleep(25)                    }
                }
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
