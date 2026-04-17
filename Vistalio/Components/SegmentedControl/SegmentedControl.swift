//
//  SegmentedControl.swift
//  Vistalio
//
//  Created by Julia Konkova on 06.04.2026.
//

import UIKit

struct SegmentedTabData {
    let text: String?
    let image: UIImage?
    var tooltip: String?
}

class SegmentedControl: UIView {
    
    @IBOutlet private weak var stackView: UIStackView!
    
    private var view: UIView!
    
    var onTabSelected: ((Int) -> ())?
    
    var tabs = [SegmentedTabData]() {
        didSet {
            for (i, data) in tabs.enumerated() {
                let tabView = SegmentedControlTab()
                tabView.data = data
                if i == 0 {
                    tabView.position = .left
                } else if i == tabs.count - 1 {
                    tabView.position = .right
                } else {
                    tabView.position = .center
                }
                tabView.tag = i
                tabView.isTabSelected = (i == 0)
                tabView.onSelected = { [unowned self] t in
                    for v in self.stackView.arrangedSubviews {
                        (v as! SegmentedControlTab).isTabSelected = (v === t)
                    }
                    onTabSelected?(i)
                }
                stackView.addArrangedSubview(tabView)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        view = xibSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        view = xibSetup()
    }
}
