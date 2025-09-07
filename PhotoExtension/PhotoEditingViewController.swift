//
//  PhotoEditingViewController.swift
//  PhotoExtension
//
//  Created by Duc Duong on 4/9/2025.
//

import Cocoa
import Photos
import PhotosUI
import AppKit

class PhotoEditingViewController: NSViewController, PHContentEditingController {

    var input: PHContentEditingInput?
    let context = CIContext()
    let formatIdentifier = "com.up209d.dev"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    // MARK: - PHContentEditingController

    func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        // Inspect the adjustmentData to determine whether your extension can work with past edits.
        // (Typically, you use its formatIdentifier and formatVersion properties to do this.)
        // return false
        return adjustmentData.formatIdentifier == self.formatIdentifier
    }
    
    func startContentEditing(with contentEditingInput: PHContentEditingInput, placeholderImage: NSImage) {
        // Present content for editing, and keep the contentEditingInput for use when closing the edit session.
        // If you returned true from canHandleAdjustmentData:, contentEditingInput has the original image and adjustment data.
        // If you returned false, the contentEditingInput has past edits "baked in".
        input = contentEditingInput
        
        // TODO: Show your LUT UI here (slider, LUT picker, preview)
    }
    
    func finishContentEditing(completionHandler: @escaping ((PHContentEditingOutput?) -> Void)) {
        // Update UI to reflect that editing has finished and output is being rendered.
        
        // Render and provide output on a background queue.
        DispatchQueue.global().async {
            guard let input = self.input else {
                completionHandler(nil)
                return
            }
            // Create editing output from the editing input.
            let output = PHContentEditingOutput(contentEditingInput: input)
            
            // Provide new adjustments and render output to given location.
            // output.adjustmentData = <#new adjustment data#>
            // let renderedJPEGData = <#output JPEG#>
            // renderedJPEGData.writeToURL(output.renderedContentURL, atomically: true)
            
//            if let url = input.fullSizeImageURL,
//               let ciImage = CIImage(contentsOf: url) {
//                // Invert Image
//                let filter = CIFilter(name: "CIColorInvert")!
//                filter.setValue(ciImage, forKey: kCIInputImageKey)
//                let filtered = filter.outputImage ?? ciImage
//                if let cgimg = self.context.createCGImage(filtered, from: filtered.extent) {
//                    let nsImage = NSImage(cgImage: cgimg, size: .zero)
//                    if let tiffData = nsImage.tiffRepresentation {
//                        try? tiffData.write(to: output.renderedContentURL)
//                    }
//                }
//                // Save adjustment metadata
//                let adjData = PHAdjustmentData(
//                    formatIdentifier: self.formatIdentifier, formatVersion: "1.0", data: Data("Filter applied".utf8)
//                )
//                output.adjustmentData = adjData
//                completionHandler(output)
//            } else {
//                completionHandler(nil)
//            }
            
            // Call completion handler to commit edit to Photos.
            completionHandler(output)
            
            // Clean up temporary files, etc.
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
