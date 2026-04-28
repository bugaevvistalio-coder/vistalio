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
        let url = FilesHelper().buildFileUrl(path: path)
        loadFromUrl(url, getCurrentPath: getCurrentPath)
    }
    
    func loadFromUrl(_ url: URL, getCurrentPath: @escaping () -> (String?)) {
        
        image = nil
        let imageView = self
        
        KingfisherManager.shared.retrieveImage(with: url) { result in
            print("Last path \(url.lastPathComponent), \(getCurrentPath())")
            var samePath = false
            if url.absoluteString.starts(with: "http") {
                samePath = url.absoluteString == getCurrentPath()
            } else {
                samePath = getCurrentPath()?.hasSuffix(url.lastPathComponent) ?? false
            }
            if samePath {
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
    
    func displayMissionCover(mission: Mission) {
        if let path = mission.photoPath {
            if path.starts(with: "http") {
                if let url = URL(string: path) {
                    loadFromUrl(url) {
                        return mission.photoPath
                    }
                }
            } else {
                loadFromPath(path) {
                    return mission.photoPath
                }
            }
        } else if let categoryName = mission.category, let category = MissionCategory(rawValue: categoryName) {
            image = UIImage(named: category.coverName)
        }
    }
}
