//
//  AddedStepCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 10.05.2026.
//

import UIKit

class AddedStepCell: UITableViewCell {
    
    @IBOutlet weak var roundedView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var addNoteControl: UIControl!
    @IBOutlet weak var addNoteInnerView: UIView!
    @IBOutlet weak var noteLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addNoteControl.setShadow(offset: CGSize(width: 0, height: 0), radius: 4, cornerRadius: 16, shadowOpacity: 0.05)
        
        let width = "Заметка".width(withHeight: 26, font: noteLabel.font) + 32
        addNoteInnerView.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 13, fixedBounds: CGRect(x: 0, y: 0, width: width, height: 26))
    }
    
    var step: MissionStep! {
        didSet {
            nameLabel.text = step.name
        }
    }
}
