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
    
    var formatted2: String {
        let calendar = Calendar.current
        if calendar.isDate(self, equalTo: Date(), toGranularity: .day) {
            return "Сегодня"
        } else if calendar.isDate(self, equalTo: Date().addingTimeInterval(24 * 60 * 60), toGranularity: .day) {
            return "Завтра"
        } else if calendar.isDate(self, equalTo: Date().addingTimeInterval(-24 * 60 * 60), toGranularity: .day) {
            return "Вчера"
        }
        
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy"
        return df.string(from: self)
    }
    
    var formatted3: String {
        var string = ""
        let calendar = Calendar.current
        if calendar.isDate(self, equalTo: Date(), toGranularity: .day) {
            return "Сегодня"
        } else if calendar.isDate(self, equalTo: Date().addingTimeInterval(24 * 60 * 60), toGranularity: .day) {
            return "Завтра"
        } else if calendar.isDate(self, equalTo: Date().addingTimeInterval(-24 * 60 * 60), toGranularity: .day) {
            return "Вчера"
        }
        
        let df = DateFormatter()
        df.dateFormat = isSameYear(Date()) ? "d MMM" : "d MMM yyyy"
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
    
    var startOfWeek: Date {
        let calendar = Calendar.current
        if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: self) {
           return weekInterval.start
        }
        return self
    }
    
    func isSameDay(_ date: Date) -> Bool {
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .day)
    }
    
    func isSameYear(_ date: Date) -> Bool {
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .year)
    }
    
    var toDateString: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: self)
    }
}
