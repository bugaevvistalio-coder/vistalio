//
//  UILabel+Utils.swift
//  Vistalio
//
//  Created by Julia Konkova on 06.04.2026.
//

import UIKit

extension UILabel {
    
    func calculateMaxLines() -> Int {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(Float.infinity))
        let charSize = font.lineHeight
        let text = (self.text ?? "") as NSString
        let textSize = text.boundingRect(with: maxSize,
                                        options: .usesLineFragmentOrigin,
                                        attributes: [.font: font as Any],
                                        context: nil)
        let linesRoundedUp = Int(ceil(textSize.height / charSize))
        return linesRoundedUp
    }
}
