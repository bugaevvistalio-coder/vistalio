//
//  VideoHelper.swift
//  Vistalio
//
//  Created by Julia Konkova on 14.07.2026.
//

import AVFoundation
import UIKit
import PhotosUI

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

func processPickerResults(_ results: [PHPickerResult], folder: String) -> [MediaData] {
    var media = [MediaData]()

    for result in results {
        let provider = result.itemProvider
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            
            let m = MediaData(type: "video", image: nil, path: nil)
            media.append(m)
            
            m.progress = provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                if let url = url {
                    FilesHelper().createFolder(folder)
                    
                    let path = "\(folder)/\(FilesHelper().createFilename(ext: url.pathExtension))"
                    let destinationURL = FilesHelper().buildFileUrl(path: path)
                    
                    do {
                        try FileManager.default.copyItem(at: url, to: destinationURL)
                        
                        m.loadedPath = path
                        m.loadedImage = createVideoSnapshot(from: destinationURL)
                    } catch {
                        print("File copy error: \(error)")
                    }
                }
            }
        } else if provider.canLoadObject(ofClass: UIImage.self) {
            let m = MediaData(type: "image", image: nil, path: nil)
            media.append(m)
            
            provider.loadObject(ofClass: UIImage.self) { (image, error) in
                m.loadedImage = image as? UIImage
            }
        }
    }
    
    return media
}

func processCameraResults(info: [UIImagePickerController.InfoKey : Any], folder: String, onMediaReady: @escaping (MediaData) -> ()) {
    let mediaType = info[.mediaType] as! String
    if mediaType == "public.image" {
        if let image = info[.originalImage] as? UIImage {
            onMediaReady(MediaData(type: "image", image: image, path: nil))
        }
    } else if mediaType == "public.movie" {
        if let videoURL = info[.mediaURL] as? URL {
            if let snapshot = createVideoSnapshot(from: videoURL) {
                FilesHelper().createFolder(folder)
                let path = "\(folder)/\(FilesHelper().createFilename(ext: videoURL.pathExtension))"
                let destinationURL = FilesHelper().buildFileUrl(path: path)
                print("Save camera video \(path)")
                do {
                    try FileManager.default.copyItem(at: videoURL, to: destinationURL)
                } catch {
                    print("File copy error: \(error)")
                }
                onMediaReady(MediaData(type: "video", image: snapshot, path: path))
            }
        }
    }
}
