//
//  DropDownView.swift
//  Vistalio
//
//  Created by Julia Konkova on 05.06.2026.
//

import UIKit

struct DropItemData {
    let text: String
}

class DropDownView: UIView {
    
    @IBOutlet private weak var stackView: UIStackView!
    
    private var view: UIView!
    
    var onChecked: ((Int) -> ())? = nil
    
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
        backgroundColor = .white
        setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 30, shadowOpacity: 0.22)
    }
    
    var items = [DropItemData]() {
        didSet {
            for (i, item) in items.enumerated() {
                let itemView = DropDownItemView()
                itemView.index = i
                itemView.text = item.text
                itemView.onChecked = { [unowned self] index in
                    self.checkedIndex = index
                    self.onChecked?(index)
                }
                
                itemView.translatesAutoresizingMaskIntoConstraints = false
                let h = itemView.heightAnchor.constraint(equalToConstant: 40)
                NSLayoutConstraint.activate([h])
                
                stackView.addArrangedSubview(itemView)
            }
        }
    }
    
    var checkedIndex: Int = 0 {
        didSet {
            for (i, v) in stackView.arrangedSubviews.enumerated() {
                (v as? DropDownItemView)?.isChecked = (i == checkedIndex)
            }
        }
    }
    
    var height: Int {
        return items.count * 40 + (items.count - 1) * 8 + 24
    }
}
