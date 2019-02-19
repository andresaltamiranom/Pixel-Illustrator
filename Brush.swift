//
//  Brush.swift
//  Pixel Artist
//
//  Created by Andres Altamirano on 6/6/18.
//  Copyright © 2018 AndresAltamirano. All rights reserved.
//

import Foundation
import UIKit

public class Brush {
    
    public var color: UIColor
    /// Original brush width set when initializing the brush. Not affected by updating the brush width. Used to determine adjusted width
    private var originalWidth: CGFloat
    public var width: CGFloat
    public var opacity: CGFloat
    
    public var adjustedWidthFactor: CGFloat = 1
    
    public init(color: UIColor = UIColor(red:0.0, green:0.0, blue:0.0, alpha:1.0), width: CGFloat = 3, opacity: CGFloat = 1, adjustedWidthFactor: CGFloat = 1) {
        self.color = color
        self.originalWidth = width
        self.width = width
        self.opacity = opacity
        self.adjustedWidthFactor = adjustedWidthFactor
    }
    
    public func adjustedWidth(for touch: UITouch) -> CGFloat {
        if touch.type == .stylus {
            return (originalWidth * (1 - adjustedWidthFactor / 10 * 2)) + (adjustedWidthFactor / touch.altitudeAngle)
        }
        return originalWidth
    }
    
    public func adjustWidth(for touch: UITouch) {
        width = adjustedWidth(for: touch)
    }
    
    public static var `default`: Brush {
        return Brush(color: UIColor(red:0.0, green:0.0, blue:0.0, alpha:1.0), width: 3, opacity: 1)
    }
    
    public static var eraser: Brush {
        return Brush(color: UIColor(red:1.0, green:1.0, blue:1.0, alpha:1.0), width: 12, opacity: 1, adjustedWidthFactor: 5)
    }
    
    public static var selection: Brush {
        return Brush(color: .clear, width: 1, opacity: 1)
    }
}

extension Brush: Equatable, Comparable {
    public static func ==(lhs: Brush, rhs: Brush) -> Bool {
        return (
            lhs.color == rhs.color &&
                lhs.originalWidth == rhs.originalWidth &&
                lhs.opacity == rhs.opacity
        )
    }
    
    public static func <(lhs: Brush, rhs: Brush) -> Bool {
        return (
            lhs.width < rhs.width
        )
    }
}
