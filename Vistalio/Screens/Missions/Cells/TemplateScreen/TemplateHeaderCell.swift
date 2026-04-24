//
//  TemplateHeaderCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 23.04.2026.
//

import UIKit

class TemplateHeaderCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var missionImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var emotionsCollectionView: UICollectionView!
    
    @IBOutlet weak var collectionViewGradieintLeft: UIView!
    @IBOutlet weak var collectionViewGradieintRight: UIView!
    
    @IBOutlet weak var badgeAge: UIView!
    @IBOutlet weak var badgeHours: UIView!
    @IBOutlet weak var badgeAgeImageView: UIImageView!
    @IBOutlet weak var badgeAgeLabel: UILabel!
    @IBOutlet weak var badgeHoursLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        bgView.layer.cornerRadius = 30
        bgView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        collectionViewGradieintLeft.setGradientLayer(colors: [.white, .white.withAlphaComponent(0.01)], startPoint: CGPoint(x: 0.0, y: 0.5), endPoint: CGPoint(x: 1.0, y: 0.5), cornerRadius: 0)
        collectionViewGradieintRight.setGradientLayer(colors: [.white, .white.withAlphaComponent(0.01)], startPoint: CGPoint(x: 1.0, y: 0.5), endPoint: CGPoint(x: 0.0, y: 0.5), cornerRadius: 0)
        badgeAgeLabel.transform = CGAffineTransform(rotationAngle: .pi * 11 / 180)
        badgeHoursLabel.transform = CGAffineTransform(rotationAngle: .pi * 11 / 180)
    }
    
    var template: MissionTemplate! {
        didSet {
            if let url = URL(string: template.cover) {
                missionImageView.kf.setImage(with: url)
                nameLabel.text = template.name
                descriptionLabel.text = template.fullDescription
                
                if let minAge = template.minAge {
                    badgeAge.isHidden = false
                    badgeAgeLabel.text = "\(minAge)+"
                    if minAge == 12 {
                        badgeAgeImageView.image = .badgeAge12
                    } else {
                        badgeAgeImageView.image = .badgeAge3
                    }
                } else {
                    badgeAge.isHidden = true
                }
                
                if let maxHours = template.maxHours {
                    badgeHours.isHidden = false
                    badgeHoursLabel.text = "<\(maxHours)ч."
                } else {
                    badgeHours.isHidden = true
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return template.emotions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmotionCell", for: indexPath) as! EmotionCell
        cell.emotion = MissionEmotion(rawValue: template.emotions[indexPath.row]) ?? .joy
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let emotion = MissionEmotion(rawValue: template.emotions[indexPath.row]) ?? .joy
        let textWidth = emotion.nameAndImage.0.width(withHeight: 15, font: UIFont.systemFont(ofSize: 12, weight: .semibold))
        return CGSize(width: 44 + textWidth, height: 32)
    }
}
