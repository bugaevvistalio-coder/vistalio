//
//  WeekViewCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 14.08.2026.
//

import UIKit

class WeekViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var roundedView: UIView!
    @IBOutlet private weak var weekdayLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    
    var onDateSelected: ((Date) -> ())?
    
    private let formatter = DateFormatter()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        roundedView.setShadow(offset: CGSize(width: 0, height: 0), radius: 3, cornerRadius: 21, shadowOpacity: 0.09, bounds: CGRect(x: 0, y: 0, width: 42, height: 52))
        roundedView.layer.borderColor = UIColor.textGrey30.cgColor
        
        formatter.locale = Locale(identifier: "ru_RU")
    }
    
    var day: Date! {
        didSet {
            formatter.dateFormat = "d"
            dateLabel.text = formatter.string(from: day)

            formatter.dateFormat = "EEE"
            weekdayLabel.text = formatter.string(from: day)
            
            roundedView.layer.borderWidth = day.isSameDay(Date()) ? 2 : 0
        }
    }
    
    var isSelectedDate: Bool = false {
        didSet {
            roundedView.backgroundColor = isSelectedDate ? .highlightBlue : .white
            weekdayLabel.textColor = isSelectedDate ? .white : .textGrey60
            dateLabel.textColor = isSelectedDate ? .white : .black
        }
    }
    
    @IBAction func tapped(_ sender: Any) {
        onDateSelected?(day)
    }
}
