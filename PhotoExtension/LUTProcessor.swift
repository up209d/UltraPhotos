//
//  LUTProcessor.swift
//  UltraPhotos
//
//  Created by Duc Duong on 4/9/2025.
//


import CoreImage

class LUTProcessor {
    let context = CIContext()

    func apply3DLUT(to image: CIImage, lutImage: CIImage, dimension: Int) -> CIImage? {
        guard let filter = CIFilter(name: "CIColorCube") else { return nil }
        
        let cubeData = createCubeData(from: lutImage, dimension: dimension)
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(dimension, forKey: "inputCubeDimension")
        filter.setValue(cubeData, forKey: "inputCubeData")
        
        return filter.outputImage
    }

    private func createCubeData(from lutImage: CIImage, dimension: Int) -> Data {
        // TODO: implement LUT → cube data conversion
        // For testing, return identity LUT (no change)
        let cubeSize = dimension * dimension * dimension * 4
        return Data(count: cubeSize * MemoryLayout<Float>.size)
    }
}
