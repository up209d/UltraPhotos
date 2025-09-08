//
//  LUTThumbnail.swift
//  UltraPhotos
//
//  Created by Duc Duong on 7/9/2025.
//

import Cocoa

class LUTThumbnail: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("LUTThumbnail")
    private var label: NSTextField!
    private var key: String!
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
        self.label = NSTextField(labelWithString: "") // non-editable
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.alignment = .center
        self.label.textColor = .white
        self.label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        
        // Add shadow
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.7)
        shadow.shadowBlurRadius = 3
        shadow.shadowOffset = NSSize(width: 1, height: -1)
        self.label.shadow = shadow
        
        view.addSubview(self.label)
        
        NSLayoutConstraint.activate([
            self.label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4), // 4pt from bottom
            self.label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func setImage(_ image: NSImage) {
        self.imageView?.image = image
    }
    
    func setKey(_ key: String) {
        self.key = key
    }
    
    func setLabel(_ text: String) {
        self.label.stringValue = text
    }
    
    func setSelected(selected: Bool) {
        self.isSelected = selected
        if (selected) {
            self.label.textColor = .yellow
        } else {
            self.label.textColor = .white
        }
    }
}
