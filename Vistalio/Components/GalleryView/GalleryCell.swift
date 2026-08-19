//
//  GalleryCel.swift
//  Vistalio
//
//  Created by Julia Konkova on 28.04.2026.
//

import UIKit
import AVKit
import AVFoundation
import Kingfisher

class GalleryCell: UICollectionViewCell {
    
    @IBOutlet private weak var imageScrollView: ImageScrollView!
    @IBOutlet private weak var loadIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var videoContainerView: UIView!
    @IBOutlet private weak var playerControlsView: PlayerControlsView!
    
    private var originalZoom: CGFloat = 1
    private var autoZooming = false
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var videoBorderLayer: CAShapeLayer?
    private var timeObserver: Any?
    private var playAfterSeek = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageScrollView.imageContentMode = .aspectFit
        imageScrollView.setup()
        imageScrollView.imageScrollViewDelegate = self
        
        videoContainerView.isHidden = true
        imageScrollView.isHidden = false
        playerControlsView.onPlay = { [unowned self] in
            videoContainerView.isHidden = false
            imageScrollView.isHidden = true
            player?.play()
            startTrackingProgress()
        }
        playerControlsView.onPause = { [unowned self] in
            player?.pause()
            removeProgressObserver()
        }
        playerControlsView.onMuted = { [unowned self] isMuted in
            player?.isMuted = isMuted
        }
        playerControlsView.onSeekStarted = { [unowned self] in
            if let player = player {
                setNeedsLayout()
                layoutIfNeeded()
                videoContainerView.isHidden = false
//                imageScrollView.isHidden = true
                playAfterSeek = player.rate > 0
                player.pause()
            }
        }
        playerControlsView.onSeekEnded = { [unowned self] in
            if let player = player, playAfterSeek {
                player.play()
            }
        }
        playerControlsView.onSeek = { [unowned self] progress in
            guard let player = player, let currentItem = player.currentItem else { return }
            
            let durationInSeconds = CMTimeGetSeconds(currentItem.duration)
            if durationInSeconds.isNaN { return }
            
            let targetSeconds = progress * durationInSeconds
            let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: 600)
            
            
            player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let zoomView = imageScrollView.zoomView {
            let point = zoomView.superview!.convert(zoomView.frame.origin, to: contentView)
            videoContainerView.frame = CGRect(origin: point, size: zoomView.frame.size)
            playerLayer?.frame = videoContainerView.bounds
            
            if let borderLayer = videoBorderLayer {
                borderLayer.frame = videoContainerView.bounds
                borderLayer.path = UIBezierPath(
                    roundedRect: videoContainerView.bounds,
                    cornerRadius: videoContainerView.layer.cornerRadius
                ).cgPath
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        resetPlayer()
    }
    
    var media: MediaData! {
        didSet {
            // Иначе будет неправильно центрирование по вертикали, потому что высота не сразу определяется правильно
            imageScrollView.frame.size.height = contentView.frame.height - 160
            videoContainerView.isHidden = true
            imageScrollView.isHidden = false
            loadIndicator.isHidden = true
            loadIndicator.stopAnimating()
            
            let url = media.url
            
            imageScrollView.isUserInteractionEnabled = media.type == "image"
            
            if media.image == nil && media.path == nil {
                imageScrollView.isHidden = true
                loadIndicator.isHidden = false
                loadIndicator.startAnimating()
            } else if let image = media.image {
                imageScrollView.display(image: image, enableDoubleTap: false)
                DispatchQueue.main.async {
                    self.updateBorder()
                }
                playerControlsView.isHidden = true
            } else if media.type == "image", let url = url {
                loadImage(url: url, path: media.path!)
            }
            
            if media.type == "video", let url = url {
                configure(with: url)
                playerControlsView.isHidden = false
            } else {
                playerControlsView.isHidden = true
            }
        }
    }
    
    private func updateBorder() {
        imageScrollView.zoomView?.layer.cornerRadius = 12 / imageScrollView.zoomScale
        imageScrollView.zoomView?.layer.borderWidth = 6 / imageScrollView.zoomScale
        imageScrollView.zoomView?.layer.borderColor = UIColor.white.cgColor
        imageScrollView.zoomView?.layer.masksToBounds = true
    }
    
    private func loadImage(url: URL, path: String) {
        if path.starts(with: "http"), !ImageCache.default.isCached(forKey: path) {
            loadIndicator.isHidden = false
            loadIndicator.startAnimating()
        } else {
            loadIndicator.isHidden = true
            loadIndicator.stopAnimating()
        }
        
        KingfisherManager.shared.retrieveImage(with: url) { result in
            DispatchQueue.main.async { [weak self] in
                if self?.media.path == path {
                    switch result {
                    case .success(let value):
                        self?.imageScrollView.display(image: value.image, enableDoubleTap: false)
                        self?.updateBorder()
                    case .failure( _):
                        self?.imageScrollView.zoomView?.image = nil
                    }
                    self?.loadIndicator.isHidden = true
                    self?.loadIndicator.stopAnimating()
                }
            }
        }
    }
    
    private func configure(with videoURL: URL) {
        resetPlayer()
        
        let player = AVPlayer(url: videoURL)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.cornerRadius = 12
        
        playerLayer.videoGravity = .resizeAspect
        videoContainerView.layer.insertSublayer(playerLayer, at: 0)
            
        let border = CAShapeLayer()
        border.strokeColor = UIColor.white.cgColor
        border.fillColor = UIColor.clear.cgColor
        border.lineWidth = 12 // в 2 раза толще надо, а то половина идет внутрь, а половина наружу
        videoContainerView.layer.addSublayer(border)
        
        self.player = player
        self.playerLayer = playerLayer
        self.videoBorderLayer = border
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
    }
    
    @objc private func playerDidFinishPlaying(notification: NSNotification) {
        guard let playerItem = notification.object as? AVPlayerItem else { return }
        playerItem.seek(to: .zero, completionHandler: nil)
        playerControlsView.reset()
    }
    
    private func resetPlayer() {
        player?.pause()
        removeProgressObserver()
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        playerLayer?.removeFromSuperlayer()
        videoBorderLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
        videoBorderLayer = nil
    }
    
    func stopPlayback() {
        player?.isMuted = false
        player?.pause()
        player?.seek(to: .zero)
        removeProgressObserver()
        videoContainerView.isHidden = true
        imageScrollView.isHidden = false
        playAfterSeek = false
        playerControlsView.reset()
    }
    
    private func startTrackingProgress() {
        guard let player = self.player, let currentItem = player.currentItem else { return }
        
        let interval = CMTime(seconds: 0.3, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] currentTime in
            guard let self = self, let duration = currentItem.duration.seconds.isFinite ? currentItem.duration : nil else { return }
            
            let currentSeconds = currentTime.seconds
            let totalSeconds = duration.seconds
            
            guard totalSeconds > 0 else { return }
            
            let progress = currentSeconds / totalSeconds
            playerControlsView.updateWithProgress(progress)
        }
    }
    
    private func removeProgressObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
}

extension GalleryCell: ImageScrollViewDelegate {
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        if !autoZooming {
            originalZoom = imageScrollView.zoomScale
        }
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if !autoZooming {
            imageScrollView.setZoomScale(originalZoom, animated: true)
        }
        autoZooming = !autoZooming
        updateBorder()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateBorder()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateBorder()
    }
    
    func imageScrollViewDidChangeOrientation(imageScrollView: ImageScrollView) { }
}
