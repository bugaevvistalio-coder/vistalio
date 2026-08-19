//
//  Helpers.swift
//  Vistalio
//
//  Created by Julia Konkova on 14.07.2026.
//

import UIKit

class MediaData {
    let type: String
    var image: UIImage?
    var path: String?
    
    var progress: Progress? = nil
    var loadedImage: UIImage?
    var loadedPath: String?
    
    var saved = false
    
    var onLoaded: (() -> ())?
    
    init(type: String, image: UIImage?, path: String?) {
        self.type = type
        self.image = image
        self.path = path
    }
    
    func stopLoading() {
        if let progress = progress, !progress.isFinished && !progress.isCancelled {
            progress.cancel()
        }
    }
    
    func share(from viewController: UIViewController) {
        var itemsToShare: [Any] = []
        
        if let url = url {
            itemsToShare = [url]
        } else if let image = image {
            itemsToShare = [image]
        }
        
        let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        viewController.present(activityVC, animated: true, completion: nil)
    }
    
    func removeFile() {
        if let path = path {
            let url = FilesHelper().buildFileUrl(path: path)
            try? FileManager.default.removeItem(at: url)
            print("Media removed \(path)")
        }
    }
    
    var url: URL? {
        if let path = path {
            if path.starts(with: "http") {
                return URL(string: path)
            } else {
                return FilesHelper().buildFileUrl(path: path)
            }
        }
        return nil
    }
}
