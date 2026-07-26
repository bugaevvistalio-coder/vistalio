//
//  NoteToStepCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 19.07.2026.
//

import UIKit

class NoteToStepCell: UITableViewCell {
    
    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var radioImageView: UIImageView!
    
    var onTapped: ((MissionStep) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        outerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
    
    var step: MissionStep! {
        didSet {
            nameLabel.text = step.name
        }
    }
    
    var isLastStep: Bool = false {
        didSet {
            outerView.layer.cornerRadius = isLastStep ? 30 : 0
        }
    }
    
    var isStepSelected: Bool = false {
        didSet {
            radioImageView.image = isStepSelected ? .radioOn1 : .radioOff1
        }
    }
    
    @IBAction func tapped(_ sender: Any) {
        radioImageView.image = .radioOn1
        onTapped?(step)
    }
}
