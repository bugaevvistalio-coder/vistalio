//
//  VideoHelper.swift
//  Vistalio
//
//  Created by Julia Konkova on 14.07.2026.
//

import AVFoundation
import UIKit

func createVideoSnapshot(from url: URL) -> UIImage? {
    let asset = AVAsset(url: url)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    
    // Prevents rotated or stretched thumbnails
    imageGenerator.appliesPreferredTrackTransform = true
    
    // Set time to the first second
    let time = CMTime(seconds: 0.0, preferredTimescale: 60)
    
    do {
        let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
        return UIImage(cgImage: cgImage)
    } catch {
        print("Error generating snapshot: \(error.localizedDescription)")
        return nil
    }
}
