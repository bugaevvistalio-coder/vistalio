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
    
    var image: UIImage! {
        didSet {
            coverImageView.image = image
        }
    }
}
