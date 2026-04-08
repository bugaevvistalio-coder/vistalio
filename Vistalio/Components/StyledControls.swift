//
//  StyledControls.swift
//  Vistalio
//
//  Created by Julia Konkova on 28.03.2026.
//

import UIKit

class StyledTextField: UITextField {
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.masksToBounds = true
            layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var leftPadding: Int = 10 {
        didSet {
            setLeftPadding(leftPadding)
        }
    }
    
    @IBInspectable var rightPadding: Int = 10 {
        didSet {
            setRightPadding(rightPadding)
        }
    }
    
    @IBInspectable var customPlaceholder: String? {
        didSet {
            if let str = customPlaceholder {
                attributedPlaceholder = NSAttributedString(string: str, attributes: [NSAttributedString.Key.foregroundColor: UIColor.textGrey20, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .semibold)])
            }
        }
    }
}

class StyledTextView: GrowingTextView {
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.masksToBounds = true
            layer.cornerRadius = cornerRadius
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textContainer.lineFragmentPadding = 0
        textContainerInset = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
    }
}
