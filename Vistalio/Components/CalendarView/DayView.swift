//
//  DayView.swift
//  Vistalio
//
//  Created by Julia Konkova on 07.06.2026.
//

import UIKit

class DayView: UIView {
    
    @IBOutlet private weak var dayLabel: UILabel!
    @IBOutlet private weak var circleView: RoundedView!
    @IBOutlet private weak var checkImageView: UIImageView!
    
    private var view: UIView!
    
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
    
    private func setup() {
        checkImageView.isHidden = true
    }
    
    var day: Int? {
        didSet {
            if let day = day {
                dayLabel.text = "\(day)"
                circleView.isHidden = false
            } else {
                dayLabel.text = ""
                circleView.isHidden = true
            }
        }
    }
    
    var isToday: Bool = false {
        didSet {
            updateBorder()
            updateCheckmark()
        }
    }
    
    var isSelected: Bool = false {
        didSet {
            updateBackground()
            updateBorder()
            updateCheckmark()
        }
    }
    
    var isAvailable: Bool = true {
        didSet {
            updateBackground()
            updateBorder()
        }
    }
    
    var stepDate: CalendarStepDate? {
        didSet {
            displayTodayBorder = false
            updateBorder()
            checkImageView.isHidden = !(stepDate?.done ?? false)
        }
    }
    
    var displayTodayBorder = true
    
    private func updateBorder() {
        if isSelected {
            circleView.removeDashedBorder()
            circleView.borderWidth = 0
        } else if let stepDate = stepDate {
            if stepDate.date > Date().startOfDay {
                let color = isAvailable ? UIColor.textGrey30 : .textGrey10
                circleView.addDashedBorder(color: color, lineWidth: 2, dashPattern: [3, 3], cornerRadius: 16, fixedBounds: CGRect(x: 0, y: 0, width: 32, height: 32))
            } else {
                circleView.removeDashedBorder()
                circleView.borderWidth = 1
                let color = isToday ? UIColor.highlightBlue : .darkGrey
                circleView.borderColor = isAvailable ? color : color.withAlphaComponent(0.3)
            }
        } else {
            circleView.removeDashedBorder()
            circleView.borderWidth = isToday && displayTodayBorder ? 2 : 0
        }
    }
    
    private func updateBackground() {
        if isSelected {
            circleView.backgroundColor = isToday ? .highlightBlue : .darkGrey
            dayLabel.textColor = .white
        } else {
            circleView.backgroundColor = .clear
            dayLabel.textColor = isAvailable ? (isToday ? .highlightBlue : .textGrey60) : .textGrey10
        }
    }
    
    private func updateCheckmark() {
        checkImageView.tintColor = isSelected ? .white : isToday ? .highlightBlue : .textGrey60
    }
}
