//
//  RingProgressView.swift
//  Vistalio
//
//  Created by Julia Konkova on 13.08.2026.
//

import UIKit

class RingProgressView: UIView {
    
    private let backgroundMaskLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    
    var ringColor: UIColor = .highlightBlue {
        didSet { progressLayer.strokeColor = ringColor.cgColor }
    }
    
    var ringBackgroundColor: UIColor = .lightBlue1 {
        didSet { backgroundMaskLayer.strokeColor = ringBackgroundColor.cgColor }
    }
    
    var lineWidth: CGFloat = 5.0 {
        didSet {
            backgroundMaskLayer.lineWidth = lineWidth
            progressLayer.lineWidth = lineWidth
            setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        backgroundMaskLayer.fillColor = UIColor.clear.cgColor
        backgroundMaskLayer.strokeColor = ringBackgroundColor.cgColor
        backgroundMaskLayer.lineWidth = lineWidth
        backgroundMaskLayer.lineCap = .round
        layer.addSublayer(backgroundMaskLayer)
        
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = ringColor.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0.0
        layer.addSublayer(progressLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2
        
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + (2 * CGFloat.pi)
        
        let circularPath = UIBezierPath(arcCenter: center,
                                        radius: radius,
                                        startAngle: startAngle,
                                        endAngle: endAngle,
                                        clockwise: true)
        backgroundMaskLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
    }

    func setProgress(_ progress: Float, animated: Bool = true) {
        let clampedProgress = CGFloat(max(0.0, min(progress, 1.0)))
        
        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = clampedProgress
            animation.duration = 0.1 // Маленькая задержка для плавности KVO
            animation.timingFunction = CAMediaTimingFunction(name: .linear)
            
            progressLayer.strokeEnd = clampedProgress
            progressLayer.add(animation, forKey: "progressAnim")
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true) // Отключаем дефолтную анимацию слоев
            progressLayer.strokeEnd = clampedProgress
            CATransaction.commit()
        }
    }
}
