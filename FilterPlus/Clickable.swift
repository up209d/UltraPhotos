//
//  Clickable.swift
//  UltraPhotos
//
//  Created by Duc Duong on 6/9/2025.
//

import Cocoa

class ClickableNSImageView: NSImageView {
//    var onMouseDown: (() -> Void)?
//    var onMouseUp: (() -> Void)?
//    override func mouseDown(with event: NSEvent) {
//        print("View mouse down")
//        onMouseDown?()  // call custom action immediately
//        // Track mouse until released
//        let windowEvent = window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged])
//        if windowEvent?.type == .leftMouseUp {
//            onMouseUp?()  // call custom action on release
//        }
//    }
//    override func mouseUp(with event: NSEvent) {
//        print("View mouse up")
//        // Fallback: ensure mouse up is called if needed
//        onMouseUp?()
//    }
}

class ClickableNSButton: NSButton {
    var onMouseDown: (() -> Void)?
    var onMouseUp: (() -> Void)?
    
    override func mouseDown(with event: NSEvent) {
        print("Button mouse down")
        self.alphaValue = 0.5
        onMouseDown?()
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseDown(with: event)
        print("Button mouse up")
        self.alphaValue = 1.0
        onMouseUp?()
    }
}

