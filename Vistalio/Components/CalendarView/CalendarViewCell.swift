//
//  CalendarViewCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 07.06.2026.
//

import UIKit

struct CalendarStepDate {
    let date: Date
    let done: Bool
    let available: Bool
}

class CalendarViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var vStackView: UIStackView!
    
    private var dayViews = [DayView]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        for (i, hStackView) in vStackView.arrangedSubviews.enumerated() {
            if i > 0 {
                dayViews.append(contentsOf: (hStackView as! UIStackView).arrangedSubviews.map { $0 as! DayView })
            }
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(calendarTapped))
        vStackView.addGestureRecognizer(tapGesture)
    }
    
    var month: Date! {
        didSet {
            let calendar = Calendar.current
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
            let weekdayNumber = calendar.component(.weekday, from: startOfMonth)
            let offset = weekdayNumber == 1 ? 6 : (weekdayNumber - 2)
            
            var todayDayNumber = -1
            if calendar.isDate(Date(), equalTo: startOfMonth, toGranularity: .month) {
                todayDayNumber = calendar.component(.day, from: Date())
            }
            
            var selectedDayNumber = -1
            if let selectedDate = selectedDate, calendar.isDate(selectedDate, equalTo: startOfMonth, toGranularity: .month) {
                selectedDayNumber = calendar.component(.day, from: selectedDate)
            }
            
            let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
            let numberOfDays = range.count
            
            if offset > 0 {
                for i in 0..<offset {
                    dayViews[i].day = nil
                }
            }
            
            for i in 0..<numberOfDays {
                let dv = dayViews[i+offset]
                dv.day = i+1
                dv.isToday = (todayDayNumber == i+1)
                dv.isSelected = (selectedDayNumber == i+1)
            }
            
            if offset + numberOfDays < 42 {
                for i in (offset + numberOfDays)..<42 {
                    dayViews[i].day = nil
                }
            }
        }
    }
    
    var selectedDate: Date? {
        didSet {
            let dayNumber = getDayNumber(selectedDate)
            for i in 0..<42 {
                let dv = dayViews[i]
                dv.isSelected = (dv.day == dayNumber)
            }
        }
    }
    
    var minDate: Date? {
        didSet {
            updateAvailable()
        }
    }
    
    var maxDate: Date? {
        didSet {
            updateAvailable()
        }
    }
    
    var stepDates: [CalendarStepDate]? {
        didSet {
            if let dates = stepDates {
                var dvIndex = 0
                for sd in dates {
                    let dayNumber = getDayNumber(sd.date)
                    for i in dvIndex..<dayViews.count {
                        let dv = dayViews[i]
                        if dv.day == dayNumber {
                            dv.stepDate = sd
                            dv.isAvailable = sd.available
                            dvIndex = i + 1
                            break
                        } else {
                            dv.stepDate = nil
                            dv.isAvailable = false
                        }
                    }
                }
                if dvIndex < dayViews.count {
                    for i in dvIndex..<dayViews.count {
                        let dv = dayViews[i]
                        dv.stepDate = nil
                        dv.isAvailable = false
                    }
                }
            }
        }
    }
    
    private func updateAvailable() {
        let minDate = minDate?.startOfDay ?? Date.distantPast
        let maxDate = maxDate?.startOfDay ?? Date.distantFuture
        let calendar = Calendar.current
        let startOfMonth = month.startOfMonth
        
        for i in 0..<42 {
            let dv = dayViews[i]
            if let day = dv.day {
                let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)!
                dv.isAvailable = date >= minDate && date <= maxDate
            }
        }
    }
    
    private func getDayNumber(_ date: Date?) -> Int {
        let calendar = Calendar.current
        let startOfMonth = month.startOfMonth
        var dayNumber = -1
        
        if let date = date {
            let isSameMonthAndYear = calendar.isDate(date, equalTo: startOfMonth, toGranularity: .month)
            if isSameMonthAndYear {
                dayNumber = calendar.component(.day, from: date)
            }
        }
        return dayNumber
    }
    
    var onDateSelected: ((Date) -> ())?
    
    @objc func calendarTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: gesture.view)
        let column = Int(point.x) / 40
        let row = Int(point.y) / 40
        if row > 0 && column >= 0 && column < 7 {
            let index = (row - 1) * 7 + column
            let dv = dayViews[index]
            if dv.isAvailable, let day = dv.day {
                let calendar = Calendar.current
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
                selectedDate = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
                onDateSelected?(selectedDate!)
            }
        }
    }
}
