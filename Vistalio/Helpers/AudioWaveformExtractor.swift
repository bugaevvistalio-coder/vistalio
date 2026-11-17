//
//  AudioWaveformExtractor.swift
//  Vistalio
//
//  Created by Julia Konkova on 16.11.2026.
//

import Foundation
import AVFoundation
import Accelerate

final class AudioWaveformExtractor {
    
    static func extractSamples(from url: URL, maxSampleCount: Int, samplesPerSecond: Int, completion: @escaping ([Float]) -> Void) {
        let asset = AVURLAsset(url: url)
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        let idealBarsForDuration = max(1, Int(ceil(CGFloat(durationSeconds) * CGFloat(samplesPerSecond))))
        let targetCount = min(maxSampleCount, idealBarsForDuration)
        extractSamples(from: url, targetSampleCount: targetCount, completion: completion)
    }
    
    /// Извлекает массив нормализованных уровней громкости (0.0 ... 1.0) заданной длины
    static func extractSamples(from url: URL, targetSampleCount: Int, completion: @escaping ([Float]) -> Void) {
        guard targetSampleCount > 0 else {
            completion([])
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let file = try AVAudioFile(forReading: url)
                let format = file.processingFormat
                let totalFrames = UInt32(file.length)
                
                guard totalFrames > 0,
                      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else {
                    DispatchQueue.main.async { completion([]) }
                    return
                }
                
                try file.read(into: buffer)
                
                guard let channelData = buffer.floatChannelData?[0] else {
                    DispatchQueue.main.async { completion([]) }
                    return
                }
                
                let frameCount = Int(buffer.frameLength)
                let samplesPerBin = max(1, frameCount / targetSampleCount)
                var result: [Float] = []
                result.reserveCapacity(targetSampleCount)
                
                for i in 0..<targetSampleCount {
                    let start = i * samplesPerBin
                    let length = min(samplesPerBin, frameCount - start)
                    
                    if length <= 0 {
                        result.append(0.0)
                        continue
                    }
                    
                    // Считаем среднеквадратичную громкость (RMS) для текущего отрезка через Accelerate
                    var rms: Float = 0.0
                    vDSP_rmsqv(channelData.advanced(by: start), 1, &rms, vDSP_Length(length))
                    
                    // Переводим амплитуду в децибелы и нормализуем в диапазон 0.0 ... 1.0
                    let db = 20 * log10(max(rms, 1e-6))
                    let minDb: Float = -50.0 // Порог тишины (можно подкрутить под чувствительность)
                    let normalized = max(0.0, min(1.0, (db - minDb) / abs(minDb)))
                    
                    result.append(normalized)
                }
                
                DispatchQueue.main.async {
                    completion(result)
                }
            } catch {
                print("Ошибка чтения аудиофайла: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
}
