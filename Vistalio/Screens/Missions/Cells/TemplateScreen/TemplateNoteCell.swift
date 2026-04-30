//
//  TemplateNoteCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 27.04.2026.
//

import UIKit

class TemplateNoteCell: UICollectionViewCell {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var noteImageView: UIImageView!
    @IBOutlet weak var audioBadge: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        stackView.setCustomSpacing(10, after: noteImageView)
        noteImageView.superview!.setShadow(offset: CGSize(width: 0, height: 0), radius: 4, cornerRadius: 13, shadowOpacity: 0.2)
//        noteImageView.setShadow(offset: CGSize(width: 0, height: 0), radius: 5, cornerRadius: 13, shadowOpacity: 0.2)
        noteImageView.layer.borderColor = UIColor.white.cgColor
        noteImageView.layer.borderWidth = 3
    }
    
    var note: TemplateNote! {
        didSet {
            nameLabel.text = note.name
            if let description = note.shortDescription {
                descriptionLabel.text = description
                descriptionLabel.isHidden = false
            } else {
                descriptionLabel.isHidden = true
            }
            if let image = note.images?.first {
                noteImageView.isHidden = false
                if let url = URL(string: image) {
                    noteImageView.loadFromUrl(url) { [weak self] in
                        return self?.note.images?.first
                    }
                }
            } else {
                noteImageView.isHidden = true
            }
            audioBadge.isHidden = (note.audio == nil)
        }
    }
}
