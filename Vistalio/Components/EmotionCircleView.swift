//
//  EmotionCircleView.swift
//  Vistalio
//
//  Created by Julia Konkova on 10.07.2026.
//

import UIKit

class EmotionCircleView: UIView {
    
    @IBOutlet weak var emotionImageView: UIImageView!
    @IBOutlet weak var borderView: UIView!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var outerView: UIView!
    
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
    
    private func setup() {
        view.backgroundColor = .clear
    }
    
    var emotion: MissionEmotion! {
        didSet {
            let nameAndImage = emotion.nameAndImage
            emotionImageView.image = nameAndImage.1
            
            let colors = emotion.colors
            bgView.setGradientLayer(colors: colors.0, startPoint: CGPoint(x: 0.5, y: 0.0), endPoint: CGPoint(x: 0.5, y: 1.0), cornerRadius: 17, bounds: CGRect(x: 0, y: 0, width: 34, height: 34))
            borderView.setGradientLayer(colors: colors.1, startPoint: CGPoint(x: 0.5, y: 0.0), endPoint: CGPoint(x: 0.5, y: 1.0), cornerRadius: 18, bounds: CGRect(x: 0, y: 0, width: 36, height: 36))
            borderView.setShadow(offset: CGSize(width: 0, height: 1.24), radius: 1.24, cornerRadius: 18, shadowOpacity: 0.12)
            outerView.layer.borderColor = colors.2.cgColor
        }
    }
}
