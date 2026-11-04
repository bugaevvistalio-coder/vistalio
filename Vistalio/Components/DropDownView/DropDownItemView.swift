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
    @IBOutlet private weak var labelLeading: NSLayoutConstraint!
    @IBOutlet private weak var imageView: UIImageView!
    
    private var view: UIView!
    
    var onChecked: ((Int) -> ())? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        view = xibSetup()
        imageView.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        view = xibSetup()
        imageView.isHidden = true
    }
    
    var text: String? {
        didSet {
            label.text = text
        }
    }
    
    var image: UIImage? {
        didSet {
            if let image = image {
                imageView.isHidden = false
                imageView.image = image
                labelLeading.constant = 32
            } else {
                imageView.isHidden = true
                labelLeading.constant = 8
            }
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
