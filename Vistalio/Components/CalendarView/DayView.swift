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
            circleView.borderWidth = isToday ? 2 : 0
            update()
        }
    }
    
    var isSelected: Bool = false {
        didSet {
            update()
        }
    }
    
    var isAvailable: Bool = true {
        didSet {
            update()
        }
    }
    
    private func update() {
        if isSelected {
            circleView.backgroundColor = isToday ? .highlightBlue : .darkGrey
            dayLabel.textColor = .white
        } else {
            circleView.backgroundColor = .clear
            dayLabel.textColor = isAvailable ? .textGrey60 : .textGrey10
        }
    }
}
