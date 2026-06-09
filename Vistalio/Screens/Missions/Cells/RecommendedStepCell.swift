//
//  RecommendedStepCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 08.05.2026.
//

import UIKit

class RecommendedStepCell: UITableViewCell {
    
    @IBOutlet weak var roundedView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var addControl: UIControl!
    @IBOutlet weak var checkImageView: UIImageView!
    
    var onStepTapped: (() -> ())?
    var onStepAdded: ((MissionStep) -> ())?
    var onLongGesture: ((UIImage, CGRect) -> ())?
    
    private lazy var longGestureRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        addControl.setGradientLayer(colors: [UIColor(hex: "#F0F6FF"), UIColor(hex: "#EAF0FC"), UIColor(hex: "#E8EFFC")], locations: [0.0, 0.25, 0.9], cornerRadius: 13)
        addControl.setShadow(offset: CGSize(width: 0, height: 0), radius: 7, cornerRadius: 13, shadowOpacity: 0.09)
        addControl.layer.borderWidth = 1
        addControl.layer.borderColor = UIColor.textGrey10.cgColor
    }
    
    var step: MissionStep! {
        didSet {
            nameLabel.text = step.name
            
            descriptionLabel.text = step.expanded ? step.text : step.shortText
            descriptionLabel.numberOfLines = step.expanded ? 0 : 2
            
            if !(roundedView.gestureRecognizers?.contains(longGestureRecognizer) ?? false) {
                roundedView.addGestureRecognizer(longGestureRecognizer)
            }
            if step.addedDate == nil {
                roundedView.alpha = 1
                checkImageView.alpha = 0
            } else {
                roundedView.alpha = 0
                checkImageView.alpha = 1
            }
        }
    }
    
    func animateAddStep(completion: @escaping () -> ()) {
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.roundedView.alpha = 0
            self?.checkImageView.alpha = 1
        } completion: { _ in
            completion()
        }
    }
    
    @IBAction func tapped(_ sender: Any) {
        if step.text != nil {
            step.expanded = !step.expanded
            descriptionLabel.text = step.expanded ? step.text : step.shortText
            descriptionLabel.numberOfLines = step.expanded ? 0 : 2
            onStepTapped?()
        }
    }
    
    @IBAction func addTapped(_ sender: Any) {
        CoreDataStack.shared.performAndWait { [unowned self] _ in
            self.step.addedDate = Date()
            self.step.hidden = false
            self.step.sortOrder = self.step.block.mission.maxSortOrder + 1
        }
        let step = step!
        animateAddStep() { [weak self] in
            if let `self` = self, self.step.id == step.id {
                self.onStepAdded?(step)
            }
        }
    }
    
    @objc private func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            if let origin = roundedView.superview?.convert(roundedView.frame.origin, to: nil) {
                onLongGesture?(roundedView.toImage(rect: roundedView.bounds), CGRect(origin: origin, size: roundedView.frame.size))
            }
        }
    }
}
