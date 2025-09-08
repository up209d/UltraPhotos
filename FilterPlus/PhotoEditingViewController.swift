//
//  PhotoEditingViewController.swift
//  FilterPlus
//
//  Created by Duc Duong on 4/9/2025.
//

import Cocoa
import Photos
import PhotosUI
import AppKit
import AVFoundation

class PhotoEditingViewController: NSViewController, PHContentEditingController {

    var input: PHContentEditingInput?
    let formatIdentifier = "com.up209d.dev"
    let context: CIContext = CIContext()
    var lutPaths: [URL] = []
    var selectedLutURL: URL! = Bundle.main.url(forResource: "Default", withExtension: "cube")
    
    @IBOutlet weak var splitView: NSSplitView!
    
    @IBOutlet weak var previewImageView: ClickableNSImageView!
    @IBOutlet weak var sourceImageView: NSImageView!
    @IBOutlet weak var hidePreviewButton: ClickableNSButton!
    @IBOutlet weak var intensitySlider: NSSlider!
    
    @IBOutlet weak var lutScrollView: NSScrollView!
    @IBOutlet weak var lutCollectionView: NSCollectionView!
    
    private var lutSelectionViewController: LUTSelectionViewController!
    
    override func viewWillAppear() {
        // !IMPORTANT This fire after StartEditingContent
        // When extension reopens, refresh state, reload data, or update previews
//        if (self.intensitySlider != nil && self.input != nil && contentEditingInput.adjustmentData != nil) {
//            if let dict = try? JSONSerialization.jsonObject(with: contentEditingInput.adjustmentData!.data, options: []) as? [String: Any],
//               let intensity = dict["intensity"] as? Float {
//                    self.intensitySlider.floatValue = intensity
//                    renderPreview(intensity: intensity)
//            }
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Bind events
        self.hidePreviewButton.onMouseDown = {
            self.previewImageView.alphaValue = 0.0
        }
        self.hidePreviewButton.onMouseUp = {
            self.previewImageView.alphaValue = 1.0
        }
    }

    // MARK: - PHContentEditingController

    @IBAction func intensityChanged(_ sender: NSSlider) {
        print("Intensity changed: \(sender.floatValue)")
        if (selectedLutURL == nil) {
            return
        }
        renderPreview(intensity: sender.floatValue)
    }
    
    @IBAction func buttonClicked(_ sender: NSButton) {
        sender.alphaValue = 0.35
        print("Mouse moved")
        // animate back to 1
        NSAnimationContext.runAnimationGroup { context in
            print("Mouse moved")
            context.duration = 0.2
            sender.animator().alphaValue = 1.0
        }
    }
    
