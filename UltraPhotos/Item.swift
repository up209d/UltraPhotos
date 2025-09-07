//
//  Item.swift
//  UltraPhotos
//
//  Created by Duc Duong on 4/9/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
