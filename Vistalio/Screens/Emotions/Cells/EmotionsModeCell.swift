//
//  EmotionsModeCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 06.07.2026.
//

import UIKit

class EmotionsModeCell: UICollectionViewCell {
    
    @IBOutlet weak var control: UIControl!
    @IBOutlet weak var chevronImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var onSwitchMode: (() -> ())?
    
    private var showAll = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        control.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 24, shadowOpacity: 0.09)
    }
    
    @IBAction func controlTapped(_ sender: Any) {
        onSwitchMode?()
        showAll = !showAll
        
        if showAll {
            chevronImageView.transform = CGAffineTransform(rotationAngle: .pi)
            label.text = "Свернуть все эмоции"
        } else {
            chevronImageView.transform = CGAffineTransform(rotationAngle: 0)
            label.text = "Все эмоции"
        }
    }
}
