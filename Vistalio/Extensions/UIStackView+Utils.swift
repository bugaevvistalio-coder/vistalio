//
//  UIStackView+Utils.swift
//  Vistalio
//
//  Created by Julia Konkova on 27.04.2026.
//

import UIKit

extension UIStackView {
    
    func addNotification(text: String) {
        let notificationView = NotificationView()
        notificationView.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(notificationView)
        
        NSLayoutConstraint.activate([notificationView.heightAnchor.constraint(equalToConstant: 68)])
        
        notificationView.text = text
    }
}
