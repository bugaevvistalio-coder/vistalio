//
//  PlayerView.swift
//  Vistalio
//
//  Created by Julia Konkova on 17.11.2026.
//

import UIKit
import AVFoundation

class AudioView: UIView {
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var waveformView: WaveformView!
    
    private let player = AudioPlayer()
    
    var url: URL!
    private var duration: TimeInterval = 0
    private var seekProgress: Float?
    
    // Опционально: ставим звук на паузу на время ведения пальца, чтобы не было щелчков
    private var wasPlayingBeforeScrub = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        playPauseButton.setImage(nil, for: .normal)
        playPauseButton.setBackgroundImage(.play1, for: .normal)
        setupPlayer()
        
        waveformView.onSeek = { [weak self] progress in
            self?.player.seek(to: progress)
            self?.seekProgress = progress
        }

        waveformView.onScrubbingStateChanged = { [weak self] isScrubbing in
            guard let self = self else { return }
            
            if isScrubbing {
                self.wasPlayingBeforeScrub = self.player.isPlaying
                self.player.pause()
            } else if self.wasPlayingBeforeScrub {
                self.wasPlayingBeforeScrub = false
                if seekProgress == 1 {
                    self.playPauseButton.setBackgroundImage(.play1, for: .normal)
                    self.durationLabel.text = self.duration.formattedMSS
                } else {
                    self.player.play(url: url)
                }
            }
        }
    }
    
    func setUrl(_ url: URL, onReady: @escaping () -> ()) {
        self.url = url
        
        let asset = AVURLAsset(url: url)
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        let samplesPerSecond = 8
        let idealBarsForDuration = max(1, Int(ceil(CGFloat(durationSeconds) * CGFloat(samplesPerSecond))))
        let targetCount = min(waveformView.maxBarsCount, idealBarsForDuration)
        
        self.duration = durationSeconds.isFinite ? durationSeconds : 0.0
        durationLabel.text = self.duration.formattedMSS

        AudioWaveformExtractor.extractSamples(from: url, targetSampleCount: targetCount) { [weak self] samples in
            guard let `self` = self else {
                return
            }
            self.waveformView.clear()
            samples.forEach {
                self.waveformView.addBar(amplitude: CGFloat($0), removeFirst: false)
            }
            onReady()
        }
    }
    
    private func setupPlayer() {
        player.onProgressUpdate = { [weak self] progress, currentTime in
            // Передаем прогресс (0.0...1.0) в волну для перекрашивания палочек
            self?.waveformView.progress = progress
            self?.durationLabel.text = currentTime.formattedMSS
        }
        
        player.onPlaybackStopped = { [weak self] didFinishToEnd in
            // Меняем иконку кнопки обратно на "Play"
            if self?.wasPlayingBeforeScrub != true {
                self?.playPauseButton.setBackgroundImage(.play1, for: .normal)
            }
            
            if didFinishToEnd {
                self?.durationLabel.text = self?.duration.formattedMSS
                print("Аудио доиграло до конца")
            }
        }
    }
    
    @IBAction func playPauseTapped(_ sender: Any) {
        if player.isPlaying {
            playPauseButton.setBackgroundImage(.play1, for: .normal)
            player.pause()
        } else {
            playPauseButton.setBackgroundImage(.pause1, for: .normal)
            player.play(url: url, progress: waveformView.progress)
        }
    }
    
    func stopPlaying() {
        if player.isPlaying {
            playPauseButton.setBackgroundImage(.play1, for: .normal)
            player.pause()
        }
    }
}
