//
//  CounterView.swift
//  Vistalio
//
//  Created by Julia Konkova on 29.07.2026.
//

import UIKit

class CounterView: UIView {
    
    @IBOutlet weak var counterLabel: UILabel!
    
    private var view: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        view = xibSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        view = xibSetup()
    }
    
    var count: Int = 0 {
        didSet {
            counterLabel.text = "+\(count)"
        }
    }
    
    var width: CGFloat {
        print("Width \(16 + (counterLabel.text?.width(withHeight: 15, font: counterLabel.font) ?? 0))")
        return 16 + (counterLabel.text?.width(withHeight: 15, font: counterLabel.font) ?? 0)
    }
}
