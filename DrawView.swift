//
//  DrawView.swift
//  Pixel Artist
//
//  Created by Andres Altamirano on 6/6/18.
//  Copyright © 2018 AndresAltamirano. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Public Protocol Declarations
/// DrawView Delegate
public protocol DrawViewDelegate: class {
    
    /**
     DrawViewDelegate called when a touch gesture should begin on the DrawView using given touch type
     
     - Parameter view: DrawView where touches occured.
     - Parameter touchType: Type of touch occuring.
     */
    func Draw(shouldBeginDrawingIn drawingView: DrawView, using touch: UITouch) -> Bool
    /**
     DrawViewDelegate called when a touch gesture begins on the DrawView.
     
     - Parameter view: DrawView where touches occured.
     */
    func Draw(didBeginDrawingIn drawingView: DrawView, using touch: UITouch)
    
    /**
     DrawViewDelegate called when touch gestures continue on the DrawView.
     
     - Parameter view: DrawView where touches occured.
     */
    func Draw(isDrawingIn drawingView: DrawView, using touch: UITouch)
    
    /**
     DrawViewDelegate called when touches gestures finish on the DrawView.
     
     - Parameter view: DrawView where touches occured.
     */
    func Draw(didFinishDrawingIn drawingView: DrawView, using touch: UITouch)
    
    /**
     DrawViewDelegate called when there is an issue registering touch gestures on the  DrawView.
     
     - Parameter view: DrawView where touches occured.
     */
    func Draw(didCancelDrawingIn drawingView: DrawView, using touch: UITouch)
}

/// UIView Subclass where touch gestures are translated into Core Graphics drawing
open class DrawView: UIView {
    
    /// Current brush being used for drawing
    public var brush: Brush = Brush.default
    
    /// Sets whether touch gestures should be registered as drawing strokes on the current canvas
    public var isEnabled: Bool = true
    
    /// Public DrawView delegate
    public weak var delegate: DrawViewDelegate?
    
    private var pathArray: [Line]  = []
    private var originalDrawing = UIImage()
    private var pixelating: Bool = false
    private var currentPoint: CGPoint = .zero
    private var previousPoint: CGPoint = .zero
    private var previousPreviousPoint: CGPoint = .zero
    private var undoStack: [UIImage] = []
    private var redoStack: [UIImage] = []
    public var visibleFrame: CGRect!
    
    public struct Line {
        public var path: CGMutablePath
        public var brush: Brush
        
        init(path: CGMutablePath, brush: Brush) {
            self.path = path
            self.brush = brush
        }
    }
    
