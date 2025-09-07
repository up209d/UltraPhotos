//
//  Cache.swift
//  UltraPhotos
//
//  Created by Duc Duong on 7/9/2025.
//

import Cocoa
import Photos
import PhotosUI
import AppKit
import AVFoundation

class CacheItem {
    var name: String
    var cacheKey: String
    var image: NSImage
    init(image: NSImage, name: String, cacheKey: String) {
        self.name = name
        self.cacheKey = cacheKey
        self.image = image
    }
}


class Cache {
    private var cache = [String: CacheItem]()
    
    public func set(key: String, item: CacheItem) -> CacheItem {
        cache[key] = item
        return item
    }
    
    public func get(key: String) -> CacheItem? {
        return cache[key]
    }
    
    public func clearCache() -> Void {
        cache.removeAll()
    }
}
