//
//  EmotionCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 04.07.2026.
//

import UIKit

class SelectEmotionCell: UICollectionViewCell {
    
    @IBOutlet weak var emotionImageView: UIImageView!
    @IBOutlet weak var emotionImageWidth: NSLayoutConstraint!
    @IBOutlet weak var emotionLabel: UILabel!
    @IBOutlet weak var radioImageView: UIImageView!
    @IBOutlet weak var radioImageWidth: NSLayoutConstraint!
    @IBOutlet weak var radioImageTop: NSLayoutConstraint!
    @IBOutlet weak var radioImageTrailing: NSLayoutConstraint!
    
    @IBOutlet weak var borderView: UIView!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var outerView: UIView!
    
    var onEmotionSelected: ((MissionEmotion, Bool) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        radioImageView.isHidden = true
    }
    
    var emotion: MissionEmotion! {
        didSet {
            let nameAndImage = emotion.nameAndImage
            emotionLabel.text = nameAndImage.0
            emotionImageView.image = nameAndImage.1
        }
    }
    
    var isSmall: Bool = false {
        didSet {
            if isSmall {
                emotionImageWidth.constant = 36
                radioImageWidth.constant = 20
                radioImageTop.constant = 9
                radioImageTrailing.constant = 9
                emotionLabel.font = UIFont.boldSystemFont(ofSize: 9)
            } else {
                emotionImageWidth.constant = 42
                radioImageWidth.constant = 24
                radioImageTop.constant = 11
                radioImageTrailing.constant = 11
                emotionLabel.font = UIFont.boldSystemFont(ofSize: 12)
            }
        }
    }
    
    func updateBorders() {
        let colors = emotion.colors
        var emotionWidth: CGFloat
        var radius: CGFloat
        if isSmall {
            emotionWidth = (UIScreen.main.bounds.width - 29) / 4
            radius = 16
        } else {
            emotionWidth = (UIScreen.main.bounds.width - 26) / 3
            radius = 20
        }
        
        bgView.setGradientLayer(colors: colors.0, startPoint: CGPoint(x: 0.5, y: 0.0), endPoint: CGPoint(x: 0.5, y: 1.0), cornerRadius: radius - 2, bounds: CGRect(x: 0, y: 0, width: emotionWidth - 10, height: emotionWidth - 10))
        borderView.setGradientLayer(colors: colors.1, startPoint: CGPoint(x: 0.5, y: 0.0), endPoint: CGPoint(x: 0.5, y: 1.0), cornerRadius: radius, bounds: CGRect(x: 0, y: 0, width: emotionWidth - 6, height: emotionWidth - 6))
        borderView.setShadow(offset: CGSize(width: 0, height: 1.08), radius: 1.08, cornerRadius: radius, shadowOpacity: 0.12)
        
//        outerView.layer.borderColor = colors.2.cgColor
        outerView.layer.cornerRadius = radius + 2
    }
    
    var isEmotionSelected: Bool = false {
        didSet {
            radioImageView.isHidden = !isEmotionSelected
            if isEmotionSelected {
                outerView.layer.borderColor = UIColor.darkGray.cgColor
            } else {
                outerView.layer.borderColor = emotion.colors.2.cgColor
            }
        }
    }
    
    @IBAction func emotionTapped(_ sender: Any) {
        isEmotionSelected = !isEmotionSelected
        onEmotionSelected?(emotion, isEmotionSelected)
    }
}
