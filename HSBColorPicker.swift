//
//  HSBColorPicker.swift
//  Pixel Artist
//
//  Created by Andres Altamirano on 6/6/18.
//  Copyright © 2018 AndresAltamirano. All rights reserved.
//

import Foundation
import UIKit

internal protocol HSBColorPickerDelegate : NSObjectProtocol {
    func HSBColorColorPickerSelected(color: UIColor)
    func HSBColorPickerPreview(color: UIColor)
}

@IBDesignable
class HSBColorPicker : UIView {
    
    weak internal var delegate: HSBColorPickerDelegate?
    let saturationExponentTop: Float = 0.75
    let saturationExponentBottom: Float = 0.3
    var lastColorSelected: UIColor!
    var elementSize: CGFloat = 1.0
    
    private func initialize() {
        self.clipsToBounds = true
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.selectedColor(gesture:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        self.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.selectedColor(gesture:)))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        self.addGestureRecognizer(tap)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let rectHeight: CGFloat = rect.height
        let rectWidth: CGFloat = rect.width
        for y in 0...Int(rectHeight) {
            var saturation = CGFloat(y) < rectHeight / 2.0 ? CGFloat(2 * y) / rectHeight : 2.0 * CGFloat(rectHeight - CGFloat(y)) / rectHeight
            saturation = CGFloat(powf(Float(saturation), CGFloat(y) < rectHeight / 2.0 ? saturationExponentTop : saturationExponentBottom))
            let brightness = CGFloat(y) < rect.height / 2.0 ? CGFloat(1.0) : 2.0 * CGFloat(rect.height - CGFloat(y)) / rect.height
            for x in 0...Int(rectWidth) {
                let hue = CGFloat(x) / rectWidth
                let color = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
                context!.setFillColor(color.cgColor)
                context!.fill(CGRect(x:x, y:y, width: 1, height: 1))
            }
        }
    }
    
    func getColorAt(point: CGPoint) -> UIColor {
        if point.x < 0 || point.y < 0 || point.x >= bounds.width || point.y >= bounds.height { return lastColorSelected }
        
        let roundedPoint = CGPoint(x: elementSize * CGFloat(Int(point.x / elementSize)),
                                   y: elementSize * CGFloat(Int(point.y / elementSize)))
        var saturation = roundedPoint.y < self.bounds.height / 2.0 ? CGFloat(2 * roundedPoint.y) / self.bounds.height
            : 2.0 * CGFloat(self.bounds.height - roundedPoint.y) / self.bounds.height
        saturation = CGFloat(powf(Float(saturation), roundedPoint.y < self.bounds.height / 2.0 ? saturationExponentTop : saturationExponentBottom))
        let brightness = roundedPoint.y < self.bounds.height / 2.0 ? CGFloat(1.0) : 2.0 * CGFloat(self.bounds.height - roundedPoint.y) / self.bounds.height
        let hue = roundedPoint.x / self.bounds.width
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
    }

    @objc func selectedColor(gesture: UIGestureRecognizer) {
        let point = gesture.location(in: self)
        
        if point.x < 0 || point.x >= bounds.width || point.y < 0 || point.y >=  bounds.height {
            // this cancels the gesture
            gesture.isEnabled = false
            gesture.isEnabled = true
        }
        
        let color = getColorAt(point: point)
        lastColorSelected = color
        if gesture.state == .cancelled || gesture.state == .ended {
            delegate?.HSBColorColorPickerSelected(color: color)
        } else {
            delegate?.HSBColorPickerPreview(color: color)
        }
    }
}
