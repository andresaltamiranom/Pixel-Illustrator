//
//  BrushSizeSlider.swift
//  Pixel Artist
//
//  Created by Andres Altamirano on 8/15/18.
//  Copyright © 2018 AndresAltamirano. All rights reserved.
//

import Foundation
import UIKit

public class BrushSizeSlider: UISlider {
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func trackRect(forBounds bounds: CGRect) -> CGRect {
        var result = super.trackRect(forBounds: bounds)
        result.size.height = 10 // added height for desired effect
        return result
    }
}
