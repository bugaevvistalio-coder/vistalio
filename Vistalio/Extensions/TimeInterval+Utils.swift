//
//  TimeInterval+Utils.swift
//  Vistalio
//
//  Created by Julia Konkova on 17.11.2026.
//

import Foundation

extension TimeInterval {
    
    var formattedMSS: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
