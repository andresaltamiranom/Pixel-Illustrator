//
//  Grid.swift
//  Pixel Artist
//
//  Created by Andres Altamirano on 6/7/18.
//  Copyright © 2018 AndresAltamirano. All rights reserved.
//

import Foundation
import UIKit

class Grid: UIView {
    let minGridColumns = 8
    let maxGridColumns = 192
    
    // There are currently 30 different grids
    
    var currentIndex: Int = 0
    var grids: [(grid: CAShapeLayer, pixelSize: CGFloat)] = []
    var pixelSize: CGFloat!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createGrids()
        
        currentIndex = UserDefaults.standard.integer(forKey: "gridIndex")
        if currentIndex == -1 {
            currentIndex = grids.count - 1
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func createGrids() {
        var columns = minGridColumns
        
        repeat {
            let pixelSize = round(bounds.width / CGFloat(columns))
            
            let rows = Int(ceil(bounds.height / pixelSize))
            let actualColumns = Int(ceil(bounds.width / pixelSize))
            let path = UIBezierPath()
            path.lineWidth = 1.0
            
            for i in 1...actualColumns {
                let start = CGPoint(x: CGFloat(i) * pixelSize, y: 0)
                let end = CGPoint(x: CGFloat(i) * pixelSize, y: bounds.height)
                path.move(to: start)
                path.addLine(to: end)
            }
            
            for i in 1...rows {
                let start = CGPoint(x: 0, y: CGFloat(i) * pixelSize)
                let end = CGPoint(x: bounds.width, y: CGFloat(i) * pixelSize)
                path.move(to: start)
                path.addLine(to: end)
            }
            
            path.close()
            
            let gridLayer = CAShapeLayer()
            gridLayer.lineWidth = 1.0;
            gridLayer.path = path.cgPath
            gridLayer.strokeColor = UIColor(hex: 0xb2b3b7).cgColor
            
            grids.append((gridLayer, pixelSize))
            
            while round(bounds.width / CGFloat(columns)) == pixelSize && columns < maxGridColumns {
                columns += 1
            }
        } while columns != maxGridColumns
    }
    
    func redrawGrid() {
        self.layer.addSublayer(grids[currentIndex].grid)
    }
    
    func removeGrid() {
        grids[currentIndex].grid.removeFromSuperlayer()
    }
    
    func setGrid(to gridIndex: Int, shouldShow: Bool) {
        guard gridIndex != currentIndex else { return }
        grids[currentIndex].grid.removeFromSuperlayer()
        if shouldShow {
            self.layer.addSublayer(grids[gridIndex].grid)
        }
        currentIndex = gridIndex
        UserDefaults.standard.set(gridIndex, forKey: "gridIndex")
    }
}
