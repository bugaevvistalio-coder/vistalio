//
//  Double+Utils.swift
//  Vistalio
//
//  Created by Julia Konkova on 11.11.2026.
//

import Foundation

extension Double {

    func formatToMaxDecimals(_ decimals: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = decimals
        formatter.minimumFractionDigits = 0 
        
        // Гарантируем, что разделителем всегда будет точка (если нужно для API)
        // Если нужно подстраиваться под язык телефона, просто удалите строку ниже
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
