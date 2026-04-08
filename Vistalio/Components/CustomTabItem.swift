//
//  CustomTabItem.swift
//  Vistalio
//
//  Created by Julia Konkova on 20.03.2026.
//

import UIKit

class CustomTabItem: UIControl {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var isTabSelected: Bool = false {
        didSet {
            if isTabSelected {
                imageView.tintColor = UIColor.highlightBlue
                titleLabel.textColor = UIColor.highlightBlue
            } else {
                imageView.tintColor = UIColor.textGrey30
                titleLabel.textColor = UIColor.textGrey30
            }
        }
    }
}
