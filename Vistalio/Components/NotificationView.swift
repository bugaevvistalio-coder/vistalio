//
//  NotificationView.swift
//  Vistalio
//
//  Created by Julia Konkova on 17.04.2026.
//

import UIKit

class NotificationView: UIView {
    
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var secondaryLabel: UILabel!
    
    private var view: UIView!
    
    var onTapped: (() -> ())?
    
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
        setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 20, shadowOpacity: 0.22)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            self?.removeFromSuperview()
        }
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        
        secondaryLabel.isHidden = true
    }
    
    var text: String? {
        didSet {
            label.text = text
        }
    }
    
    var secondaryText: String? {
        didSet {
            if let text = secondaryText {
                secondaryLabel.isHidden = false
                secondaryLabel.text = text
            } else {
                secondaryLabel.isHidden = true
            }
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let screenWidth = UIScreen.main.bounds.width
        
        if gesture.state == .changed {
            let translation = gesture.translation(in: self.superview!)
            if translation.x > 0 {
                return
            }
            center = CGPoint(x: center.x + translation.x, y: center.y)
            gesture.setTranslation(CGPoint.zero, in: self.superview!)
        } else if gesture.state == .ended {
            if center.x < superview!.frame.width / 2 - 50 {
                UIView.animate(withDuration: 0.3, animations: {
                    self.center.x = -screenWidth
                }) { _ in
                    self.removeFromSuperview()
                }
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.center.x = self.superview!.frame.width/2
                }
            }
        }
    }
    
    @objc func handleTap(_ gesture: UIPanGestureRecognizer) {
        onTapped?()
        removeFromSuperview()
    }
}
