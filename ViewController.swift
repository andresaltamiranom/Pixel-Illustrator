//
//  ViewController.swift
//  Pixel Artist
//
//  Created by Andres Altamirano on 6/6/18.
//  Copyright © 2018 AndresAltamirano. All rights reserved.
//

import UIKit
import MessageUI
import StoreKit

enum ImageSource {
    case camera, photoLibrary
    
    func type() -> UIImagePickerControllerSourceType {
        switch self {
        case .camera:
            return .camera
        case .photoLibrary:
            return .photoLibrary
        }
    }
    
    func name() -> String {
        switch self {
        case .camera:
            return "Camera"
        case .photoLibrary:
            return "Photo Library"
        }
    }
}

enum Tool: Int {
    case brush = 0, bucket, eraser, eyedropper
}

enum SelectOptions: Int {
    case tools = 0, grid
}

class ViewController: UIViewController, DrawViewDelegate, HSBColorPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate/*, MFMailComposeViewControllerDelegate*/ {
    func Draw(shouldBeginDrawingIn drawingView: DrawView, using touch: UITouch) -> Bool {
        guard !isPixelated else {
            showAlert(title: "Unable to draw", message: "Switch to drawing mode to continue drawing.", duration: 1.5)
            
            return false
        }
        
        switch selectedTool {
        case .brush:
            drawView.brush.color = selectedColor.backgroundColor!
            if gridIsShown {
                if drawView.isDrawingPixels {
                    drawingView.continueDrawingPixels(at: touch, with: grid)
                } else {
                    drawView.drawPixels(at: touch, with: grid)
                }
            }
            return !gridIsShown
        case .bucket:
            drawView.brush.color = selectedColor.backgroundColor!
            showActivityIndicator("Filling")
            
            DispatchQueue.main.async {
                self.drawView.fill(touch)
                DispatchQueue.main.async {
                    self.removeActivityIndicator()
                }
            }
            return false
        case .eraser:
            drawView.brush.color = .white
            if gridIsShown {
                if drawView.isDrawingPixels {
                    drawingView.continueDrawingPixels(at: touch, with: grid)
                } else {
                    drawView.drawPixels(at: touch, with: grid)
                }
            }
            return !gridIsShown
        case .eyedropper:
            let color = drawView.pickColorAt(touch)
            selectedColor.backgroundColor = color
            drawView.brush.color = color
            return false
        }
    }
    
    func Draw(didBeginDrawingIn drawingView: DrawView, using touch: UITouch) {
        guard !isPixelated else { return }
    }
    
    func Draw(isDrawingIn drawingView: DrawView, using touch: UITouch) {
        
    }
    
    func Draw(didFinishDrawingIn drawingView: DrawView, using touch: UITouch) {
        guard !isPixelated else { return }
        
        if drawingView.isDrawingPixels {
            drawingView.finishDrawingPixels()
        }
        
        if drawingView.canUndo {
            undoButton.isEnabled = true
        }
        
        if !drawingView.canRedo {
            redoButton.isEnabled = false
        }
    }
    
    func Draw(didCancelDrawingIn drawingView: DrawView, using touch: UITouch) {
        Draw(didFinishDrawingIn: drawingView, using: touch)
    }

    var drawView: DrawView!
    var redoButton: UIButton!
    var undoButton: UIButton!
    var deleteButton: UIButton!
    var selectedColor: UIButton!
    var pixelateButton: UIButton!
    var saveButton: UIButton!
    var imageButton: UIButton!
    var shareButton: UIButton!
    var showGrid: UISwitch!
    var gridButton: UIButton!
    var toolsButton: UIButton!
    var brushButton: UIButton!
    var bucketButton: UIButton!
    var eraserButton: UIButton!
    var eyedropperButton: UIButton!
    var lineWidthSlider: UISlider!
    var topFrameView: UIView!
    var bottomFrameTopView: UIView!
    var bottomFrameBottomView: UIView!
    var toolsFrameView: UIView!
    var gridFrameView: UIView!
    var alert: UIAlertController!
    var grid: Grid!
    var gridSlider: UISlider!
    var colorPicker: HSBColorPicker!
    var isColorPickerInBack = true
    var gridIsShown = false
    var isPixelated = false
    var selectedOption = SelectOptions.tools
    var selectedTool = Tool.brush
    var selectedToolSize: CGSize!
    var notSelectedToolSize: CGSize!
    let bounds = UIScreen.main.bounds
    let appName = "Pixel Illustrator"
    let pixelationCountToRequestReview = 30
    