    /// Public init(frame:) implementation
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(red:1.0, green:1.0, blue:1.0, alpha:1.0) // white - don't use UIColor.white()
    }
    
    /// Public init(coder:) implementation
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Overriding draw(rect:) to stroke paths
    override open func draw(_ rect: CGRect) {
        guard let context: CGContext = UIGraphicsGetCurrentContext() else { return }
        
        context.setLineCap(.round)
        
        let pathArraySize = pathArray.count
        for i in 0..<pathArraySize {
            context.setLineWidth(pathArray[i].brush.width)
            context.setStrokeColor(pathArray[i].brush.color.cgColor)
            context.addPath(pathArray[i].path)
            context.beginTransparencyLayer(auxiliaryInfo: nil)
            context.strokePath()
            context.endTransparencyLayer()
        }
    }
    
    /// touchesBegan implementation to capture strokes
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard delegate?.Draw(shouldBeginDrawingIn: self, using: touch) ?? true else { return }
        
        guard isEnabled else { return }
        
        undoStack.append(self.toImage())
        
        delegate?.Draw(didBeginDrawingIn: self, using: touch)
        
        redoStack = []
        
        setTouchPoints(touch, view: self)
        let newLine = Line(path: CGMutablePath(), brush: Brush(color: brush.color, width: brush.width))
        newLine.path.addPath(createNewPath())
        pathArray.append(newLine)
    }
    
    /// touchesMoved implementation to capture strokes
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEnabled else { return }
        guard !pixelating else { return }
        guard let touch = touches.first else { return }
        guard delegate?.Draw(shouldBeginDrawingIn: self, using: touch) ?? true else { return }
        delegate?.Draw(isDrawingIn: self, using: touch)
        
        updateTouchPoints(for: touch, in: self)
        let newLine = createNewPath()
        if let currentPath = pathArray.last {
            currentPath.path.addPath(newLine)
        }
    }
    
    /// touchesEnded implementation to capture strokes
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEnabled else { return }
        guard !pixelating else { return }
        guard let touch = touches.first else { return }
        
        delegate?.Draw(didFinishDrawingIn: self, using: touch)
        UserDefaults.standard.set(UIImagePNGRepresentation(self.toImage()), forKey: "lastDrawing")
    }
    
    /// touchesCancelled implementation
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEnabled else { return }
        guard !pixelating else { return }
        guard let touch = touches.first else { return }
        delegate?.Draw(didCancelDrawingIn: self, using: touch)
    }
    
    /// Determines whether a last change can be undone
    public var canUndo: Bool {
        return undoStack.count > 0
    }
    
    /// Determines whether an undone change can be redone
    public var canRedo: Bool {
        return redoStack.count > 0
    }
    
    /// Undo the last change, if possible
    public func undo() {
        guard canUndo else { return }
        redoStack.append(self.toImage())
        let newImage = undoStack.removeLast()
        setBackgroundImage(newImage)
        UserDefaults.standard.set(UIImagePNGRepresentation(newImage), forKey: "lastDrawing")
    }
    
    /// Redo the last change, if possible
    public func redo() {
        guard canRedo else { return }
        undoStack.append(self.toImage())
        let newImage = redoStack.removeLast()
        setBackgroundImage(newImage)
        UserDefaults.standard.set(UIImagePNGRepresentation(newImage), forKey: "lastDrawing")
    }
    
    /// Clears all stroked lines on canvas
    public func clear() {
        self.backgroundColor = UIColor(red:1.0, green:1.0, blue:1.0, alpha:1.0) // white - don't use UIColor.white()
        undoStack = []
        redoStack = []
        pathArray = []
        setNeedsDisplay()
        
        UserDefaults.standard.set(Data(), forKey: "lastDrawing")
    }
    
    /// Applies bucket fill starting from the selected touch location
    func fill(_ touch: UITouch) {
        let drawing = self.toImage()
        let (context, width, height, pixelBuffer) = drawing.getDataBuffer()
        let location = touch.location(in: self)
        let x = Int(round(location.x) * drawing.scale)
        let y = Int(round(location.y) * drawing.scale)
        
        let initialIndex = y * width + x
        let paintColor = RGBA32(brush.color)
        let originalColor = pixelBuffer[initialIndex]
        
        guard paintColor != originalColor else { return }
        
        undoStack.append(drawing)
        redoStack = []
        
        let topY = Int(round(visibleFrame.minY) * drawing.scale)
        let lowY = Int(round(visibleFrame.maxY) * drawing.scale)
        let min = topY * width
        let max = lowY * width
        
        // start measuring time
//        let start = DispatchTime.now()
        
        var fillQueue = Queue(size: width * height * Int(ceil(drawing.scale)))
        fillQueue.push(initialIndex)
        
        while !fillQueue.isEmpty {
            let currIndex = fillQueue.pop()!
            if pixelBuffer[currIndex] != originalColor { continue }
            
            // Common implementation
//            pixelBuffer[currIndex] = paintColor
//            if x - 1 >= 0     && pixelBuffer[currIndex - 1]     == originalColor { fillQueue.push(currIndex - 1) }
//            if x + 1 < width  && pixelBuffer[currIndex + 1]     == originalColor { fillQueue.push(currIndex + 1) }
//            if y - 1 >= 0     && pixelBuffer[currIndex - width] == originalColor { fillQueue.push(currIndex - width) }
//            if y + 1 < height && pixelBuffer[currIndex + width] == originalColor { fillQueue.push(currIndex + width) }
            
            // Use this implementation to make 3x3 squares instead of 1x1. Much faster but less precision.
            pixelBuffer[currIndex] = paintColor
            if currIndex - 1         >= min { pixelBuffer[currIndex - 1        ] = paintColor }
            if currIndex + 1         <= max { pixelBuffer[currIndex + 1        ] = paintColor }
            if currIndex     - width >= min { pixelBuffer[currIndex     - width] = paintColor }
            if currIndex     + width <= max { pixelBuffer[currIndex     + width] = paintColor }
            if currIndex - 1 - width >= min { pixelBuffer[currIndex - 1 - width] = paintColor }
            if currIndex + 1 - width >= min { pixelBuffer[currIndex + 1 - width] = paintColor }
            if currIndex - 1 + width <= max { pixelBuffer[currIndex - 1 + width] = paintColor }
            if currIndex + 1 + width <= max { pixelBuffer[currIndex + 1 + width] = paintColor }

            let x = currIndex % width
            let y = currIndex / width
            if x - 3 >= 0      && pixelBuffer[currIndex - 2]         == originalColor { fillQueue.push(currIndex - 3) }
            if x + 3 < width   && pixelBuffer[currIndex + 2]         == originalColor { fillQueue.push(currIndex + 3) }
            if y - 3 >= topY   && pixelBuffer[currIndex - width * 2] == originalColor { fillQueue.push(currIndex - width * 3) }
            if y + 3 <= lowY   && pixelBuffer[currIndex + width * 2] == originalColor { fillQueue.push(currIndex + width * 3) }
        }
        
        // stop measuring time
//        let end = DispatchTime.now()
        
        // print time elapsed
//        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
//        let timeInterval = Double(nanoTime) / 1_000_000_000
//        print("Filling took \(timeInterval) seconds")
        
        let outputCGImage = context.makeImage()!
        let outputImage = UIImage(cgImage: outputCGImage, scale: drawing.scale, orientation: drawing.imageOrientation)
        setBackgroundImage(outputImage)
        delegate?.Draw(didFinishDrawingIn: self, using: touch)
        UserDefaults.standard.set(UIImagePNGRepresentation(outputImage), forKey: "lastDrawing")
    }
    
    /// Pixelates the current drawing on the canvas
    func pixelate(with grid: Grid) {
        guard !pixelating else { return }
        pixelating = true
        
        let drawing = self.toImage()
        let (context, width, _, pixelBuffer) = drawing.getDataBuffer()
        let visibleHeight = Int(visibleFrame.height * drawing.scale)
        let pixelSize = grid.grids[grid.currentIndex].pixelSize
        let squareSize = Int(pixelSize * drawing.scale)
        let numberOfPixelsInSquare = squareSize * squareSize
        
        // save drawing so that we can depixelate later
        originalDrawing = self.toImage()
        
        // start measuring time
//        let start = DispatchTime.now()
        
        let topYPixels = Int(round(visibleFrame.minY) * drawing.scale) // to skip pixels under top menu
        let cols = Int(ceil(visibleFrame.width / pixelSize))
        let rows = Int(ceil(visibleFrame.height / pixelSize))
        for row in 0..<rows {
            let yCol = row * squareSize
            let indexInRow = (topYPixels + row * squareSize) * width
            for col in 0..<cols {
                let xCol = col * squareSize
                let indexToCurrentSquare = indexInRow + col * squareSize
                
                var colors: [UInt32: Int] = [:]
                var squareIndices = [Int](repeating: 0, count: numberOfPixelsInSquare)
                var count = 0
                for i in 0..<squareSize {
                    if yCol + i >= visibleHeight { break }
                    let indexInI = i * width
                    for j in 0..<squareSize {
                        // skip all the pixels that are outside the screen (which can happen since we can
                        // have incomplete squares in the last column and last row which would finish outside)
                        if xCol + j >= width { break }
                        
                        let index = indexToCurrentSquare + indexInI + j
                        
                        let colorValue = pixelBuffer[index].value()
                        colors[colorValue] = (colors[colorValue] ?? 0) + 1
                        
                        squareIndices[count] = index
                        count += 1
                    }
                }
                
                var bestColor = RGBA32.clear
                let max = colors.values.max()
                for (key, value) in colors {
                    if value == max {
                        bestColor = RGBA32(UInt32(key))
                        break
                    }
                }
                
                for i in 0..<count {
                    pixelBuffer[squareIndices[i]] = bestColor
                }
            }
        }
        
        // stop measuring time
//        let end = DispatchTime.now()
        
        // print time elapsed
//        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
//        let timeInterval = Double(nanoTime) / 1_000_000_000
//        print("Pixelating took \(timeInterval) seconds")
        
        let outputCGImage = context.makeImage()!
        let outputImage = UIImage(cgImage: outputCGImage, scale: drawing.scale, orientation: drawing.imageOrientation)
        setBackgroundImage(outputImage)
    }
    
    /// Returns a pixelated drawing back to its original form
    func depixelate() {
        guard pixelating else { return }
        pixelating = false
        setBackgroundImage(originalDrawing)
    }
    
    var isDrawingPixels = false
    var infoToContinueDrawingPixels: (scale: CGFloat, context: CGContext, width: Int, height: Int, pixelBuffer: UnsafeMutablePointer<RGBA32>, pixelSize: CGFloat, orientation: UIImageOrientation)!
    var lastPixelDrawn: (x: Int, y: Int) = (-1, -1)
    var lastPixelImage: UIImage!
    /// Draws the whole pixel in which a touch was detected
    func drawPixels(at touch: UITouch, with grid: Grid) {
        isDrawingPixels = true
        let pos = touch.location(in: grid)
        var x = Int(round(pos.x))
        var y = Int(round(pos.y))
        
        let pixelSize = grid.grids[grid.currentIndex].pixelSize
        var squareSize = Int(pixelSize)
        
        let squareXIndex = x / squareSize
        let squareYIndex = y / squareSize
        
        if lastPixelDrawn != (-1, -1) && (squareXIndex, squareYIndex) == lastPixelDrawn { return }
        lastPixelDrawn = (squareXIndex, squareYIndex)
        
        let drawing = self.toImage()
        let scale = drawing.scale
        x = Int(CGFloat(x) * scale)
        y = Int(CGFloat(y) * scale)
        guard x >= 0 && y >= 0 else { return }
        squareSize = Int(CGFloat(squareSize) * scale)
        
        undoStack.append(drawing)
        redoStack = []
        
        let topY = Int(round(visibleFrame.minY) * scale)
        
        let (context, width, _, pixelBuffer) = drawing.getDataBuffer()
        let visibleHeight = Int(visibleFrame.height * scale)
        let paintColor = RGBA32(brush.color)
        let indexToCurrentSquare = (width * squareYIndex + squareXIndex) * squareSize + topY * width
        
        for i in 0..<squareSize {
            if squareYIndex * squareSize + i >= visibleHeight { break }
            let indexInI = i * width
            for j in 0..<squareSize {
                if squareXIndex * squareSize + j >= width { break }
                
                let index = indexToCurrentSquare + indexInI + j
                pixelBuffer[index] = paintColor
            }
        }
        
        let outputCGImage = context.makeImage()!
        let outputImage = UIImage(cgImage: outputCGImage, scale: drawing.scale, orientation: drawing.imageOrientation)
        
        setBackgroundImage(outputImage)
        
        infoToContinueDrawingPixels = (scale, context, width, visibleHeight, pixelBuffer, pixelSize, drawing.imageOrientation)
        lastPixelImage = outputImage
    }
    
    func continueDrawingPixels(at touch: UITouch, with grid: Grid) {
        let pos = touch.location(in: grid)
        var x = Int(round(pos.x))
        var y = Int(round(pos.y))
        
        let (scale, context, width, height, pixelBuffer, pixelSize, orientation) = infoToContinueDrawingPixels
        var squareSize = Int(pixelSize)
        
        let squareXIndex = x / squareSize
        let squareYIndex = y / squareSize
        
        if lastPixelDrawn != (-1, -1) && (squareXIndex, squareYIndex) == lastPixelDrawn { return }
        lastPixelDrawn = (squareXIndex, squareYIndex)
        
        x = Int(CGFloat(x) * scale)
        y = Int(CGFloat(y) * scale)
        guard x >= 0 && y >= 0 else { return }
        squareSize = Int(CGFloat(squareSize) * scale)
        
        let topY = Int(round(visibleFrame.minY) * scale)
        let paintColor = RGBA32(brush.color)
        let indexToCurrentSquare = (width * squareYIndex + squareXIndex) * squareSize + topY * width
        
        for i in 0..<squareSize {
            if squareYIndex * squareSize + i >= height { break }
            let indexInI = i * width
            for j in 0..<squareSize {
                if squareXIndex * squareSize + j >= width { break }
                
                let index = indexToCurrentSquare + indexInI + j
                pixelBuffer[index] = paintColor
            }
        }
        
        let outputCGImage = context.makeImage()!
        let outputImage = UIImage(cgImage: outputCGImage, scale: scale, orientation: orientation)
        
        setBackgroundImage(outputImage)
        infoToContinueDrawingPixels = (scale, context, width, height, pixelBuffer, pixelSize, orientation)
        lastPixelImage = outputImage
    }
    
    func finishDrawingPixels() {
        UserDefaults.standard.set(UIImagePNGRepresentation(lastPixelImage), forKey: "lastDrawing")
        isDrawingPixels = false
    }
    
    func pickColorAt(_ touch: UITouch) -> UIColor {
        let drawing = self.toImage()
        let (context, width, _, pixelBuffer) = drawing.getDataBuffer() // ignore warning, context is required to access pixelBuffer
        
        let location = touch.location(in: self)
        let x = Int(round(location.x) * drawing.scale)
        let y = Int(round(location.y) * drawing.scale)
        
        let index = y * width + x
        return UIColor(pixelBuffer[index])
    }
    
    func uploadImage(_ image: UIImage) {
        undoStack.append(self.toImage())
        redoStack = []
        setBackgroundImage(image)
        UserDefaults.standard.set(UIImagePNGRepresentation(self.toImage()), forKey: "lastDrawing")
    }
    
    /// Sets the background of the canvas to the specified image
    func setBackgroundImage(_ image: UIImage) {
        pathArray = []
        self.backgroundColor = UIColor(patternImage: image)
    }
    
    /********************************** Private Functions **********************************/
    
    private func setTouchPoints(_ touch: UITouch,view: UIView) {
        previousPoint = touch.previousLocation(in: view)
        previousPreviousPoint = touch.previousLocation(in: view)
        currentPoint = touch.location(in: view)
    }
    
    private func updateTouchPoints(for touch: UITouch,in view: UIView) {
        previousPreviousPoint = previousPoint
        previousPoint = touch.previousLocation(in: view)
        currentPoint = touch.location(in: view)
    }
    
    private func createNewPath() -> CGMutablePath {
        let midPoints = getMidPoints()
        let subPath = createSubPath(midPoints.0, mid2: midPoints.1)
        let newPath = addSubPathToPath(subPath)
        return newPath
    }
    
    private func calculateMidPoint(_ p1 : CGPoint, p2 : CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) * 0.5, y: (p1.y + p2.y) * 0.5);
    }
    
    private func getMidPoints() -> (CGPoint,  CGPoint) {
        let mid1: CGPoint = calculateMidPoint(previousPoint, p2: previousPreviousPoint)
        let mid2: CGPoint = calculateMidPoint(currentPoint, p2: previousPoint)
        return (mid1, mid2)
    }
    
    private func createSubPath(_ mid1: CGPoint, mid2: CGPoint) -> CGMutablePath {
        let subpath: CGMutablePath = CGMutablePath()
        subpath.move(to: CGPoint(x: mid1.x, y: mid1.y))
        subpath.addQuadCurve(to: CGPoint(x: mid2.x, y: mid2.y), control: CGPoint(x: previousPoint.x, y: previousPoint.y))
        return subpath
    }
    
    private func addSubPathToPath(_ subpath: CGMutablePath) -> CGMutablePath {
        let boundingBox: CGRect = subpath.boundingBox
        let drawBox: CGRect = boundingBox.insetBy(dx: -2.0 * brush.width, dy: -2.0 * brush.width)
        setNeedsDisplay(drawBox)
        return subpath
    }
}

