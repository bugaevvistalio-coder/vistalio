//
//  String+Extensions.swift
//  Vistalio
//
//  Created by Julia Konkova on 08.06.2022.
//

import UIKit

extension String {
    func trim() -> String {
        return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    static func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    func height(withWidth width: CGFloat, font: UIFont) -> CGFloat {
        let maxSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let actualSize = self.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font : font], context: nil)
        return actualSize.height + 0.5
    }
    
    func height(withWidth width: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let maxSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let actualSize = self.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
        return actualSize.height + 0.5
    }
    
    func width(withHeight height: CGFloat, font: UIFont) -> CGFloat {
        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)
        let actualSize = self.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font : font], context: nil)
        return actualSize.width + 0.5
    }
    
    func toFileName() -> String {
        var invalidCharacters = CharacterSet(charactersIn: ":/")
        invalidCharacters.formUnion(.newlines)
        invalidCharacters.formUnion(.illegalCharacters)
        invalidCharacters.formUnion(.controlCharacters)

        return components(separatedBy: invalidCharacters).joined(separator: "_")
    }
    
    func getUrls() -> [String] {
        if !contains("http") {
            return []
        }
        var urls = [String]()
        let types: NSTextCheckingResult.CheckingType = .link
        let detector = try? NSDataDetector(types: types.rawValue)

        guard let detect = detector else {
            return urls
        }
      
        let matches = detect.matches(in: self, options: .reportCompletion, range: NSMakeRange(0, count))

        for match in matches {
            if let url = match.url?.absoluteString {
                urls.append(url)
            }
        }
        return urls
    }
    
    func convertToAttributedFromHTML() -> NSAttributedString? {
        var attributedText: NSAttributedString?
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue]
        if let data = data(using: .unicode, allowLossyConversion: true), let attrStr = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            attributedText = attrStr
        }
        return attributedText
    }
    
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }

    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }

    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
    
    func inclineWord_1(for count: Int) -> String {
        switch count % 10 {
        case 1 where count % 100 != 11:
            return "\(count) \(self)"

        case 2 where !(count % 100 != 12),
            3 where !(count % 100 != 13),
            4 where !(count % 100 != 14):
            return "\(count) \(self)а"
        default:
            return "\(count) \(self)ов"
        }
    }
    
    func inclineWord_2(for count: Int) -> String {
        switch count % 10 {
        case 1 where count % 100 != 11:
            return "\(count) \(self)ка"

        case 2 where !(count % 100 != 12),
            3 where !(count % 100 != 13),
            4 where !(count % 100 != 14):
            return "\(count) \(self)ки"
        default:
            return "\(count) \(self)ок"
        }
    }
    
    func limitCharacters(_ limit: Int) -> String {
        if count > limit {
            let index = index(startIndex, offsetBy: limit)
            return String(self[..<index]) + "..."
        } else {
            return self
        }
    }
    
    var toDay: Date {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: self)!
    }
}
