//
//  NotePhotoCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 13.07.2026.
//

import UIKit
import Kingfisher

class NoteBiggerPhotoCell: NotePhotoCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        roundedView.setShadow(offset: CGSize(width: 0, height: 0), radius: 8, cornerRadius: 29, shadowOpacity: 0.1)
        roundedView.setGradientLayer(colors: [UIColor(hex: "#F0F6FF"), UIColor(hex: "#EAF0FC"), UIColor(hex: "#E8EFFC")], locations: [0.0, 0.25, 0.9], cornerRadius: 26, bounds: CGRect(origin: CGPoint(x: 6, y: 6), size: CGSize(width: 104, height: 104)))
    }
    
}
