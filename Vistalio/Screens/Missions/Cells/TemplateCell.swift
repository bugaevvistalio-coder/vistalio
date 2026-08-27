//
//  TemplateCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 21.04.2026.
//

import UIKit
import Kingfisher

class TemplateCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var roundedView: RoundedView!
    @IBOutlet weak var missionImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var emotionsCollectionView: UICollectionView!
    
    @IBOutlet weak var collectionViewGradientLeft: UIView!
    @IBOutlet weak var collectionViewGradientRight: UIView!
    
    @IBOutlet weak var badgeAge: UIView!
    @IBOutlet weak var badgeHours: UIView!
    @IBOutlet weak var badgeAgeImageView: UIImageView!
    @IBOutlet weak var badgeAgeLabel: UILabel!
    @IBOutlet weak var badgeHoursLabel: UILabel!
    
    @IBOutlet weak var eyeButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionViewGradientLeft.setGradientLayer(colors: [.white, .white.withAlphaComponent(0.01)], startPoint: CGPoint(x: 0.0, y: 0.5), endPoint: CGPoint(x: 1.0, y: 0.5), cornerRadius: 0)
        collectionViewGradientRight.setGradientLayer(colors: [.white, .white.withAlphaComponent(0.01)], startPoint: CGPoint(x: 1.0, y: 0.5), endPoint: CGPoint(x: 0.0, y: 0.5), cornerRadius: 0)
        badgeAgeLabel.transform = CGAffineTransform(rotationAngle: .pi * 11 / 180)
        badgeHoursLabel.transform = CGAffineTransform(rotationAngle: .pi * 11 / 180)
    }
    
    var template: MissionTemplate! {
        didSet {
            if let url = URL(string: template.cover) {
                missionImageView.loadFromUrl(url) { [weak self] in
                    return self?.template.cover
                }
            }
            nameLabel.text = template.name
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14, weight: .semibold), .foregroundColor: UIColor.textGrey60, .paragraphStyle: paragraphStyle]
            descriptionLabel.attributedText = NSAttributedString(string: template.shortDescription, attributes: attributes)
            
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
            
            eyeButton.setImage(template.hiddenAt != nil ? .eyeOn : .eyeOff, for: .normal)
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        roundedView.alpha = highlighted ? 0.5 : 1
    }
    
    @IBAction func eyeButtonTapped(_ sender: Any) {
        if template.hiddenAt != nil {
            parentViewController?.openShowMissionTemplate(template) {
                (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Миссия убрана из скрытых")
            }
        } else {
            parentViewController?.openHideMissionTemplate(template) {
                (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Миссия скрыта")
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
