//
//  UITextView+Utils.swift
//  Vistalio
//
//  Created by Julia Konkova on 17.08.2026.
//

import UIKit

extension UITextView {
    func highlightLinks() {
        guard let currentText = self.text, !currentText.isEmpty else { return }
        
        // 1. Сохраняем текущую позицию курсора, чтобы он не прыгал в конец текста
        let selectedRange = self.selectedRange
        
        // 2. Создаем изменяемую строку на основе текущего шрифта и цвета
        let attributedString = NSMutableAttributedString(string: currentText)
        let fullRange = NSRange(location: 0, length: currentText.utf16.count)
        
        // Задаем базовый стиль для всего текста (чтобы сбросить старые ссылки)
        attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: fullRange)
        attributedString.addAttribute(.font, value: self.font!, range: fullRange)
        
        // 3. Используем NSDataDetector для поиска ссылок в тексте
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let matches = detector.matches(in: currentText, options: [], range: fullRange)
            
            for match in matches {
                guard let urlRange = match.range as NSRange? else { continue }
                print("URL range \(urlRange)")
                attributedString.addAttribute(.foregroundColor, value: UIColor.highlightBlue, range: urlRange)
            }
        }
                
        attributedText = attributedString
        self.selectedRange = selectedRange
    }
}
