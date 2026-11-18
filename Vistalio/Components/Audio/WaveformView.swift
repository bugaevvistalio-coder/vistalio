//
//  WaveformView.swift
//  Vistalio
//
//  Created by Julia Konkova on 15.11.2026.
//

import UIKit

class WaveformView: UIView {
    
    @IBOutlet private weak var stackView: UIStackView!
    
    private var view: UIView!
    
    var maxWidth = 0
    
    @IBInspectable var barColor: UIColor = UIColor.highlightBlue
    @IBInspectable var unplayedBarColor: UIColor = UIColor.textGrey30
    @IBInspectable var barWidth: Int = 2
    @IBInspectable var minBarHeight: Int = 2
    @IBInspectable var maxBarHeight: Int = 16
    
    @IBInspectable var barSpacing: Int = 6 {
        didSet {
            stackView.spacing = CGFloat(barSpacing)
        }
    }
    
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
        maxWidth = Int(UIScreen.main.bounds.width) - 32
        stackView.spacing = CGFloat(barSpacing)
        setupGestures()
    }
    
    var maxBarsCount: Int {
        let spacing = Int(barSpacing)
        return (maxWidth + spacing) / (barWidth + spacing)
    }
    
    var width: Int {
        return stackView.subviews.count * (barWidth + barSpacing) - barSpacing
    }
    
    func clear() {
        stackView.subviews.forEach { view in
            view.removeFromSuperview()
        }
    }
    
    func fillEmpty() {
        clear()
        let count = maxBarsCount
        for _ in 0..<count {
            addBar(amplitude: 0, removeFirst: false)
        }
    }
    
    func addBar(amplitude: CGFloat, removeFirst: Bool = true) {

        if removeFirst {
            stackView.removeArrangedSubview(stackView.arrangedSubviews.first!)
        }
        
        let barHeight = CGFloat(minBarHeight) + CGFloat(maxBarHeight - minBarHeight) * amplitude
        
        let v = UIView()
        v.backgroundColor = barColor
        v.translatesAutoresizingMaskIntoConstraints = false

        stackView.addArrangedSubview(v)

        NSLayoutConstraint.activate([
            v.widthAnchor.constraint(equalToConstant: CGFloat(barWidth)),
            v.heightAnchor.constraint(equalToConstant: barHeight)
        ])
        
        v.layer.cornerRadius = CGFloat(barWidth/2)
    }
    
    var progress: Float = 0 {
        didSet {
            guard !stackView.subviews.isEmpty else { return }
            
            let clamped = max(0.0, min(1.0, progress))
            // Считаем индекс палочки, до которой дошло воспроизведение
            let activeCount = progress == 0 ? stackView.subviews.count : Int(round(Float(stackView.subviews.count) * clamped))
            
            for (index, bar) in stackView.subviews.enumerated() {
                bar.backgroundColor = index < activeCount ? barColor : unplayedBarColor
            }
        }
    }
    
    /// Вызывается при изменении позиции пальца (progress от 0.0 до 1.0)
    var onSeek: ((_ progress: Float) -> Void)?

    /// Вызывается в начале и конце перетаскивания (чтобы при желании ставить плеер на паузу во время скролла)
    var onScrubbingStateChanged: ((_ isScrubbing: Bool) -> Void)?
    
    private func setupGestures() {
        isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(panGesture)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let locationX = gesture.location(in: stackView).x
        let progress = calculateProgress(for: locationX)
        
        self.progress = progress
        onSeek?(progress)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let locationX = gesture.location(in: stackView).x
        let progress = calculateProgress(for: locationX)
        
        switch gesture.state {
        case .began:
            onScrubbingStateChanged?(true)
            self.progress = progress
            
        case .changed:
            self.progress = progress
            // Если хотите, чтобы время в UILabel менялось прямо во время ведения пальца:
            onSeek?(progress)
            
        case .ended, .cancelled, .failed:
            self.progress = progress
            onSeek?(progress)
            onScrubbingStateChanged?(false)
            
        default:
            break
        }
    }

    private func calculateProgress(for xPosition: CGFloat) -> Float {
        let activeWidth = stackView.bounds.width
        guard activeWidth > 0 else { return 0 }
        
        let rawProgress = Float(xPosition / activeWidth)
        return max(0.0, min(1.0, rawProgress))
    }
}
