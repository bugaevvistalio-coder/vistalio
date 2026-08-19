//
//  NoteToMissionCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 19.07.2026.
//

import UIKit

class NoteToMissionCell: UITableViewCell {
    
    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var innerView: UIView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    
    @IBOutlet weak var radioImageView: UIImageView!
    
    var onTapped: ((Mission) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        outerView.layer.cornerRadius = 30
        outerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        innerView.setShadow(offset: CGSize(width: 0, height: 1), radius: 2, cornerRadius: 19, shadowOpacity: 0.22)
    }
    
    var mission: Mission! {
        didSet {
            if oldValue?.objectID == mission.objectID {
                return
            }
            nameLabel.text = mission.name
            coverImageView.displayMissionCover(mission: mission)
            
            let screenW = UIScreen.main.bounds.width
            let height = max(mission.name?.height(withWidth: screenW - 120, font: nameLabel.font) ?? 0, 24) + 16
            innerView.setGradientLayer(colors: [UIColor(hex: "#F0F6FF"), UIColor(hex: "#EAF0FC"), UIColor(hex: "#E8EFFC")], locations: [0.0, 0.25, 0.9], cornerRadius: 19, bounds: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: screenW - 40, height: height)))
        }
    }
    
    var isMissionSelected: Bool = false {
        didSet {
            radioImageView.image = isMissionSelected ? .radioOn1 : .radioOff1
        }
    }
    
    @IBAction func tapped(_ sender: Any) {
        radioImageView.image = .radioOn1
        onTapped?(mission)
    }
}
