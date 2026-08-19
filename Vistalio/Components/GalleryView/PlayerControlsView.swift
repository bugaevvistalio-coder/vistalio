//
//  PlayerControlView.swift
//  Vistalio
//
//  Created by Julia Konkova on 10.08.2026.
//

import UIKit

class PlayerControlsView: UIView, UIGestureRecognizerDelegate {
    
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var soundButton: UIButton!
    @IBOutlet private weak var fullLengthView: UIView!
    @IBOutlet private weak var progressViewWidth: NSLayoutConstraint!
    @IBOutlet private weak var sliderView: UIView!
    
    private var view: UIView!
    
    private var isPlaying = false
    private var isMuted = false
    
    var onPlay: (() -> ())?
    var onPause: (() -> ())?
    var onMuted: ((Bool) -> ())?
    var onSeek: ((Double) -> ())?
    var onSeekStarted: (() -> ())?
    var onSeekEnded: (() -> ())?
    
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
        backgroundColor = .clear
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        sliderView.addGestureRecognizer(panGesture)
    }
    
    func reset() {
        playButton.setImage(.play, for: .normal)
        soundButton.setImage(.unmuted, for: .normal)
        isPlaying = false
        isMuted = false
        progressViewWidth.constant = 0
    }
    
    func updateWithProgress(_ progress: Double) {
        progressViewWidth.constant = fullLengthView.frame.width * progress
    }
    
    @IBAction func playPauseTapped(_ sender: Any) {
        isPlaying = !isPlaying
        playButton.setImage(isPlaying ? .pause : .play, for: .normal)
        if isPlaying {
            onPlay?()
        } else {
            onPause?()
        }
    }
    
    @IBAction func soundTapped(_ sender: Any) {
        isMuted = !isMuted
        soundButton.setImage(isMuted ? .muted : .unmuted, for: .normal)
        onMuted?(isMuted)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let targetView = gesture.view, let container = targetView.superview else { return }
        
        let translation = gesture.translation(in: container)
        
        let newCenterX = targetView.center.x + translation.x
        let clampedX = max(fullLengthView.frame.minX, min(newCenterX, fullLengthView.frame.maxX))
        let progress = (clampedX - fullLengthView.frame.minX) / fullLengthView.frame.width
        
        if gesture.state == .began {
            onSeekStarted?()
        }
        
        updateWithProgress(progress)
        onSeek?(progress)
            
        if gesture.state == .ended || gesture.state == .cancelled {
            onSeekEnded?()
        }
        
        gesture.setTranslation(.zero, in: container)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer is UITapGestureRecognizer
    }
}
