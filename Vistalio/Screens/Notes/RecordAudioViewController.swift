//
//  RecordAudioViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 15.11.2026.
//

import UIKit

class RecordAudioViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var waveformView: WaveformView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var startStopButton: UIButton!
    
    private let audioRecorder = AudioRecorder()
    
    enum RecordingAction {
        case finishAndSave
        case finishAndDelete
        case cancel
    }
    
    private var action: RecordingAction?
    
    var onRecordingFinished: ((URL) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        deleteButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 28, shadowOpacity: 0, bounds: CGRect(x: 0, y: 0, width: 56, height: 56))
        
        waveformView.fillEmpty()
        
        audioRecorder.onMeterUpdate = { [weak self] amplitude, duration in
            guard let `self` = self else {
                return
            }
            waveformView.addBar(amplitude: CGFloat(amplitude))
            
            let duration = duration.formattedMSS
            if duration != timeLabel.text {
                timeLabel.text = duration
            }
        }
        audioRecorder.onPermissionDenied = { [unowned self] in
            self.showPermissionDenied()
        }
        audioRecorder.onRecordingStarted = { [unowned self] in
            startStopButton.setTitle("Завершить", for: .normal)
            deleteButton.tintColor = .black
            deleteButton.backgroundColor = .white
            deleteButton.layer.shadowOpacity = 0.1
        }
        audioRecorder.onRecordingFinished = { [unowned self] url in
            if action == .cancel {
                FilesHelper().deleteFile(url: url)
                startStopButton.setTitle("Начать", for: .normal)
                deleteButton.tintColor = .textGrey30
                deleteButton.backgroundColor = .bgGrey
                deleteButton.layer.shadowOpacity = 0
                waveformView.fillEmpty()
                timeLabel.text = "0:00"
            } else {
                if action == .finishAndSave {
                    onRecordingFinished?(url)
                } else {
                    FilesHelper().deleteFile(url: url)
                }
                dismiss(animated: true)
            }
        }
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        if audioRecorder.isRecording {
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
            vc.popupTitle = "У вас осталась незавершённая аудиозапись"
            vc.buttons = [
                ActionButton(type: .red, title: "Удалить", action: { [unowned self] _ in
                    action = .finishAndDelete
                    audioRecorder.stopRecording()
                }),
                ActionButton(type: .secondary, title: "Сохранить", action: { [unowned self] _ in
                    action = .finishAndSave
                    audioRecorder.stopRecording()
                })
            ]
            presentBottomSheet(vc, height: 200, canDismiss: false)
        } else {
            dismiss(animated: true)
        }
    }
    
    @IBAction func startStopTapped(_ sender: Any) {
        if audioRecorder.isRecording {
            action = .finishAndSave
            audioRecorder.stopRecording()
        } else {
            audioRecorder.startRecording()
        }
    }
    
    @IBAction func deleteTapped(_ sender: Any) {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
        }
    }
    
    private func showPermissionDenied() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
        vc.popupTitle = "Нет доступа к микрофону"
        vc.popupText = "Доступ к микрофону нужен для съёмки видео со звуком в приложении и добавления аудиозаписей. Разрешите в настройках."
        vc.showClose = true
        vc.buttons = [
            ActionButton(type: .primary, title: "В настройки", action: { _ in
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                    
                if UIApplication.shared.canOpenURL(settingsURL) {
                    UIApplication.shared.open(settingsURL)
                }
            })
        ]
        presentBottomSheet(vc, height: 200)
    }
}
