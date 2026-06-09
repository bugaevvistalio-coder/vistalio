//
//  Date+Utils.swift
//  Vistalio
//
//  Created by Julia Konkova on 08.06.2026.
//

import Foundation

extension Date {
    
    var formatted1: String {
        var string = ""
        let calendar = Calendar.current
        if calendar.isDate(self, equalTo: Date(), toGranularity: .day) {
            string = "Сегодня, "
        } else if calendar.isDate(self, equalTo: Date().addingTimeInterval(24 * 60 * 60), toGranularity: .day) {
            string = "Завтра, "
        } else if calendar.isDate(self, equalTo: Date().addingTimeInterval(-24 * 60 * 60), toGranularity: .day) {
            string = "Вчера, "
        }
        
        let df = DateFormatter()
        df.dateFormat = string.isEmpty ? "d MMM yyyy" : "d MMM"
        df.locale = Locale(identifier: "ru_RU")
        return string + df.string(from: self).replacingOccurrences(of: ".", with: "")
    }
    
    var startOfMonth: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: self))!
    }
    
    var startOfDay: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month, .day], from: self))!
    }
    
    func isSameDay(_ date: Date) -> Bool {
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .day)
    }
}
