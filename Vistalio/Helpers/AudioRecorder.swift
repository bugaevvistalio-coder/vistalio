//
//  AudioRecorder.swift
//  Vistalio
//
//  Created by Julia Konkova on 15.11.2026.
//

import Foundation
import AVFoundation

final class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    
    /// Замыкание вызывается каждые 0.5 сек: передаёт громкость (0.0...1.0) и время записи
    var onMeterUpdate: ((_ amplitude: Float, _ duration: TimeInterval) -> Void)?
    var onRecordingStarted: (() -> Void)?
    var onRecordingFinished: ((_ fileURL: URL) -> Void)?
    var onPermissionDenied: (() -> Void)?
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private let updateInterval: TimeInterval = 0.05
    private var isCancelled = false
    
    var isRecording: Bool {
        audioRecorder?.isRecording ?? false
    }
    
    // MARK: - Public Methods
    
    func startRecording() {
        checkPermissionAndRecord()
    }
    
    func stopRecording() {
        isCancelled = false
        stopTimer()
        audioRecorder?.stop() // После этого сработает делегат audioRecorderDidFinishRecording
    }
    
    func cancelRecording() {
        isCancelled = true
        stopTimer()
        let url = audioRecorder?.url
        audioRecorder?.stop()
        audioRecorder = nil
        
        if let url = url {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Permission & Setup
    
    private func checkPermissionAndRecord() {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                beginRecordingSession()
            case .denied:
                DispatchQueue.main.async { self.onPermissionDenied?() }
            case .undetermined:
                AVAudioApplication.requestRecordPermission { [weak self] granted in
                    DispatchQueue.main.async {
                        granted ? self?.beginRecordingSession() : self?.onPermissionDenied?()
                    }
                }
            @unknown default:
                DispatchQueue.main.async { self.onPermissionDenied?() }
            }
        } else {
            let session = AVAudioSession.sharedInstance()
            switch session.recordPermission {
            case .granted:
                beginRecordingSession()
            case .denied:
                DispatchQueue.main.async { self.onPermissionDenied?() }
            case .undetermined:
                session.requestRecordPermission { [weak self] granted in
                    DispatchQueue.main.async {
                        granted ? self?.beginRecordingSession() : self?.onPermissionDenied?()
                    }
                }
            @unknown default:
                DispatchQueue.main.async { self.onPermissionDenied?() }
            }
        }
    }
    
    private func beginRecordingSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            FilesHelper().createFolder("audio")
            let fileURL = documentsDirectory
                .appendingPathComponent("audio")
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            startTimer()
            onRecordingStarted?()
        } catch {
            print("Ошибка запуска записи: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Timer & Metering
    
    private func startTimer() {
        stopTimer()
        let timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.fetchMetrics()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func fetchMetrics() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        
        recorder.updateMeters()
        
        let minDb: Float = -55.0
        let power = recorder.averagePower(forChannel: 0)
        let normalizedAmplitude = max(0.05, min(1.0, (power - minDb) / abs(minDb)))
        
        onMeterUpdate?(normalizedAmplitude, recorder.currentTime)
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        stopTimer()
        let url = recorder.url
        audioRecorder = nil
        
        if flag && !isCancelled {
            onRecordingFinished?(url)
        }
    }
}

