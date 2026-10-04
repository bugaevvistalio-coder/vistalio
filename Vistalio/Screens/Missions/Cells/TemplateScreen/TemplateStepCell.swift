//
//  TemplateStepCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 24.04.2026.
//

import UIKit

class TemplateStepCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    private var step: TemplateStep!
    
    var onStepTapped: (() -> ())?
    
    func setStep(_ step: TemplateStep, mission: MissionContents) {
        nameLabel.text = step.getFullName(mission: mission)
        if let description = step.description {
            descriptionLabel.text = (step.expanded ?? false) ? description : step.shortDescription
            descriptionLabel.isHidden = false
        } else {
            descriptionLabel.isHidden = true
        }
    }
    
    @IBAction func stepTapped(_ sender: Any) {
        if step.description != nil {
            step.expanded = !(step.expanded ?? false)
            descriptionLabel.text = step.expanded! ? step.description : step.shortDescription
            descriptionLabel.numberOfLines = (step.expanded ?? false) ? 0 : 2
            onStepTapped?()
        }
    }
}
