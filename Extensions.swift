//
//  Extensions.swift
//  Pixel Artist
//
//  Created by Andres Altamirano on 6/6/18.
//  Copyright © 2018 AndresAltamirano. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func toImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0)
        
        defer { UIGraphicsEndImageContext() }
        let context = UIGraphicsGetCurrentContext()!
        self.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        return image
    }
    
}

extension UIImage {
    func padTo(frame: CGRect, top: CGFloat, right: CGFloat, bottom: CGFloat, left: CGFloat, _ paddingColor: UIColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)) -> UIImage {
        let view = UIView(frame: frame)
        view.backgroundColor = paddingColor
        let imgv = UIImageView(frame: CGRect(x: left, y: top, width: frame.width - left - right, height: frame.height - top - bottom))
        imgv.backgroundColor = paddingColor
        imgv.contentMode = .scaleAspectFit
        imgv.image = self
        view.addSubview(imgv)
        return view.toImage()
    }
    
    func scaleTo(targetSize: CGSize) -> UIImage {
        let size = self.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated and this what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        return newImage!
    }
    
    func getDataBuffer() -> (CGContext, Int, Int, UnsafeMutablePointer<RGBA32>) {
        let inputCGImage = self.cgImage!
        
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = inputCGImage.width
        let height           = inputCGImage.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapInfo       = RGBA32.bitmapInfo
        
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)!
        context.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let buffer = context.data!
        
        let pixelBuffer = buffer.bindMemory(to: RGBA32.self, capacity: width * height)
        
        return (context, width, height, pixelBuffer)
    }
}

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let blue = CGFloat((hex & 0xFF)) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
    
    convenience init(_ rgba: RGBA32) {
         self.init(red: CGFloat(rgba.redComponent) / 255.0, green: CGFloat(rgba.greenComponent) / 255.0, blue: CGFloat(rgba.blueComponent) / 255.0, alpha: CGFloat(rgba.alphaComponent) / 255.0)
    }
    
    func rgba() -> (red: UInt, green: UInt, blue: UInt, alpha: UInt)? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            let iRed = UInt(fRed * 255.0)
            let iGreen = UInt(fGreen * 255.0)
            let iBlue = UInt(fBlue * 255.0)
            let iAlpha = UInt(fAlpha * 255.0)
            
            // (Bits 24-31 are alpha, 16-23 are red, 8-15 are green, 0-7 are blue).
            let rgba = (red: iRed, green: iGreen, blue: iBlue, alpha: iAlpha)
            return rgba
        } else {
            // Could not extract RGBA components
            return nil
        }
    }
    
    func equals(_ color: UIColor) -> Bool {
        let color1 = self.rgba()!
        let color2 = color.rgba()!
        
        return abs(Int(color1.red) - Int(color2.red)) <= 1 &&
               abs(Int(color1.blue) - Int(color2.blue)) <= 1 &&
               abs(Int(color1.green) - Int(color2.green)) <= 1
    }
}

extension UIControl {
    var x: CGFloat { return self.frame.origin.x }
    var y: CGFloat { return self.frame.origin.y }
    var position: CGPoint { return self.frame.origin }
    var width: CGFloat { return self.frame.width }
    var height: CGFloat { return self.frame.height }
    
    var rightmostPoint: CGFloat { return self.frame.origin.x + self.width }
    var leftmostPoint:  CGFloat { return self.frame.origin.x }
    var topPoint:       CGFloat { return self.frame.origin.y + self.height }
    var bottomPoint:    CGFloat { return self.frame.origin.y }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, nil otherwise.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

public extension UIDevice {
    
    static let isiPhoneXModel: Bool = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        func mapToDevice(identifier: String) -> Bool { // swiftlint:disable:this cyclomatic_complexity
            #if os(iOS)
            switch identifier {
            case "iPhone10,3", "iPhone10,6":                return true // "iPhone X"
            case "iPhone11,2":                              return true // "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return true // "iPhone XS Max"
            case "iPhone11,8":                              return true // "iPhone XR"
            case "i386", "x86_64":                          return mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS")
            default:                                        return false
            }
            #elseif os(tvOS)
            return false
            #endif
        }
        
        return mapToDevice(identifier: identifier)
    }()
    
}
