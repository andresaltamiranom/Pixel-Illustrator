//
//  Creates.swift
//  Pixel Artist
//
//  Created by Andres Altamirano on 6/6/18.
//  Copyright © 2018 AndresAltamirano. All rights reserved.
//

import Foundation
import UIKit

extension ViewController {
    func createBackground() {
        let topFrame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height * 0.075)
        let bottomFrameTop = CGRect(x: 0, y: bounds.height * 0.85, width: bounds.width, height: bounds.height * 0.075)
        let bottomHeight = bottomFrameTop.height + 2
        let bottomFrameBottom = CGRect(x: bottomHeight * 2 - 1, y: bottomFrameTop.maxY - 1, width: bounds.width - bottomHeight * 2 + 2, height: bottomHeight)
        let toolsFrame = CGRect(x: 0, y: bottomFrameTop.maxY - 1, width: bottomHeight, height: bottomHeight)
        let gridFrame = CGRect(x: bottomHeight, y: bottomFrameTop.maxY - 1, width: bottomHeight, height: bottomHeight)
        let drawingFrame = CGRect(x: 0, y: topFrame.maxY, width: bounds.width, height: bottomFrameTop.minY - topFrame.maxY)
        
        topFrameView = UIView(frame: topFrame)
        let topLayer = CAShapeLayer()
        topLayer.path = CGPath(rect: topFrame, transform: nil)
        topLayer.fillColor = UIColor(hex: 0x3e76d1).cgColor
        topFrameView.layer.addSublayer(topLayer)
        
        bottomFrameTopView = UIView(frame: bottomFrameTop)
        let bottomTopLayer = CAShapeLayer()
        bottomTopLayer.path = CGPath(rect: CGRect(x: 0, y: 0, width: bottomFrameTop.width, height: bottomFrameTop.height), transform: nil)
        bottomTopLayer.fillColor = UIColor(hex: 0x2c5599).cgColor
        bottomFrameTopView.layer.insertSublayer(bottomTopLayer, at: 0)
        
        bottomFrameBottomView = UIView(frame: bottomFrameBottom)
        let bottomBottomLayer = CAShapeLayer()
        bottomBottomLayer.path = CGPath(rect: CGRect(x: 0, y: 0, width: bottomFrameBottom.width, height: bottomFrameBottom.height), transform: nil)
        bottomBottomLayer.fillColor = UIColor(hex: 0x3e76d1).cgColor
        bottomFrameBottomView.layer.addSublayer(bottomBottomLayer)
        
        toolsFrameView = UIView(frame: toolsFrame)
        let toolsLayer = CAShapeLayer()
        toolsLayer.path = CGPath(rect: CGRect(x: 0, y: 0, width: toolsFrame.width, height: toolsFrame.height), transform: nil)
        toolsLayer.fillColor = UIColor(hex: 0x2c5599).cgColor
        toolsFrameView.layer.addSublayer(toolsLayer)
        
        gridFrameView = UIView(frame: gridFrame)
        let gridLayer = CAShapeLayer()
        gridLayer.path = CGPath(rect: CGRect(x: 0, y: 0, width: gridFrame.width, height: gridFrame.height), transform: nil)
        gridLayer.fillColor = UIColor(hex: 0x3362af).cgColor
        gridFrameView.layer.addSublayer(gridLayer)
        
        drawView = DrawView(frame: self.view.frame)
        drawView.visibleFrame = drawingFrame
        drawView.delegate = self
        let lastDrawing = UserDefaults.standard.object(forKey: "lastDrawing") as! Data
        if !lastDrawing.isEmpty { drawView.setBackgroundImage(UIImage(data: lastDrawing, scale: UIScreen.main.scale)!) }
        
        self.view.insertSubview(topFrameView,           at: 5)
        self.view.insertSubview(toolsFrameView,         at: 4)
        self.view.insertSubview(gridFrameView,          at: 3)
        self.view.insertSubview(bottomFrameBottomView,  at: 2)
        self.view.insertSubview(bottomFrameTopView,     at: 1)
        self.view.insertSubview(drawView,               at: 0)
        
