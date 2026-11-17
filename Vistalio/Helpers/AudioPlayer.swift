//
//  AudioPlayer.swift
//  Vistalio
//
//  Created by Julia Konkova on 17.11.2026.
//

import Foundation
import AVFoundation
import QuartzCore

final class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    
    // MARK: - Callbacks
    
    /// Возвращает прогресс (0.0 ... 1.0) и текущее время воспроизведения в секундах
    var onProgressUpdate: ((_ progress: Float, _ currentTime: TimeInterval) -> Void)?
    
    /// Срабатывает при постановке на паузу, ручной остановке или доигрывании до конца
    var onPlaybackStopped: ((_ didFinishToEnd: Bool) -> Void)?
    
    // MARK: - Private Properties
    
    private var audioPlayer: AVAudioPlayer?
    private var displayLink: CADisplayLink?
    private(set) var currentURL: URL?
    
    var isPlaying: Bool {
        audioPlayer?.isPlaying ?? false
    }
    
    var duration: TimeInterval {
        audioPlayer?.duration ?? 0
    }
    
    // MARK: - Public Methods
    
    /// Запускает воспроизведение нового файла или снимает текущий с паузы
    func play(url: URL) {
        // Если тот же файл уже на паузе — просто продолжаем
        if currentURL == url, let player = audioPlayer {
            if !player.isPlaying {
                configureAudioSession()
                player.play()
                startProgressTracking()
            }
            return
        }
        
        // Если играет другой файл — останавливаем его перед запуском нового
        stop()
        
        do {
            configureAudioSession()
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            player.play()
            
            audioPlayer = player
            currentURL = url
            startProgressTracking()
        } catch {
            print("Ошибка запуска плеера: \(error.localizedDescription)")
            onPlaybackStopped?(false)
        }
    }
    
    /// Ставит воспроизведение на паузу с сохранением текущей позиции
    func pause() {
        guard let player = audioPlayer, player.isPlaying else { return }
        player.pause()
        stopProgressTracking()
        onPlaybackStopped?(false)
    }
    
    /// Полностью останавливает воспроизведение и сбрасывает прогресс в 0
    func stop() {
        stopProgressTracking()
        let wasActive = audioPlayer != nil
        audioPlayer?.stop()
        audioPlayer = nil
        currentURL = nil
        
        if wasActive {
            onPlaybackStopped?(false)
        }
    }
    
    /// Перемотка на нужную позицию (progress от 0.0 до 1.0)
    func seek(to progress: Float) {
        guard let player = audioPlayer else { return }
        let clamped = max(0.0, min(1.0, progress))
        player.currentTime = TimeInterval(clamped) * player.duration
        onProgressUpdate?(clamped, player.currentTime)
    }
    
    // MARK: - Private Helpers
    
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        // Используем .playback, чтобы звук шел через основной динамик, а не разговорный
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }
    
    private func startProgressTracking() {
        stopProgressTracking()
        let link = CADisplayLink(target: self, selector: #selector(updateProgress))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }
    
    private func stopProgressTracking() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateProgress() {
        guard let player = audioPlayer, player.isPlaying, player.duration > 0 else { return }
        let progress = Float(player.currentTime / player.duration)
        onProgressUpdate?(progress, player.currentTime)
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopProgressTracking()
        audioPlayer = nil
        currentURL = nil
        onProgressUpdate?(0.0, 0.0)
        onPlaybackStopped?(flag)
    }
}