struct RGBA32: Equatable, Hashable {
    private var color: UInt32
    
    var redComponent: UInt8 {
        return UInt8((color >> 24) & 255)
    }
    
    var greenComponent: UInt8 {
        return UInt8((color >> 16) & 255)
    }
    
    var blueComponent: UInt8 {
        return UInt8((color >> 8) & 255)
    }
    
    var alphaComponent: UInt8 {
        return UInt8((color >> 0) & 255)
    }
    
    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        let red   = UInt32(red)
        let green = UInt32(green)
        let blue  = UInt32(blue)
        let alpha = UInt32(alpha)
        color = (red << 24) | (green << 16) | (blue << 8) | (alpha << 0)
    }
    
    init(_ inputColor: UIColor) {
        let rgba = inputColor.rgba()!
        let red   = UInt32(rgba.red)
        let green = UInt32(rgba.green)
        let blue  = UInt32(rgba.blue)
        let alpha = UInt32(rgba.alpha)
        color = (red << 24) | (green << 16) | (blue << 8) | (alpha << 0)
    }
    
    init(_ value: UInt32) {
        color = value
    }
    
    static let clear   = RGBA32(red: 0, green: 0, blue: 0, alpha: 0)
    static let red     = RGBA32(red: 255, green: 0,   blue: 0,   alpha: 255)
    static let green   = RGBA32(red: 0,   green: 255, blue: 0,   alpha: 255)
    static let blue    = RGBA32(red: 0,   green: 0,   blue: 255, alpha: 255)
    static let white   = RGBA32(red: 255, green: 255, blue: 255, alpha: 255)
    static let black   = RGBA32(red: 0,   green: 0,   blue: 0,   alpha: 255)
    static let magenta = RGBA32(red: 255, green: 0,   blue: 255, alpha: 255)
    static let yellow  = RGBA32(red: 255, green: 255, blue: 0,   alpha: 255)
    static let cyan    = RGBA32(red: 0,   green: 255, blue: 255, alpha: 255)
    
    static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    
    func value() -> UInt32 {
        return color
    }
    
    static func ==(lhs: RGBA32, rhs: RGBA32) -> Bool {
        return abs(Int(lhs.redComponent) - Int(rhs.redComponent)) <= 1 &&
            abs(Int(lhs.blueComponent) - Int(rhs.blueComponent)) <= 1 &&
            abs(Int(lhs.greenComponent) - Int(rhs.greenComponent)) <= 1
    }
    
    static func !=(lhs: RGBA32, rhs: RGBA32) -> Bool {
        return !(lhs == rhs)
    }
}