    func getFiles(from folderURL: URL, ext: String) -> [URL] {
        let fileManager = FileManager.default
        var files: [URL] = []
        print("Scanning folder: \(folderURL)")
        do {
            let items = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            for item in items {
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory)
                    && item.pathExtension == ext {
                    print("Item with ext (\(ext)) found: \(item.lastPathComponent)")
                    if !isDirectory.boolValue {
                        files.append(item)
                    }
                }
            }
        } catch {
            print("Error reading directory: \(error)")
        }
        return files
    }
    
    func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        // Inspect the adjustmentData to determine whether your extension can work with past edits.
        // (Typically, you use its formatIdentifier and formatVersion properties to do this.)
        // return false
        if (adjustmentData.formatIdentifier == self.formatIdentifier) {
            return true
        }
        return false
    }
    
    func loadCubeLUT(from fileUrl: URL) -> (bData: Data, size: Int)? {
        guard let text = try? String(contentsOf: fileUrl, encoding: .utf8) else { return nil }

        var cubeSize = 0
        var cubeData = [Float]()
        var index = 0
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") || trimmed.isEmpty { continue } // skip comments
            if trimmed.lowercased().hasPrefix("lut_3d_size") {
                let parts = trimmed.components(separatedBy: " ")
                if let sizeInt = Int(parts.last ?? "") { cubeSize = sizeInt }
                continue
            }
            if (trimmed.lowercased().hasPrefix("domain_min")) {
                continue
            }
            if (trimmed.lowercased().hasPrefix("domain_max")) {
                continue
            }
            
            let components = trimmed.split(separator: " ").compactMap { Float($0) }
            if components.count == 3 {
                index = index + 3
                cubeData.append(components[0])
                cubeData.append(components[1])
                cubeData.append(components[2])
                cubeData.append(1.000)
            }
        }
        print("CubeData Length: \(index)")
        guard cubeSize > 0 else { return nil }
        let bData = cubeData.withUnsafeBufferPointer { buffer -> Data in
            return Data(buffer: buffer)
        }
        return (bData, cubeSize)
    }

    func applyFilterLUT(to ciImage: CIImage, cubeUrl: URL, intensity: Float) -> CIImage {
        guard let (bData, cubeSize) = self.loadCubeLUT(from: cubeUrl) else {
            print("Can't load LUT: " + cubeUrl.path())
            return ciImage
        }

        guard let filter = CIFilter(name: "CIColorCubeWithColorSpace") else {
            print("CIFilter not available")
            return ciImage
        }
        filter.setValue(cubeSize, forKey: "inputCubeDimension")
        filter.setValue(bData, forKey: "inputCubeData")
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        // Force color space to sRGB IEC61966-2.1
        if let srgbColorSpace = CGColorSpace(name: CGColorSpace.sRGB) {
            filter.setValue(srgbColorSpace, forKey: "inputColorSpace")
        }
        
        let alphaFilter = CIFilter(name: "CIConstantColorGenerator")!
        alphaFilter.setValue(CIColor(red: 0, green: 0, blue: 0, alpha: CGFloat(intensity/100)), forKey: kCIInputColorKey)
        let alphaImage = alphaFilter.outputImage!.cropped(to: ciImage.extent)
        
        let blend = CIFilter(name: "CIBlendWithAlphaMask")!
        blend.setValue(filter.outputImage ?? ciImage, forKey: kCIInputImageKey)       // top image
        blend.setValue(ciImage, forKey: kCIInputBackgroundImageKey) // bottom image
        blend.setValue(alphaImage, forKey: kCIInputMaskImageKey)
        return blend.outputImage ?? filter.outputImage ?? ciImage
    }
    
    func applyFilterInvert(to ciImage: CIImage) -> CIImage {
        let filter = CIFilter(name: "CIColorInvert")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        return filter.outputImage ?? ciImage
    }
    
    func renderPreview(intensity: Float) {
        DispatchQueue.global().async {
            if let src = self.input!.fullSizeImageURL {
                let ciImage = CIImage(contentsOf: src)!
                // let filtered = self.applyFilterInvert(to: ciImage)
                let filtered = self.applyFilterLUT(to: ciImage, cubeUrl: self.selectedLutURL!, intensity: intensity)
                guard let cgImg = self.context.createCGImage(filtered, from: filtered.extent) else { return }
                let nsImg = NSImage(cgImage: cgImg, size: .zero)
                DispatchQueue.main.async {
                    self.previewImageView.image = nsImg
                }
            }
        }
    }
    
    func renderOriginal() {
        DispatchQueue.global().async {
            if let src = self.input!.fullSizeImageURL {
                let ciImage = CIImage(contentsOf: src)!
                guard let cgImg = self.context.createCGImage(ciImage, from: ciImage.extent) else { return }
                let nsImg = NSImage(cgImage: cgImg, size: .zero)
                DispatchQueue.main.async {
                    self.sourceImageView.image = nsImg
                }
            }
        }
    }
    
    func startContentEditing(with contentEditingInput: PHContentEditingInput, placeholderImage: NSImage)  {
        // Present content for editing, and keep the contentEditingInput for use when closing the edit session.
        // If you returned true from canHandleAdjustmentData:, contentEditingInput has the original image and adjustment data.
        // If you returned false, the contentEditingInput has past edits "baked in".
        input = contentEditingInput
        
        guard let fullSizeImageURL = contentEditingInput.fullSizeImageURL else {
            print("Cannot get fullSizeImageURL from source")
            return
        }
        
        guard let imageSource = CGImageSourceCreateWithURL(fullSizeImageURL as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            print("Cannot read image dimensions")
            return
        }
        
        
        lutSelectionViewController = LUTSelectionViewController(
            splitView: splitView,
            scrollView: lutScrollView,
            collectionView: lutCollectionView,
            itemRatio: Float(width) / Float(height)
        )
        self.addChild(lutSelectionViewController)
        
        lutSelectionViewController.onSelected = { path in
            self.selectedLutURL = URL(string: path)!
            self.renderPreview(intensity: self.intensitySlider.floatValue)
        }
        
        lutSelectionViewController.onDeselected = { path in
            self.selectedLutURL = Bundle.main.url(forResource: "Default", withExtension: "cube")
            self.renderPreview(intensity: self.intensitySlider.floatValue)
        }
        
        renderOriginal()
        
        if (self.intensitySlider != nil && self.input != nil && contentEditingInput.adjustmentData != nil) {
            if let dict = try? JSONSerialization.jsonObject(with: contentEditingInput.adjustmentData!.data, options: []) as? [String: Any],
               let lutPath = dict["lutPath"] as? String,
               let lutUrl = URL(string: lutPath),
               let intensity = dict["intensity"] as? Float {
                    self.selectedLutURL = lutUrl
                    self.intensitySlider.floatValue = intensity
            }
        }
        
        // Input identifier
        // let identifier = String(contentEditingInput.fullSizeImageURL!.path)
        // print("File identifier: \(identifier)")
        
        print("Now scanning for all LUTs...")
        lutPaths.append(contentsOf: getFiles(from: self.selectedLutURL!.deletingLastPathComponent(), ext: "cube"))
        
        renderAllThumbnails()
        
        self.previewImageView.image = placeholderImage
        renderPreview(intensity: self.intensitySlider.floatValue)
    }
    
    func makeThumbnailSource(from image: CIImage, maxDimension: CGFloat = 256) -> CIImage {
        let extent = image.extent
        let scale = maxDimension / max(extent.width, extent.height)
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }
    
    func renderThumbnail(for cubeUrl: URL, thumbImage: CIImage, context: CIContext) -> NSImage? {
        let filtered = self.applyFilterLUT(to: thumbImage, cubeUrl: cubeUrl, intensity: 100)
        guard let cgImage = context.createCGImage(filtered, from: filtered.extent) else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: filtered.extent.size)
    }
    
    func renderAllThumbnails() {
        let sourceThumbnailImage = makeThumbnailSource(
            from: CIImage(contentsOf: input!.fullSizeImageURL!)!
        )
        for lutPath in lutPaths {
            DispatchQueue.global(qos: .userInitiated).async {
                let thumbnailImage = self.renderThumbnail(
                    for: lutPath as URL,
                    thumbImage: sourceThumbnailImage,
                    context: self.context
                )
                DispatchQueue.main.async {
                    guard let t = thumbnailImage else {
                        return
                    }
                    let item = ViewThumbnailItem(key: lutPath.absoluteString, image: t)
                    self.lutSelectionViewController.lutThumbnails.append(item)
                    self.lutSelectionViewController.lutThumbnails.sort { a, b in
                        let originalKey = "Default.cube"
                        if a.key.hasSuffix(originalKey) { return true }
                        if b.key.hasSuffix(originalKey) { return false }
                        return a.key < b.key
                    }
                }
            }
        }
    }
    
    func writeCIImageAsJPG(_ ciImage: CIImage, to url: URL) -> Bool {
        guard let cgImage = self.context.createCGImage(ciImage, from: ciImage.extent) else {
            return false
        }
        // Create destination for HEIC
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, AVFileType.jpg as CFString, 1, nil) else {
            return false
        }
        // Optional: specify HEIC properties
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 1.0 // Max Quality
        ]
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        return CGImageDestinationFinalize(destination)
    }
    
    func finishContentEditing(completionHandler: @escaping ((PHContentEditingOutput?) -> Void)) {
        // Update UI to reflect that editing has finished and output is being rendered.
        
        // Render and provide output on a background queue.
        DispatchQueue.global().async {
            // Create editing output from the editing input.
            let output = PHContentEditingOutput(contentEditingInput: self.input!)
            
            if let src = self.input!.fullSizeImageURL {
                let ciImage = CIImage(contentsOf: src)!
                let filtered = self.applyFilterLUT(to: ciImage, cubeUrl: self.selectedLutURL!, intensity: self.intensitySlider.floatValue)
                if self.writeCIImageAsJPG(filtered, to: output.renderedContentURL) {
                    let dict: [String: Any] = [
                        "lutPath": self.selectedLutURL.absoluteString,
                        "intensity": self.intensitySlider.floatValue]
                    let data = try! JSONSerialization.data(withJSONObject: dict, options: [])
                    output.adjustmentData = PHAdjustmentData(
                        formatIdentifier: self.formatIdentifier,
                        formatVersion: "1.0",
                        data: data
                    )
                    completionHandler(output)
                    return
                }
            }
            completionHandler(nil)
            return
        }
    }

    var shouldShowCancelConfirmation: Bool {
        // Determines whether a confirmation to discard changes should be shown to the user on cancel.
        // (Typically, this should be "true" if there are any unsaved changes.)
        return false
    }

    func cancelContentEditing() {
        // Clean up temporary files, etc.
        // May be called after finishContentEditingWithCompletionHandler: while you prepare output.
    }

}
