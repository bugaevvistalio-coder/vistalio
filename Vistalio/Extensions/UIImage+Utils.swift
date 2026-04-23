//
//  UIImage+Utils.swift
//  Vistalio
//
//  Created by Julia Konkova on 05.04.2026.
//

import UIKit

extension UIImage {
    
    @discardableResult
    func saveToDocuments(directory: String? = nil) -> String? {
        if let imageData = resized().jpegData(compressionQuality: 0.5) {
            return FilesHelper().saveToFile(data: imageData, directory: directory)
        }
        print("ERROR!!! Failed to save photo!!!")
        return nil
    }
    
    func resized() -> UIImage {
        let minSide = min(size.width, size.height)
        var newSide = minSide
        var times: CGFloat = 1
        while newSide > 1000 {
            times = times + 1
            newSide = minSide / times
        }
        let size = (minSide == size.width) ? CGSize(width: newSide, height: size.height/times) : CGSize(width: size.width/times, height: newSide)
        return scaledTo(size: size)
    }
    
    func scaledTo(numberOfBytes: Int, compressionQuality: CGFloat) -> Data? {
        var imageData = jpegData(compressionQuality: compressionQuality)
        var factor = 1.0;
        let adjustment = 1.0 / sqrt(2.0);  // or use 0.8 or whatever you want
        let size = self.size;
        var currentSize = size;
        var currentImage = self;
        
        while (imageData != nil && imageData!.count >= numberOfBytes) {
            factor = adjustment * factor;
            currentSize = CGSize(width: round(Double(size.width) * factor), height: round(Double(size.height) * factor))
            currentImage = scaledTo(size: currentSize)
            imageData = currentImage.jpegData(compressionQuality: compressionQuality)
        }
        
        return imageData
    }
    
    func scaledTo(size:CGSize) -> UIImage {
        
        guard let cgImage = self.cgImage else {
            return self
        }
        
        let bitsPerComponent = cgImage.bitsPerComponent
        let bytesPerRow = cgImage.bytesPerRow
        let colorSpace = cgImage.colorSpace!
        let bitmapInfo = cgImage.bitmapInfo
        let correctedSize = ((cgImage.width > cgImage.height) != (self.size.width > self.size.height)) ? CGSize(width: size.height, height: size.width) : size
        
        guard let context = CGContext(data: nil, width: Int(correctedSize.width), height: Int(correctedSize.height), bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return self
        }
        context.interpolationQuality = CGInterpolationQuality.high
        
        context.draw(cgImage, in: CGRect(origin: .zero, size: correctedSize), byTiling: false)
        
        let scaledImage = context.makeImage().flatMap { UIImage(cgImage: $0, scale: self.scale, orientation: self.imageOrientation) }
        return scaledImage ?? self
    }
    
    func cropped(to rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage?.cropping(to: rect) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
    }
}
