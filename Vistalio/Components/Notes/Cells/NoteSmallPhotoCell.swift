//
//  NoteSmallPhotoCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 15.07.2026.
//

import UIKit

class NoteSmallPhotoCell: NotePhotoCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        roundedView.setShadow(offset: CGSize(width: 0, height: 0), radius: 3, cornerRadius: 14, shadowOpacity: 0.15, bounds: CGRect(x: 0, y: 0, width: 58, height: 58))
    }
}