    var brushImageBig: UIImage!
    var brushImageSmall: UIImage!
    var bucketImageBig: UIImage!
    var bucketImageSmall: UIImage!
    var eraserImageBig: UIImage!
    var eraserImageSmall: UIImage!
    var eyedropperImageBig: UIImage!
    var eyedropperImageSmall: UIImage!
    var paletteImageBig: UIImage!
    var paletteImageSmall: UIImage!
    var rulerImageBig: UIImage!
    var rulerImageSmall: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createBackground()
        
        brushImageBig = UIImage(named: "brush")
        brushImageSmall = brushImageBig.scaleTo(targetSize: notSelectedToolSize)
        bucketImageBig = UIImage(named: "bucket")
        bucketImageSmall = bucketImageBig.scaleTo(targetSize: notSelectedToolSize)
        eraserImageBig = UIImage(named: "eraser")
        eraserImageSmall = eraserImageBig.scaleTo(targetSize: notSelectedToolSize)
        eyedropperImageBig = UIImage(named: "eyedropper")
        eyedropperImageSmall = eyedropperImageBig.scaleTo(targetSize: notSelectedToolSize)
        paletteImageBig = UIImage(named: "palette")
        paletteImageSmall = paletteImageBig.scaleTo(targetSize: notSelectedToolSize)
        rulerImageBig = UIImage(named: "ruler")
        rulerImageSmall = rulerImageBig.scaleTo(targetSize: notSelectedToolSize)
        
        createGrid()
        createTools()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func selectOption(sender: UIButton) {
        guard sender.tag != selectedOption.rawValue else { return }
        
        if sender.tag == SelectOptions.tools.rawValue {
            selectedOption = .tools
            brushButton.isHidden = false
            eraserButton.isHidden = false
            bucketButton.isHidden = false
            eyedropperButton.isHidden = false
            lineWidthSlider.isHidden = false
            bottomFrameTopView.layer.addSublayer(shapeLayer)
            showGrid.isHidden = true
            gridSlider.isHidden = true
            
            // Change the bottom-top bar background color
            (bottomFrameTopView.layer.sublayers![0] as! CAShapeLayer).fillColor =
                (toolsFrameView.layer.sublayers![0] as! CAShapeLayer).fillColor
            
            toolsButton.setImage(paletteImageBig, for: .normal)
            gridButton.setImage(rulerImageSmall, for: .normal)
        } else {
            selectedOption = .grid
            brushButton.isHidden = true
            eraserButton.isHidden = true
            bucketButton.isHidden = true
            eyedropperButton.isHidden = true
            lineWidthSlider.isHidden = true
            shapeLayer.removeFromSuperlayer()
            showGrid.isHidden = false
            gridSlider.isHidden = false
            
            // Change the bottom-top bar background color
            (bottomFrameTopView.layer.sublayers![0] as! CAShapeLayer).fillColor =
                (gridFrameView.layer.sublayers![0] as! CAShapeLayer).fillColor
            
            toolsButton.setImage(paletteImageSmall, for: .normal)
            gridButton.setImage(rulerImageBig, for: .normal)
        }
    }
    
    @objc func selectTool(sender: UIButton) {
        guard sender.tag != selectedTool.rawValue else { return }
        
        if sender.tag == Tool.brush.rawValue {
            selectedTool = .brush
            
            brushButton.setImage(brushImageBig, for: .normal)
            bucketButton.setImage(bucketImageSmall, for: .normal)
            eraserButton.setImage(eraserImageSmall, for: .normal)
            eyedropperButton.setImage(eyedropperImageSmall, for: .normal)
            
            lineWidthSlider.isEnabled = true
            drawView.isEnabled = true
        } else if sender.tag == Tool.bucket.rawValue {
            selectedTool = .bucket
            
            brushButton.setImage(brushImageSmall, for: .normal)
            bucketButton.setImage(bucketImageBig, for: .normal)
            eraserButton.setImage(eraserImageSmall, for: .normal)
            eyedropperButton.setImage(eyedropperImageSmall, for: .normal)
            
            lineWidthSlider.isEnabled = false
            drawView.isEnabled = false
        } else if sender.tag == Tool.eraser.rawValue {
            selectedTool = .eraser
            
            brushButton.setImage(brushImageSmall, for: .normal)
            bucketButton.setImage(bucketImageSmall, for: .normal)
            eraserButton.setImage(eraserImageBig, for: .normal)
            eyedropperButton.setImage(eyedropperImageSmall, for: .normal)
            
            lineWidthSlider.isEnabled = true
            drawView.isEnabled = true
        } else if sender.tag == Tool.eyedropper.rawValue {
            selectedTool = .eyedropper
            
            brushButton.setImage(brushImageSmall, for: .normal)
            bucketButton.setImage(bucketImageSmall, for: .normal)
            eraserButton.setImage(eraserImageSmall, for: .normal)
            eyedropperButton.setImage(eyedropperImageBig, for: .normal)
            
            lineWidthSlider.isEnabled = false
            drawView.isEnabled = false
        }
    }
    
