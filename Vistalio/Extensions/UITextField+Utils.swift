//
//  UITextField+Utils.swift
//  Vistalio
//
//  Created by Julia Konkova on 28.03.2026.
//

import UIKit

extension UITextField {
    func setRightPadding(_ padding: Int) {
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: padding))
        rightView = paddingView
        rightViewMode = .always
    }
    
    func setLeftPadding(_ padding: Int) {
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: padding))
        leftView = paddingView
        leftViewMode = .always
    }
}
