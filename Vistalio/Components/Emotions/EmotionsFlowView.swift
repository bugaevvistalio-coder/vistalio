//
//  EmotionsFlowView.swift
//  Vistalio
//
//  Created by Julia Konkova on 29.07.2026.
//

import UIKit

class EmotionsFlowView: UIStackView {
    
    private var collapsedEmotionsCount = 0
    private var hideLastEmotionInFirstRow = false
    private var firstStackView: UIStackView?
    private var counterView: CounterView?
    
    var maxWidth: CGFloat = UIScreen.main.bounds.width
    var canEdit = false
    var onEdit: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }
    
    var emotions = [MissionEmotion]() {
        didSet {
            let views = arrangedSubviews
            for v in views {
                v.removeFromSuperview()
            }
            if emotions.isEmpty {
                return
            }
            
            var width: CGFloat = 0
            var stackView = addHorizontalStackView(hidden: false)
            
            if canEdit {
                let button = createEditButton()
                stackView.addArrangedSubview(button)
                stackView.setCustomSpacing(4, after: button)
                width += 34
            }
            
            collapsedEmotionsCount = 0
            
            for e in emotions {
                let emotionView = createEmotionView(emotion: e)
                width += emotionView.width
                
                if width <= maxWidth {
                    stackView.addArrangedSubview(emotionView)
                    collapsedEmotionsCount += 1
                    width += 3
                } else {
                    counterView = CounterView()
                    counterView!.count = emotions.count - collapsedEmotionsCount
                    
                    width -= emotionView.width
                    width += counterView!.width
                    if width > maxWidth {
                        hideLastEmotionInFirstRow = true
                        stackView.arrangedSubviews.last?.isHidden = true
                        counterView!.count = emotions.count - collapsedEmotionsCount + 1
                    }
                    stackView.addArrangedSubview(counterView!)
                    break
                }
            }
            
            addRemainingSpacingView(to: stackView)
            
            firstStackView = stackView
            
            if collapsedEmotionsCount == emotions.count {
                return
            }
            
            let remainingEmotions = Array(emotions.dropFirst(collapsedEmotionsCount))
            
            if remainingEmotions.count > 0 {
                width = 0
                stackView = addHorizontalStackView(hidden: true)
                
                for e in remainingEmotions {
                    let emotionView = createEmotionView(emotion: e)
                    width += emotionView.width
                    
                    if width > maxWidth {
                        addRemainingSpacingView(to: stackView)
                        stackView = addHorizontalStackView(hidden: true)
                        width = emotionView.width
                    }
                    stackView.addArrangedSubview(emotionView)
                    width += 3
                }
                addRemainingSpacingView(to: stackView)
            }
        }
    }
    
    private func createEditButton() -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.setImage(.edit1, for: .normal)
        button.tintColor = .black
        button.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 15, shadowOpacity: 0.09, bounds: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        
        let w = NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 28)
        let h = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 28)
        NSLayoutConstraint.activate([w, h])
        return button
    }
    
    var expanded = false {
        didSet {
            if expanded == oldValue {
                return
            }
            if hideLastEmotionInFirstRow {
                let index = canEdit ? collapsedEmotionsCount : (collapsedEmotionsCount - 1)
                firstStackView?.arrangedSubviews[index].isHidden = !expanded
            }
            counterView?.isHidden = expanded
            for (i, v) in arrangedSubviews.enumerated() {
                if i > 0 {
                    v.isHidden = !expanded
                }
            }
        }
    }
    
    private func addHorizontalStackView(hidden: Bool) -> UIStackView {
        let stackView = UIStackView(frame: .zero)
        stackView.spacing = 3
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isHidden = hidden
        addArrangedSubview(stackView)
        
        let h = NSLayoutConstraint(item: stackView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 32)
        NSLayoutConstraint.activate([h])
        return stackView
    }
    
    private func createEmotionView(emotion: MissionEmotion) -> EmotionView {
        let emotionView = EmotionView()
        emotionView.emotion = emotion
        emotionView.translatesAutoresizingMaskIntoConstraints = false
        
        let h = NSLayoutConstraint(item: emotionView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 32)
        NSLayoutConstraint.activate([h])
        
        return emotionView
    }
    
    private func addRemainingSpacingView(to stackView: UIStackView) {
        stackView.setCustomSpacing(0, after: stackView.arrangedSubviews.last!)
        let remainingSpaceView = UIView()
        remainingSpaceView.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        stackView.addArrangedSubview(remainingSpaceView)
    }
    
    @objc private func tapped(_ gesture: UITapGestureRecognizer) {
        expanded = !expanded
    }
    
    @objc private func editTapped() {
        onEdit?()
    }
}
