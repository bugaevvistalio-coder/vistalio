//
//  MyMissionCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 05.04.2026.
//

import UIKit
import Kingfisher

class MyMissionCell: UICollectionViewCell {
    
    @IBOutlet weak var roundedView: RoundedView!
    @IBOutlet weak var coverImageView: RoundedImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var radioImageView: UIImageView?
    
    private var longGestureRecognizer: UILongPressGestureRecognizer?
    private var onLongGesture: ((UIImage, CGRect) -> ())?
    
    var mission: Mission! {
        didSet {
            nameLabel.text = mission.name
            
            if let path = mission.photoPath {
                if path.starts(with: "http") {
                    if let url = URL(string: path) {
                        coverImageView.loadFromUrl(url) { [weak self] in
                            return self?.mission.photoPath
                        }
                    }
                } else {
                    coverImageView.loadFromPath(path) { [weak self] in
                        return self?.mission.photoPath
                    }
                }
            } else if let categoryName = mission.category, let category = MissionCategory(rawValue: categoryName) {
                coverImageView.image = UIImage(named: category.coverName)
            } else {
                coverImageView.image = nil
            }
        }
    }
    
//    override var isHighlighted: Bool {
//        didSet {
//            super.isHighlighted = isHighlighted
//            roundedView.backgroundColor = isHighlighted ? .textGrey20 : .white
//        }
//    }
    
    func addLongGesture(onLongGesture: ((UIImage, CGRect) -> ())?) {
        if longGestureRecognizer == nil {
            longGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
            roundedView.addGestureRecognizer(longGestureRecognizer!)
        }
        self.onLongGesture = onLongGesture
    }
    
    @objc private func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            if let origin = roundedView.superview?.convert(roundedView.frame.origin, to: nil) {
                roundedView.backgroundColor = .white
                onLongGesture?(roundedView.toImage(rect: roundedView.bounds), CGRect(origin: origin, size: roundedView.frame.size))
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if let radioImageView = radioImageView {
                if isSelected {
                    radioImageView.image = UIImage.radioOn
                    roundedView.borderWidth = 3
                } else {
                    radioImageView.image = UIImage.radioOff
                    roundedView.borderWidth = 0
                }
            }
        }
    }
}
