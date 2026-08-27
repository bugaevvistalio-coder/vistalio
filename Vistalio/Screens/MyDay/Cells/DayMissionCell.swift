//
//  DayMissionCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 20.08.2026.
//

import UIKit

class DayMissionCell: UITableViewCell {
    
    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var mediumView: UIView!
    @IBOutlet weak var innerView: UIView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    
    @IBOutlet private weak var addStepControl: UIControl?
    @IBOutlet private weak var addStepInnerView: UIView?
    @IBOutlet private weak var stepLabel: UILabel?
    
    var onTapped: ((Mission) -> ())?
    var onAddStep: ((Mission) -> ())?
    var onLongGesture: ((Mission, UIImage, CGRect) -> ())?
    
    var labelWidth: CGFloat = 0
    var innerViewWidth: CGFloat = 0
    
    private lazy var longGestureRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        outerView.layer.cornerRadius = 30
        
        innerView.setShadow(offset: CGSize(width: 0, height: 1), radius: 2, cornerRadius: 19, shadowOpacity: 0.22)
        
        if addStepControl != nil {
            outerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            
            addStepControl?.setShadow(offset: CGSize(width: 0, height: 0), radius: 4, cornerRadius: 16, shadowOpacity: 0.05)
            
            let width = "Шаг".width(withHeight: 26, font: stepLabel!.font) + 32
            addStepInnerView?.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 13, fixedBounds: CGRect(x: 0, y: 0, width: width, height: 26))
        }
    }
    
    var mission: Mission! {
        didSet {
            if oldValue?.name != mission.name {
                nameLabel.text = mission.name
                
                let height = max(mission.name?.height(withWidth: labelWidth, font: nameLabel.font) ?? 0, 24) + 16
                innerView.setGradientLayer(colors: [UIColor(hex: "#F0F6FF"), UIColor(hex: "#EAF0FC"), UIColor(hex: "#E8EFFC")], locations: [0.0, 0.25, 0.9], cornerRadius: 19, bounds: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: innerViewWidth, height: height)))
            }
            if oldValue?.photoPath != mission.photoPath || oldValue?.category != mission.category {
                coverImageView.displayMissionCover(mission: mission)
            }
            
            if !(outerView.gestureRecognizers?.contains(longGestureRecognizer) ?? false) {
                outerView.addGestureRecognizer(longGestureRecognizer)
            }
        }
    }
    
    @IBAction func tapped(_ sender: Any) {
        onTapped?(mission)
        if parentViewController?.sheetViewController != nil {
            let mission = mission!
            parentViewController?.dismiss(animated: false) {
                UIApplication.topViewController()?.openMission(mission)
            }
        } else {
            parentViewController?.openMission(mission)
        }
    }
    
    @IBAction func addStepTapped(_ sender: Any) {
        onAddStep?(mission)
    }
    
    @objc private func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            if let origin = mediumView.superview?.convert(mediumView.frame.origin, to: nil) {
                DispatchQueue.main.async {
                    self.onLongGesture?(self.mission, self.mediumView.toImage(rect: self.mediumView.bounds), CGRect(origin: origin, size: self.mediumView.frame.size))
                }
            }
        }
    }
}
