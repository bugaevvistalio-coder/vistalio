//
//  DropDownControl.swift
//  Vistalio
//
//  Created by Julia Konkova on 05.06.2026.
//

import UIKit
class DropDownControl: UIView {
    
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var arrowImageView: UIImageView!
    
    @IBOutlet private weak var labelLeading: NSLayoutConstraint!
    
    private var view: UIView!
    
    var parentVC: UIViewController!
    var items = [DropItemData]()
    var checkedIndex: Int = 0 {
        didSet {
            if checkedIndex < items.count {
                let item = items[checkedIndex]
                label.text = item.text
                
                if let image = item.image {
                    imageView.isHidden = false
                    imageView.image = image
                    labelLeading.constant = 36
                } else {
                    imageView.isHidden = true
                    labelLeading.constant = 12
                }
            }
        }
    }
    var dropDownWidth: CGFloat = 274
    var onBeforeShowItems: (() -> ())?
    var onChecked: ((Int) -> ())?
    
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
    
    private func setup() { }
    
    @IBAction func tapped(_ sender: AnyObject) {
        parentVC.view.endEditing(true)
        
        onBeforeShowItems?()
        
        let menuUnderlayControl = parentVC.addMenuUnderlayControl(color: .clear)
        
        let dropDownView = DropDownView()
        dropDownView.items = items
        dropDownView.checkedIndex = checkedIndex
        dropDownView.onChecked = { [unowned self] index in
            self.checkedIndex = index
            self.onChecked?(index)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                menuUnderlayControl.removeFromSuperview()
                self?.arrowImageView.image = UIImage.chevronDown
                NotificationCenter.default.post(name: .menuClosed, object: nil)
            }
        }
        
        dropDownView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(dropDownView)
        
        var anchorRect = CGRect.zero
        if let origin = superview?.convert(frame.origin, to: nil) {
            anchorRect = CGRect(origin: origin, size: frame.size)
        }
        
        let screenHeight = UIScreen.main.bounds.height
        let menuHeight = CGFloat(height)
        let horizontalConstraint = dropDownView.leftAnchor.constraint(equalTo: menuUnderlayControl.leftAnchor, constant: anchorRect.minX)
        let verticalConstraint = anchorRect.maxY + 7 + 8 + menuHeight > screenHeight ? dropDownView.bottomAnchor.constraint(equalTo: menuUnderlayControl.bottomAnchor, constant: anchorRect.minY - 7 - screenHeight) : dropDownView.topAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: anchorRect.maxY + 7)
        let heightConstraint = dropDownView.heightAnchor.constraint(equalToConstant: menuHeight)
        let widthConstraint = dropDownView.widthAnchor.constraint(equalToConstant: dropDownWidth)
        NSLayoutConstraint.activate([verticalConstraint, horizontalConstraint, heightConstraint, widthConstraint])
        
        arrowImageView.image = UIImage.cross2
    }
    
    var height: Int {
        return items.count * 40 + (items.count - 1) * 8 + 24
    }
    
    func reset() {
        arrowImageView.image = UIImage.chevronDown
    }
    
    @IBInspectable var mainColor: UIColor? {
        didSet {
            label.superview?.backgroundColor = mainColor ?? .darkGrey
        }
    }
    
    @IBInspectable var arrowBackgroundColor: UIColor? {
        didSet {
            arrowImageView.backgroundColor = arrowBackgroundColor ?? .white.withAlphaComponent(0.4)
        }
    }
    
    @IBInspectable var arrowTintColor: UIColor? {
        didSet {
            arrowImageView.tintColor = arrowTintColor ?? .black
        }
    }
    
    @IBInspectable var labelColor: UIColor? {
        didSet {
            label.textColor = labelColor ?? .white
        }
    }
}
