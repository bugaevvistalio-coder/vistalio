//
//  CoverCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 29.03.2026.
//

import UIKit

class CoverCell: UICollectionViewCell {
    
    @IBOutlet weak var coverImageView: RoundedImageView!
    @IBOutlet weak var radioImageView: UIImageView!
    
    private lazy var longGestureRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
    }()
    
    var onLongGesture: ((UIImage, CGRect) -> ())?
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                radioImageView.image = UIImage.radioOn
                coverImageView.borderWidth = 3
            } else {
                radioImageView.image = UIImage.radioOff
                coverImageView.borderWidth = 0
            }
        }
    }
    
    var image: UIImage? {
        didSet {
            coverImageView.image = image
            coverImageView.removeGestureRecognizer(longGestureRecognizer)
        }
    }
    
    var path: String? {
        didSet {
            if let path = path {
                let currentPath = path
                coverImageView.loadFromPath(path) {
                    return currentPath
                }
            }
            if !(coverImageView.gestureRecognizers?.contains(longGestureRecognizer) ?? false) {
                coverImageView.addGestureRecognizer(longGestureRecognizer)
            }
        }
    }
    
    @objc private func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            if let origin = contentView.superview?.convert(contentView.frame.origin, to: nil) {
                onLongGesture?(contentView.toImage(rect: contentView.bounds), CGRect(origin: origin, size: contentView.frame.size))
            }
        }
    }
}
