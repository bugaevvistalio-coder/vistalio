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
    
    @IBOutlet private weak var addNoteLeading: NSLayoutConstraint!
    
    @IBOutlet private weak var emotionsCounterView: UIView!
    @IBOutlet private weak var emotionsCounterLabel: UILabel!
    
    @IBOutlet private weak var emotion1View: EmotionCircleView!
    @IBOutlet private weak var emotion2View: EmotionCircleView!
    @IBOutlet private weak var emotion3View: EmotionCircleView!
    @IBOutlet private weak var emotion4View: EmotionCircleView!
    
    var onLongGesture: ((UIImage, CGRect) -> ())?
    var onOpenStep: ((MissionStep, Date?, Bool) -> ())?
    
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
            if step.hasFrequency {
                dateLabel.superview?.isHidden = false
                lastStepItemDate = step.lastDate
                checkImageView.image = step.isImplementedForDate(lastStepItemDate) ? .checkCircleOn : .checkCircleOff
                addNoteControl.isHidden = false
            } else {
                dateLabel.superview?.isHidden = true
                checkImageView.isHidden = true
                addNoteControl.isHidden = true
            }
            
            displayEmotions()
        }
    }
    
    private var lastStepItemDate: Date? {
        didSet {
            dateLabel.text = lastStepItemDate?.formatted2
            checkImageView.isHidden = lastStepItemDate == nil || step.frequency == StepFrequency.untilDone.rawValue && lastStepItemDate! > Date().startOfDay
        }
    }
    
    private func displayEmotions() {
        let notes = step.notes?.allObjects.map { $0 as! MissionNote }.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) } ?? []
        let emotions = notes.compactMap { $0.emotions?.allObjects.map { $0 as! MissionNoteEmotion }.sorted { $0.date < $1.date }.first }
        let displayedEmotions = emotions.prefix(4)
        
        let views = [emotion4View, emotion3View, emotion2View, emotion1View]
        for i in 0..<views.count {
            let v = views[i]!
            if displayedEmotions.count > i {
                v.emotion = MissionEmotion(rawValue: displayedEmotions[i].emotion)
                v.isHidden = false
            } else {
                v.isHidden = true
            }
        }
        
        let left = notes.count - displayedEmotions.count
        if left > 0 {
            emotionsCounterView.isHidden = false
            if displayedEmotions.count == 4 {
                emotionsCounterLabel.text = "+\(left+1)"
                emotion1View.isHidden = true
            } else if displayedEmotions.count == 0 {
                emotionsCounterLabel.text = "\(left)"
            } else {
                emotionsCounterLabel.text = "+\(left)"
            }
        } else {
            emotionsCounterView.isHidden = true
        }
        
        addNoteLeading.constant = notes.isEmpty ? 0 : -7
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        roundedView.backgroundColor = highlighted ? .textGrey20 : .white
    }
    
    @objc private func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            if let origin = roundedView.superview?.convert(roundedView.frame.origin, to: nil) {
                roundedView.backgroundColor = .white
                DispatchQueue.main.async {
                    self.onLongGesture?(self.roundedView.toImage(rect: self.roundedView.bounds), CGRect(origin: origin, size: self.roundedView.frame.size))
                }
            }
        }
    }
    
    @IBAction func tapped(_ sender: Any) {
        onOpenStep?(step, lastStepItemDate, false)
    }
    
    @IBAction func addNoteTapped(_ sender: Any) {
        onOpenStep?(step, lastStepItemDate, true)
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
