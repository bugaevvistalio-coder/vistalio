//
//  MenuView.swift
//  Vistalio
//
//  Created by Julia Konkova on 07.04.2026.
//

import UIKit

class MenuView: UIView {
    
    @IBOutlet private weak var stackView: UIStackView!
    
    private var view: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        view = xibSetup()
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        view = xibSetup()
        setup()
    }
    
    func setup() {
        setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 30, shadowOpacity: 0.22)
    }
    
    var items = [MenuItemData]() {
        didSet {
            for item in items {
                let itemView = MenuItemView()
                itemView.text = item.text
                itemView.image = item.image
                itemView.type = item.type
                itemView.action = item.action
                stackView.addArrangedSubview(itemView)
            }
        }
    }
}