        selectedToolSize = CGSize(width: bottomFrameTopView.bounds.height * 0.85, height: bottomFrameTopView.bounds.height * 0.85)
        notSelectedToolSize = CGSize(width: selectedToolSize.width * 0.7, height: selectedToolSize.height * 0.7)
    }
    
    func createTools() {
        createBrush()
        createEraser()
        createBucket()
        createEyedropper()
        createBrushSlider()
        createButtons()
        createColorPicker()
    }
    
    func createBrush() {
        brushButton = UIButton(type: UIButtonType.custom)
        brushButton.frame = CGRect(x: bottomFrameTopView.bounds.height * 0.1, y: bottomFrameTopView.bounds.height * 0.075, width: selectedToolSize.width, height: selectedToolSize.height)
        brushButton.setImage(brushImageBig, for: .normal)
        brushButton.addTarget(self, action: #selector(selectTool), for: .touchUpInside)
        brushButton.tag = Tool.brush.rawValue
        bottomFrameTopView.addSubview(brushButton)
    }
    
    func createEraser() {
        eraserButton = UIButton(type: .custom)
        eraserButton.frame = CGRect(x: brushButton.x + brushButton.width + bounds.width * 0.01, y: brushButton.y, width: selectedToolSize.width, height: selectedToolSize.height)
        eraserButton.setImage(eraserImageSmall, for: .normal)
        eraserButton.addTarget(self, action: #selector(selectTool), for: .touchUpInside)
        eraserButton.tag = Tool.eraser.rawValue
        bottomFrameTopView.addSubview(eraserButton)
    }
    
    func createBucket() {
        bucketButton = UIButton(type: UIButtonType.custom)
        bucketButton.frame = CGRect(x: eraserButton.x + eraserButton.width + bounds.width * 0.01, y: brushButton.y, width: selectedToolSize.width, height: selectedToolSize.height)
        bucketButton.setImage(bucketImageSmall, for: .normal)
        bucketButton.addTarget(self, action: #selector(selectTool), for: .touchUpInside)
        bucketButton.tag = Tool.bucket.rawValue
        bottomFrameTopView.addSubview(bucketButton)
    }
    
    func createEyedropper() {
        eyedropperButton = UIButton(type: .custom)
        eyedropperButton.frame = CGRect(x: bucketButton.x + bucketButton.width + bounds.width * 0.01, y: brushButton.y, width: selectedToolSize.width, height: selectedToolSize.height)
        eyedropperButton.setImage(eyedropperImageSmall, for: .normal)
        eyedropperButton.addTarget(self, action: #selector(selectTool), for: .touchUpInside)
        eyedropperButton.tag = Tool.eyedropper.rawValue
        bottomFrameTopView.addSubview(eyedropperButton)
    }
    
    func createGrid() {
        gridIsShown = false
        grid = Grid(frame: drawView.visibleFrame)
        grid.backgroundColor = UIColor.clear
        grid.isUserInteractionEnabled = false
        
        self.view.insertSubview(grid, aboveSubview: drawView)
    }
    
    func createButtons() {
        let distanceBetweenButtons = topFrameView.frame.width * 0.1725
        undoButton = UIButton(type: .custom)
        undoButton.frame = CGRect(x: topFrameView.frame.width * 0.025, y: topFrameView.frame.height * (UIDevice.isiPhoneXModel ? 0.48 : 0.125), width: topFrameView.frame.height * (UIDevice.isiPhoneXModel ? 0.5 : 0.75), height: topFrameView.frame.height * (UIDevice.isiPhoneXModel ? 0.5 : 0.75))
        undoButton.setImage(UIImage(named: "undo"), for: .normal)
        undoButton.addTarget(self, action: #selector(undo), for: .touchUpInside)
        undoButton.isEnabled = false
        topFrameView.addSubview(undoButton)
        
        redoButton = UIButton(type: .custom)
        redoButton.frame = CGRect(x: undoButton.x + distanceBetweenButtons, y: undoButton.y, width: undoButton.width, height: undoButton.height)
        redoButton.setImage(UIImage(named: "redo"), for: .normal)
        redoButton.addTarget(self, action: #selector(redo), for: .touchUpInside)
        redoButton.isEnabled = false
        topFrameView.addSubview(redoButton)
        
        deleteButton = UIButton(type: .custom)
        deleteButton.frame = CGRect(x: redoButton.x + distanceBetweenButtons, y: undoButton.y, width: topFrameView.frame.height * (UIDevice.isiPhoneXModel ? 0.46 : 0.7), height: undoButton.height)
        deleteButton.setImage(UIImage(named: "delete"), for: .normal)
        deleteButton.addTarget(self, action: #selector(showDeleteAlert), for: .touchUpInside)
        topFrameView.addSubview(deleteButton)
        
        imageButton = UIButton(type: .custom)
        imageButton.frame = CGRect(x: deleteButton.x + distanceBetweenButtons, y: undoButton.y, width: topFrameView.frame.height * (UIDevice.isiPhoneXModel ? 0.56 : 0.85), height: undoButton.height)
        imageButton.setImage(UIImage(named: "camera"), for: .normal)
        imageButton.addTarget(self, action: #selector(showImageAlert), for: .touchUpInside)
        topFrameView.addSubview(imageButton)
        
        saveButton = UIButton(type: .custom)
        saveButton.frame = CGRect(x: imageButton.x + distanceBetweenButtons, y: undoButton.y, width: deleteButton.width, height: undoButton.height)
        saveButton.setImage(UIImage(named: "download"), for: .normal)
        saveButton.addTarget(self, action: #selector(saveImageToDevice), for: .touchUpInside)
        topFrameView.addSubview(saveButton)
        
        shareButton = UIButton(type: .custom)
        shareButton.frame = CGRect(x: saveButton.x + distanceBetweenButtons, y: undoButton.y, width: deleteButton.width, height: undoButton.height)
        shareButton.setImage(UIImage(named: "share"), for: .normal)
        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)
        topFrameView.addSubview(shareButton)
        
        var pixelateButtonWidth = brushButton.width * 3.2
        var pixelateButtonHeight = brushButton.height
        var pixelateButtonX = topFrameView.frame.width * 0.5 - pixelateButtonWidth * 0.5 - toolsFrameView.frame.width * 2
        if UIDevice.isiPhoneXModel {
            pixelateButtonWidth *= 0.75
            pixelateButtonHeight *= 0.75
            pixelateButtonX += 30
        }
        pixelateButton = UIButton(type: .custom)
        pixelateButton.frame = CGRect(x: pixelateButtonX, y: bottomFrameBottomView.bounds.height * 0.5 - brushButton.height * 0.5, width: pixelateButtonWidth, height: pixelateButtonHeight)
        
        pixelateButton.setImage(UIImage(named: "pixelate_button"), for: .normal)
        pixelateButton.addTarget(self, action: #selector(changePixelation), for: .touchUpInside)
        bottomFrameBottomView.addSubview(pixelateButton)
        
        toolsButton = UIButton(type: .custom)
        toolsButton.frame = CGRect(x: brushButton.x, y: bottomFrameBottomView.bounds.height * 0.5 - brushButton.height * 0.5, width: brushButton.width, height: brushButton.height)
        toolsButton.setImage(paletteImageBig, for: .normal)
        toolsButton.addTarget(self, action: #selector(selectOption(sender:)), for: .touchUpInside)
        toolsButton.tag = SelectOptions.tools.rawValue
        toolsFrameView.addSubview(toolsButton)
        
        gridButton = UIButton(type: .custom)
        gridButton.frame = CGRect(x: brushButton.x, y: toolsButton.y, width: toolsButton.width, height: toolsButton.height)
        gridButton.setImage(rulerImageSmall, for: .normal)
        gridButton.addTarget(self, action: #selector(selectOption(sender:)), for: .touchUpInside)
        gridButton.tag = SelectOptions.grid.rawValue
        gridFrameView.addSubview(gridButton)
        
        showGrid = UISwitch()
        showGrid.frame = CGRect(x: brushButton.x, y: bottomFrameTopView.frame.height * 0.5 - showGrid.height * 0.5, width: 0, height: 0)
        showGrid.addTarget(self, action: #selector(toggleGrid), for: .valueChanged)
        showGrid.isHidden = true
        showGrid.isOn = false
        bottomFrameTopView.addSubview(showGrid)
        
        let gridSliderX = showGrid.x + showGrid.frame.width + bounds.width * 0.03
        gridSlider = BrushSizeSlider(frame: CGRect(x: gridSliderX, y: lineWidthSlider.y, width: bottomFrameTopView.bounds.width * 0.95 - gridSliderX, height: 10))
        gridSlider.minimumValue = 0
        gridSlider.maximumValue = Float(grid.grids.count - 1)
        gridSlider.setValue(Float(grid.currentIndex), animated: false)
        gridSlider.isContinuous = true
        gridSlider.tintColor = UIColor.white
        gridSlider.addTarget(self, action: #selector(gridSliderValueDidChange(sender:)), for: .valueChanged)
        gridSlider.isHidden = true
        bottomFrameTopView.addSubview(gridSlider)
    }
    
    func createBrushSlider() {
        let brushSize = UserDefaults.standard.float(forKey: "brushSize")
        let lineWidthSliderX = eyedropperButton.x + eyedropperButton.width + bounds.width * 0.03
        lineWidthSlider = BrushSizeSlider(frame: CGRect(x: lineWidthSliderX, y: brushButton.y + brushButton.height * 0.5 - 5, width: bottomFrameTopView.bounds.width * 0.9 - lineWidthSliderX, height: /*bottomFrameTopView.bounds.height * 0.2*/10))
        lineWidthSlider.minimumValue = 3.0
        lineWidthSlider.maximumValue = 30.0
        lineWidthSlider.setValue(brushSize, animated: false)
        lineWidthSlider.isContinuous = true
        lineWidthSlider.tintColor = UIColor.white
        lineWidthSlider.addTarget(self, action: #selector(lineWidthSliderValueDidChange(sender:)), for: .valueChanged)
        drawView.brush.width = CGFloat(brushSize)
        bottomFrameTopView.addSubview(lineWidthSlider)
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: lineWidthSlider.x + lineWidthSlider.width + bounds.width * 0.05, y: lineWidthSlider.y + lineWidthSlider.height / 2.0), radius: CGFloat(drawView.brush.width / 2.0), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        
        shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = UIColor.white.cgColor
        
        bottomFrameTopView.layer.addSublayer(shapeLayer)
    }
    
    private func createColorPicker() {
        let colorData = UserDefaults.standard.object(forKey: "brushColor") as! Data
        let color = colorData.isEmpty ? UIColor.black : NSKeyedUnarchiver.unarchiveObject(with: colorData) as? UIColor
        selectedColor = UIButton(type: .custom)
        selectedColor.frame = CGRect(x: bottomFrameBottomView.frame.width * 0.8 - 10, y: toolsButton.y, width: brushButton.width * 0.93, height: brushButton.height * 0.93)
        selectedColor.layer.cornerRadius = 0.5 * selectedColor.bounds.size.width
        selectedColor.clipsToBounds = true
        selectedColor.backgroundColor = color
        selectedColor.layer.borderWidth = 2
        selectedColor.layer.borderColor = UIColor.white.cgColor
        selectedColor.addTarget(self, action: #selector(self.pressColorPicker(_:)), for: .touchUpInside)
        bottomFrameBottomView.addSubview(selectedColor)
        drawView.brush.color = color!
        
        colorPicker = HSBColorPicker(frame: drawView.visibleFrame)
        colorPicker.delegate = self
        self.view.addSubview(colorPicker)
        self.view.sendSubview(toBack: colorPicker)
    }
}
