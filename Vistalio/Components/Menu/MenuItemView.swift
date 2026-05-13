//
//  MenuItemView.swift
//  Vistalio
//
//  Created by Julia Konkova on 07.04.2026.
//

import UIKit

enum MenuItemType {
    case normal
    case red
    case blue
}

struct MenuItemData {
    let text: String?
    let image: UIImage?
    let type: MenuItemType
    let action: () -> ()
}

class MenuItemView: UIControl {
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var label: UILabel!
    
    private var view: UIView!
    
    var action: (() -> ())? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        view = xibSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        view = xibSetup()
    }
    
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    var text: String? {
        didSet {
            label.text = text
        }
    }
    
    var type: MenuItemType = .normal {
        didSet {
            if type == .red {
                label.textColor = .textRed
                imageView.tintColor = .textRed
            } else if type == .blue {
                label.textColor = .brightBlue
                imageView.tintColor = .brightBlue
            } else {
                label.textColor = .black
                imageView.tintColor = .black
            }
        }
    }
    
    @IBAction func onTapped(_ sender: Any) {
        action?()
    }
}
