//
//  RoundedButton.swift
//  Vistalio
//
//  Created by Julia Konkova on 21.03.2026.
//

import UIKit

class RoundedView: UIView {
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            self.layer.masksToBounds = true
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            self.layer.borderColor = borderColor?.cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let borderColor = borderColor {
            self.layer.borderColor = borderColor.cgColor
        }
    }
}

class RoundedControl: UIControl {
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            self.layer.masksToBounds = true
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            self.layer.borderColor = borderColor?.cgColor
        }
    }
    
    @IBInspectable var highlightOnTap: Bool = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let borderColor = borderColor {
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            super.isHighlighted = isHighlighted
            if highlightOnTap {
                alpha = isHighlighted ? 0.5 : 1
            }
        }
    }
}

class RoundedButton: UIButton {
    
    var onHighlighted: ((Bool) -> ())?
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            self.layer.masksToBounds = true
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            self.layer.borderColor = borderColor?.cgColor
        }
    }
    
    @IBInspectable var normalBackground: UIColor?
    @IBInspectable var highlightedBackground: UIColor?
    @IBInspectable var disabledBackground: UIColor?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let borderColor = borderColor {
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            super.isHighlighted = isHighlighted
            if let normalBackground = normalBackground, let highlightedBackground = highlightedBackground {
                backgroundColor = isHighlighted ? highlightedBackground : normalBackground
            }
            onHighlighted?(isHighlighted)
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            super.isEnabled = isEnabled
            if let normalBackground = normalBackground, let disabledBackground = disabledBackground {
                backgroundColor = isEnabled ? normalBackground : disabledBackground
            }
        }
    }
}

class RoundedImageView: UIImageView {
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            self.layer.masksToBounds = true
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            self.layer.borderColor = borderColor?.cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let borderColor = borderColor {
            self.layer.borderColor = borderColor.cgColor
        }
    }
}
