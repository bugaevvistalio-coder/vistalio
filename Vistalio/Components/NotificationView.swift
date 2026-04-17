//
//  NotificationView.swift
//  Vistalio
//
//  Created by Julia Konkova on 17.04.2026.
//

import UIKit

class NotificationView: UIView {
    
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
        setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 20, shadowOpacity: 0.22)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            self?.removeFromSuperview()
        }
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }
    
    var text: String? {
        didSet {
            label.text = text
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
}
