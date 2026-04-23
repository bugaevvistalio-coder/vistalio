//
//  EmotionCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 22.04.2026.
//

import UIKit

class EmotionCell: UICollectionViewCell {
    
    @IBOutlet weak var emotionImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var borderView: UIView!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var outerView: UIView!
    
    var emotion: MissionEmotion! {
        didSet {
            let nameAndImage = emotion.nameAndImage
            let textWidth = nameAndImage.0.width(withHeight: 15, font: UIFont.systemFont(ofSize: 12, weight: .semibold))
            
            let colors = emotion.colors
            bgView.setGradientLayer(colors: colors.0, startPoint: CGPoint(x: 0.5, y: 0.0), endPoint: CGPoint(x: 0.5, y: 1.0), cornerRadius: 13, bounds: CGRect(x: 0, y: 0, width: textWidth + 38, height: 26))
            borderView.setGradientLayer(colors: colors.1, startPoint: CGPoint(x: 0.5, y: 0.0), endPoint: CGPoint(x: 0.5, y: 1.0), cornerRadius: 14, bounds: CGRect(x: 0, y: 0, width: textWidth + 40, height: 28))
            borderView.setShadow(offset: CGSize(width: 0, height: 1.24), radius: 1.24, cornerRadius: 14, shadowOpacity: 0.12)
            
            outerView.layer.cornerRadius = 16
            outerView.layer.borderWidth = 2
            outerView.layer.borderColor = colors.2.cgColor
            
            nameLabel.text = nameAndImage.0
            emotionImageView.image = nameAndImage.1
        }
    }
}
