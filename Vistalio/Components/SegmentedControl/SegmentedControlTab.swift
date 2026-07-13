//
//  SegmentedControlTab.swift
//  Vistalio
//
//  Created by Julia Konkova on 06.04.2026.
//

import UIKit

enum TabPosition {
    case left
    case center
    case right
}

class SegmentedControlTab: UIControl {
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var outerView: RoundedView!
    @IBOutlet private weak var mediumView: RoundedView!
    @IBOutlet private weak var innerView: RoundedView!
    @IBOutlet private weak var shadowView: UIView!
    @IBOutlet private weak var questionButton: UIButton!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var questionPlaceholder: UIView!
    
    private var view: UIView!
    
    private var mediumGradientLayer: CAGradientLayer!
    private var innerGradientLayer: CAGradientLayer!
    
    var onSelected: ((SegmentedControlTab) -> ())?
    
    var data: SegmentedTabData? {
        didSet {
            label.text = data?.text
            imageView.image = data?.image
            questionButton.isHidden = (data?.tooltip == nil)
            questionPlaceholder.isHidden = questionButton.isHidden
        }
    }
    
    var position = TabPosition.center {
        didSet {
            switch position {
            case .left:
                innerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            case .right:
                innerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            default:
                innerView.layer.maskedCorners = []
            }
            mediumView.layer.maskedCorners = innerView.layer.maskedCorners
            outerView.layer.maskedCorners = innerView.layer.maskedCorners
            shadowView.layer.maskedCorners = innerView.layer.maskedCorners
        }
    }
    
    var isTabSelected: Bool = false {
        didSet {
            outerView.isHidden = !isTabSelected
            imageView.tintColor = isTabSelected ? .black : .textGrey40
            label.textColor = imageView.tintColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        view = xibSetup()
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        view = xibSetup()
        setup()
    }
    
    func setup() {
        shadowView.setShadow(offset: CGSize(width: 0, height: 2), radius: 2, cornerRadius: 22, shadowOpacity: 0.18)
        stackView.setCustomSpacing(0, after: label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if mediumGradientLayer == nil {
            mediumGradientLayer = CAGradientLayer()
            mediumGradientLayer.colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0.25).cgColor]
            mediumGradientLayer.locations = [0.0, 1.0]
            mediumGradientLayer.frame = mediumView.bounds
            mediumGradientLayer.cornerRadius = mediumView.layer.cornerRadius
            mediumGradientLayer.maskedCorners = mediumView.layer.maskedCorners
            
//            mediumGradientLayer.shadowColor = UIColor.black.cgColor
//            mediumGradientLayer.shadowRadius = 2
//            mediumGradientLayer.shadowOffset = CGSize(width: 0, height: 2)
//            mediumGradientLayer.shadowOpacity = 0.18
            
            mediumView.layer.insertSublayer(mediumGradientLayer, at: 0)
        } else {
            mediumGradientLayer.frame = mediumView.bounds
        }
        
        if innerGradientLayer == nil {
            innerGradientLayer = CAGradientLayer()
            innerGradientLayer.colors = [UIColor(hex: "#F0F6FF").cgColor, UIColor(hex: "#EAF0FC").cgColor, UIColor(hex: "#E8EFFC").cgColor]
            innerGradientLayer.locations = [0.0, 0.25, 0.9]
            innerGradientLayer.frame = innerView.bounds
            innerGradientLayer.cornerRadius = innerView.layer.cornerRadius
            innerGradientLayer.maskedCorners = innerView.layer.maskedCorners
            
            innerView.layer.insertSublayer(innerGradientLayer, at: 0)
        } else {
            innerGradientLayer.frame = innerView.bounds
        }
    }
    
    @IBAction func onTapped(_ sender: Any) {
        onSelected?(self)
    }
    
    @IBAction func questionTapped(_ sender: Any) {

        let menuUnderlayControl = parentViewController!.addMenuUnderlayControl(color: .clear)
        
        let tooltipView = TooltipView()
        tooltipView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(tooltipView)
        
        let location = superview!.convert(frame.origin, to: nil)
        let menuUnderlayLocation = menuUnderlayControl.superview!.convert(menuUnderlayControl.frame.origin, to: nil)
        
        let horizontalConstraint: NSLayoutConstraint
        if position == .right {
            horizontalConstraint = tooltipView.rightAnchor.constraint(equalTo: menuUnderlayControl.rightAnchor, constant: location.x + frame.width + 4 - UIScreen.main.bounds.width)
        } else {
            horizontalConstraint = tooltipView.leftAnchor.constraint(equalTo: menuUnderlayControl.leftAnchor, constant: location.x - 4)
        }
        let constraints = [
            horizontalConstraint,
            tooltipView.topAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: location.y + frame.height + 4 - menuUnderlayLocation.y),
            tooltipView.widthAnchor.constraint(equalToConstant: frame.width + 24)
        ]
        NSLayoutConstraint.activate(constraints)
        
        tooltipView.text = data?.tooltip
    }
}
