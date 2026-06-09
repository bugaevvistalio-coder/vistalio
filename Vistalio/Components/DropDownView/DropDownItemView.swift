//
//  DropDownItemView.swift
//  Vistalio
//
//  Created by Julia Konkova on 05.06.2026.
//

import UIKit

class DropDownItemView: UIView {
    
    @IBOutlet private weak var checkImageView: UIImageView!
    @IBOutlet private weak var label: UILabel!
    
    private var view: UIView!
    
    var onChecked: ((Int) -> ())? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        view = xibSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        view = xibSetup()
    }
    
    var text: String? {
        didSet {
            label.text = text
        }
    }
    
    var index: Int = 0
    
    var isChecked: Bool = false {
        didSet {
            checkImageView.isHidden = !isChecked
        }
    }
    
    @IBAction func onTapped(_ sender: Any) {
        isChecked = true
        onChecked?(index)
    }
}
