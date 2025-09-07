//
//  LUTThumbnail.swift
//  UltraPhotos
//
//  Created by Duc Duong on 7/9/2025.
//

import Cocoa

class LUTThumbnail: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("LUTThumbnail")
    private var titleLabel: NSTextField!
    override func loadView() {
        // Create view programmatically
        self.view = NSView()
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        self.view.addSubview(imageView)
        self.imageView = imageView
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Label setup
        let label = NSTextField(labelWithString: "") // non-editable
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alignment = .center
        label.textColor = .white
        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        
        // Add shadow
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.7)
        shadow.shadowBlurRadius = 3
        shadow.shadowOffset = NSSize(width: 1, height: -1)
        label.shadow = shadow
        
        view.addSubview(label)
        self.titleLabel = label
        
        NSLayoutConstraint.activate([
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4), // 4pt from bottom
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func setLabel(_ text: String) {
        titleLabel.stringValue = text
    }
}
