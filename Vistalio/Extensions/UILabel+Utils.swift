//
//  UILabel+Utils.swift
//  Vistalio
//
//  Created by Julia Konkova on 06.04.2026.
//

import UIKit

extension UILabel {
    
    func calculateMaxLines(width: CGFloat? = nil, lineHeightMultiple: CGFloat = 1) -> Int {
        let maxSize = CGSize(width: width ?? frame.size.width, height: CGFloat(Float.infinity))
        let charSize = font.lineHeight * lineHeightMultiple
        let text = (self.text ?? "") as NSString
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = lineHeightMultiple
        
        let textSize = text.boundingRect(with: maxSize,
                                         options: .usesLineFragmentOrigin,
                                         attributes: [.font: font as Any, .paragraphStyle: paragraphStyle as Any],
                                         context: nil)
        let linesRoundedUp = Int(ceil(textSize.height / charSize))
        return linesRoundedUp
    }
}