    @objc func undo() {    
        drawView.undo()
        
        if !drawView.canUndo {
            undoButton.isEnabled = false
        }
        
        if drawView.canRedo {
            redoButton.isEnabled = true
        }
    }
    
    @objc func redo() {
        drawView.redo()
        if !drawView.canRedo {
            redoButton.isEnabled = false
        }
        
        if drawView.canUndo {
            undoButton.isEnabled = true
        }
    }
    
    @objc func deleteDrawing() {
        self.drawView.clear()
        undoButton.isEnabled = false
        redoButton.isEnabled = false
    }
    
    @objc func changePixelation() {
        if isPixelated {
            pixelateButton.setImage(UIImage(named: "pixelate_button"), for: .normal)
            drawView.depixelate()
            isPixelated = false
            undoButton.isEnabled = drawView.canUndo
            redoButton.isEnabled = drawView.canRedo
            deleteButton.isEnabled = true
            imageButton.isEnabled = true
            brushButton.isEnabled = true
            bucketButton.isEnabled = true
            eraserButton.isEnabled = true
            eyedropperButton.isEnabled = true
            selectedColor.isEnabled = true
            selectedColor.isHidden = false
            lineWidthSlider.isEnabled = true
        } else {
            self.undoButton.isEnabled = false
            self.redoButton.isEnabled = false
            self.deleteButton.isEnabled = false
            self.imageButton.isEnabled = false
            self.brushButton.isEnabled = false
            self.bucketButton.isEnabled = false
            self.eraserButton.isEnabled = false
            self.eyedropperButton.isEnabled = false
            self.selectedColor.isEnabled = false
            self.selectedColor.isHidden = true
            self.lineWidthSlider.isEnabled = false
            
            showActivityIndicator("Pixelating")
            DispatchQueue.main.async {
            
                self.drawView.pixelate(with: self.grid)
                
                DispatchQueue.main.async {
                    self.removeActivityIndicator()
                    
                    self.pixelateButton.setImage(UIImage(named: "draw_button"), for: .normal)
                    self.isPixelated = true
                    
                }
            }
            
            let pixelationCount = UserDefaults.standard.integer(forKey: "pixelationCounter")
            
            if pixelationCount + 1 >= pixelationCountToRequestReview {
                UserDefaults.standard.set(0, forKey: "pixelationCounter")
                
                if #available(iOS 10.3, *) {
                    SKStoreReviewController.requestReview()
                } else {
                    // Fallback on earlier versions
                }
            } else {
                UserDefaults.standard.set(pixelationCount + 1, forKey: "pixelationCounter")
            }
        }
    }
    
    var shapeLayer = CAShapeLayer() // Dot representing brush size
    @objc func lineWidthSliderValueDidChange(sender: UISlider!) {
        drawView.brush.width = CGFloat(sender.value)
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: lineWidthSlider.x + lineWidthSlider.width + bounds.width * 0.05, y: lineWidthSlider.y + lineWidthSlider.height / 2.0), radius: CGFloat(drawView.brush.width / 2.0), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        
        shapeLayer.removeFromSuperlayer()
        shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = UIColor.white.cgColor
        bottomFrameTopView.layer.addSublayer(shapeLayer)
        
        UserDefaults.standard.set(sender.value, forKey: "brushSize")
    }
    
    @objc func gridSliderValueDidChange(sender: UISlider!) {
        let value = Int(sender.value)
        grid.setGrid(to: value, shouldShow: gridIsShown)
    }
    
    func getDrawViewImage() -> UIImage {
        let image = drawView.toImage()
        let cgImage = image.cgImage!
        let croppedCGImage = cgImage.cropping(to:
            CGRect(x: 0,
                   y: drawView.visibleFrame.minY * image.scale,
                   width: bounds.width * image.scale,
                   height: drawView.visibleFrame.height * image.scale))!
        
        let uiImage = UIImage(cgImage: croppedCGImage)
        return uiImage
    }
    
    @objc func saveImageToDevice() {
        let myimage = getDrawViewImage()
        UIImageWriteToSavedPhotosAlbum(myimage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            showAlert(title: "Error", message: "There was an error while trying to save the drawing to your device.")
        } else {
            showAlert(title: "Drawing Saved", message: "Your drawing has been saved. You can now find it on your camera roll.")
        }
    }
    
    @objc func toggleGrid() {
        if gridIsShown {
            gridIsShown = false
            grid.removeGrid()
        } else {
            gridIsShown = true
            grid.redrawGrid()
        }
    }
    
    func uploadImage(from source: ImageSource) {
        if !UIImagePickerController.isSourceTypeAvailable(source.type()) {
            showAlert(title: "\(source.name()) not available", message: "\(appName) cannot access the \(source.name()).")
            return
        }
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = source.type();
        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let newImage = image.padTo(frame: drawView.frame,
                                       top: topFrameView.frame.height,
                                       right: 0,
                                       bottom: drawView.frame.height - bottomFrameTopView.frame.minY,
                                       left: 0)
            
            drawView.uploadImage(newImage)
            redoButton.isEnabled = false
        }
        dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func pressColorPicker(_ sender: UIButton) {
        if isColorPickerInBack {
            self.view.bringSubview(toFront: colorPicker)
            isColorPickerInBack = false
        } else {
            self.view.sendSubview(toBack: colorPicker)
            isColorPickerInBack = true
        }
    }
    
    func HSBColorColorPickerSelected(color: UIColor) {
        selectedColor.backgroundColor = color
        drawView.brush.color = color
        self.view.sendSubview(toBack: colorPicker)
        isColorPickerInBack = true
        
        let colorData = NSKeyedArchiver.archivedData(withRootObject: color) as Data
        UserDefaults.standard.set(colorData, forKey: "brushColor")
    }
    
    func HSBColorPickerPreview(color: UIColor) {
        selectedColor.backgroundColor = color
    }
    
    @objc func share() {
        let imageToShare = getDrawViewImage()
        let textToShare = "Created with #PixelIllustrator"
        let activityVC = UIActivityViewController(activityItems: [imageToShare, textToShare], applicationActivities: nil)
        activityVC.excludedActivityTypes = [UIActivityType.print, UIActivityType.copyToPasteboard, UIActivityType.airDrop, UIActivityType.addToReadingList]
        
        if let popOver = activityVC.popoverPresentationController {
            popOver.sourceView = self.view
            popOver.sourceRect = self.view.bounds
        }
        
        present(activityVC, animated: true, completion: nil)
    }
    
    @objc func showImageAlert() {
        let alertController = UIAlertController(title: "Upload Photo", message: "How do you want to upload a photo?", preferredStyle: .alert)
        
        let cameraAction = UIAlertAction(title: "Take a picture", style: .default) { (action) in
            self.uploadImage(from: .camera)
        }
        
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            self.uploadImage(from: .photoLibrary)
        }
        
        let closeAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in }
        closeAction.setValue(UIColor.red, forKey: "titleTextColor")
        
        alertController.addAction(cameraAction)
        alertController.addAction(photoLibraryAction)
        alertController.addAction(closeAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func showDeleteAlert() {
        let alertController = UIAlertController(title: "Delete Drawing", message: "Are you sure you want to delete your current drawing?", preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .default) { (action) in
            self.deleteDrawing()
        }
        
        let saveAndDeleteAction = UIAlertAction(title: "Save and delete", style: .default) { (action) in
            self.saveImageToDevice()
            self.deleteDrawing()
        }
        
        let closeAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in }
        closeAction.setValue(UIColor.red, forKey: "titleTextColor")
        
        alertController.addAction(deleteAction)
        alertController.addAction(saveAndDeleteAction)
        alertController.addAction(closeAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showAlert(title: String, message: String, duration: TimeInterval = 3.0) {
        self.alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(self.alert, animated: true, completion: nil)
        Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(dismissAlert), userInfo: nil, repeats: false)
    }
    
    @objc func dismissAlert(){
        self.alert.dismiss(animated: true, completion: nil)
    }
    
    var activityIndicatorLabel = UILabel()
    var activityIndicator = UIActivityIndicatorView()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    private func showActivityIndicator(_ title: String) {
        activityIndicatorLabel = UILabel(frame: CGRect(x: 10, y: 0, width: 160, height: 46))
        activityIndicatorLabel.textAlignment = .center
        activityIndicatorLabel.text = title
        activityIndicatorLabel.font = .systemFont(ofSize: 14, weight: .medium)
        activityIndicatorLabel.textColor = UIColor(white: 0.9, alpha: 0.7)
        
        effectView.frame = CGRect(x: view.frame.midX - activityIndicatorLabel.frame.width/2, y: view.frame.midY - activityIndicatorLabel.frame.height/2 , width: 160, height: 46)
        effectView.layer.cornerRadius = 15
        effectView.layer.masksToBounds = true
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 46, height: 46)
        activityIndicator.startAnimating()
        
        effectView.contentView.addSubview(activityIndicator)
        effectView.contentView.addSubview(activityIndicatorLabel)
        self.view.insertSubview(effectView, aboveSubview: topFrameView)
    }
    
    private func removeActivityIndicator() {
        activityIndicatorLabel.removeFromSuperview()
        activityIndicator.removeFromSuperview()
        effectView.removeFromSuperview()
    }
}

