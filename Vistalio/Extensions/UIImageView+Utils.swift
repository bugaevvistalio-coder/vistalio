//
//  UIImageView+Utils.swift
//  Vistalio
//
//  Created by Julia Konkova on 05.04.2026.
//

import UIKit
import Kingfisher

extension UIImageView {
    
    func loadFromPath(_ path: String, getCurrentPath: @escaping () -> (String?)) {
        
        image = nil
        let url = FilesHelper().buildFileUrl(path: path)
        let imageView = self
        
        KingfisherManager.shared.retrieveImage(with: url) { result in
            if getCurrentPath()?.hasSuffix(url.lastPathComponent) ?? false {
                DispatchQueue.main.async {
                    switch result {
                    case .success(let value):
                        imageView.image = value.image
                    case .failure( _):
                        imageView.image = nil
                    }
                }
            }
        }
    }
}
