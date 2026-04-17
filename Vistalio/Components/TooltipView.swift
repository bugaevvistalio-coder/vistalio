//
//  TooptipView.swift
//  Vistalio
//
//  Created by Julia Konkova on 17.04.2026.
//

import UIKit

class TooltipView: UIView {
    
    @IBOutlet private weak var label: UILabel!
    
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
        backgroundColor = .white
        setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 15, shadowOpacity: 0.22)
    }
    
    var text: String? {
        didSet {
            label.text = text
        }
    }
}
