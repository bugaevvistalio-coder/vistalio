//
//  NotePhotoCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 13.07.2026.
//

import UIKit
import Kingfisher

class NoteBigPhotoCell: NotePhotoCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        roundedView.setShadow(offset: CGSize(width: 0, height: 0), radius: 6, cornerRadius: 20, shadowOpacity: 0.1)
        roundedView.setGradientLayer(colors: [UIColor(hex: "#F0F6FF"), UIColor(hex: "#EAF0FC"), UIColor(hex: "#E8EFFC")], locations: [0.0, 0.25, 0.9], cornerRadius: 18, bounds: CGRect(origin: CGPoint(x: 4, y: 4), size: CGSize(width: 74, height: 74)))
        progressView?.lineWidth = 4
    }
    
}
