//
//  AddedStepCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 10.05.2026.
//

import UIKit

class AddedStepCell: UITableViewCell {
    
    @IBOutlet weak var roundedView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var addNoteControl: UIControl!
    @IBOutlet weak var addNoteInnerView: UIView!
    @IBOutlet weak var noteLabel: UILabel!
    
    @IBOutlet weak var checkImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    
    var onLongGesture: ((UIImage, CGRect) -> ())?
    var onOpenStep: ((MissionStep, Date?) -> ())?
    
    private lazy var longGestureRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addNoteControl.setShadow(offset: CGSize(width: 0, height: 0), radius: 4, cornerRadius: 16, shadowOpacity: 0.05)
        
        let width = "Заметка".width(withHeight: 26, font: noteLabel.font) + 32
        addNoteInnerView.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 13, fixedBounds: CGRect(x: 0, y: 0, width: width, height: 26))
        
        let checkTapGesture = UITapGestureRecognizer(target: self, action: #selector(checkImageTapped))
        checkImageView.addGestureRecognizer(checkTapGesture)
    }
    
    var step: MissionStep! {
        didSet {
            nameLabel.text = step.name
            
            if !(roundedView.gestureRecognizers?.contains(longGestureRecognizer) ?? false) {
                roundedView.addGestureRecognizer(longGestureRecognizer)
            }
            
            lastStepItemDate = step.lastDate
            checkImageView.image = step.isImplementedForDate(lastStepItemDate) ? .checkCircleOn : .checkCircleOff
        }
    }
    
    private var lastStepItemDate: Date? {
        didSet {
            dateLabel.text = lastStepItemDate?.formatted2
            checkImageView.isHidden = lastStepItemDate == nil || step.frequency == StepFrequency.untilDone.rawValue && lastStepItemDate! > Date().startOfDay
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        roundedView.backgroundColor = highlighted ? .textGrey20 : .white
    }
    
    @objc private func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            if let origin = roundedView.superview?.convert(roundedView.frame.origin, to: nil) {
                onLongGesture?(roundedView.toImage(rect: roundedView.bounds), CGRect(origin: origin, size: roundedView.frame.size))
            }
        }
    }
    
    @IBAction func tapped(_ sender: Any) {
        onOpenStep?(step, lastStepItemDate)
    }
    
    @objc func checkImageTapped(_ gesture: UITapGestureRecognizer) {
        guard let date = lastStepItemDate else {
            return
        }
        parentViewController?.switchStepImplemented(step, date: date) { [unowned self] checked in
            checkImageView.image = checked ? .checkCircleOn : .checkCircleOff
        }
    }
}
