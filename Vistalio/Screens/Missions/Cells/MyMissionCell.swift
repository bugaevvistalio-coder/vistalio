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
    
    var mission: Mission! {
        didSet {
            nameLabel.text = mission.name
            
            if let path = mission.photoPath {
                coverImageView.loadFromPath(path) { [weak self] in
                    return self?.mission.photoPath
                }
            } else if let categoryName = mission.category, let category = MissionCategory(rawValue: categoryName) {
                coverImageView.image = UIImage(named: category.coverName)
            } else {
                coverImageView.image = nil
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            super.isSelected = isSelected
            roundedView.backgroundColor = isHighlighted ? .textGrey20 : .white
        }
    }
}
