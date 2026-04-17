//
//  ConfirmationViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 03.04.2026.
//

import UIKit
import FittedSheets

enum ActionButtonType {
    case primary
    case secondary
    case red
    case blue
}

struct ActionButton {
    let type: ActionButtonType
    let title: String
    let action: () -> ()
    
    func create() -> UIButton {
        let button = RoundedButton(type: .system)
        button.cornerRadius = 26
        
        let h = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 52)
        NSLayoutConstraint.activate([h])
        
        switch type {
        case .primary:
            button.backgroundColor = .darkGrey
            button.setTitleColor(.white, for: .normal)
        case .secondary:
            button.backgroundColor = .bgGrey
            button.setTitleColor(.black, for: .normal)
        case .red:
            button.backgroundColor = .textRed.withAlphaComponent(0.1)
            button.setTitleColor(.textRed, for: .normal)
        case .blue:
            button.backgroundColor = .brightBlue.withAlphaComponent(0.1)
            button.setTitleColor(.brightBlue, for: .normal)
        }
        
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitle(title, for: .normal)
        
        return button
    }
}

class SelectActionViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var buttonsStackView: UIStackView!
    
    var popupTitle: String!
    var popupText: String?
    var buttons = [ActionButton]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = popupTitle
        if let text = popupText {
            textLabel.text = text
        } else {
            textLabel.isHidden = true
        }
        
        for (i, b) in buttons.enumerated() {
            let button = b.create()
            buttonsStackView.addArrangedSubview(button)
            button.tag = i
            button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resize()
    }
    
    private func resize() {
        let window = UIApplication.shared.windows.first
        var height = window?.safeAreaInsets.bottom ?? 0
        if height == 0 {
            height = 20
        }
        
        height += 72
        height += 32
        
        height += titleLabel.frame.height
        if popupText != nil {
            height += textLabel.frame.height
            height += 8
        }
        
        buttons.forEach {_ in 
            height += 52
        }
        height += CGFloat((buttons.count - 1) * 8)

        self.sheetViewController?.setSizes([.fixed(height), .fixed(height)], animated: true)
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        let action = buttons[sender.tag].action
        dismiss(animated: true) {
            action()
        }
    }
}
