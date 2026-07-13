//
//  EmotionSettingsViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 12.07.2026.
//

import UIKit

class EmotionSettingsViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var radio1ImageView: UIImageView!
    @IBOutlet weak var radio2ImageView: UIImageView!
    @IBOutlet weak var manualOptionTextView: UITextView!
    @IBOutlet weak var manualOptionHeight: NSLayoutConstraint!
    @IBOutlet weak var saveButton: UIButton!
    
    private var savedEmotions = [SelectedEmotion]()
    private lazy var mode: String = {
        return UserDefaults.standard.string(forKey: "EmotionsMode") ?? "auto"
    }()
    
    var onSaved: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        setupBottomConstraint(saveButton)
        
        let window = UIApplication.shared.windows.first
        var bottom = window?.safeAreaInsets.bottom ?? 0
        if bottom == 0 {
            bottom = 20
        }
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50 + bottom, right: 0)
        
        let request = SelectedEmotion.selectedEmotionFetchRequest()
        request.predicate = NSPredicate(format: "auto == NO")
        do {
            savedEmotions = try CoreDataStack.shared.mainContext.fetch(request)
        } catch {
            print("Failed to retrive missions and folders")
        }
        
        manualOptionTextView.textContainer.lineFragmentPadding = 0
        manualOptionTextView.textContainerInset = .zero
        manualOptionTextView.linkTextAttributes = [
            .foregroundColor: UIColor.highlightBlue
        ]
        manualOptionTextView.delegate = self
        updateManualOptionTextView()
        
        if mode == "auto" {
            radio1ImageView.image = .radioOn1
            radio2ImageView.image = .radioOff1
        } else {
            radio1ImageView.image = .radioOff1
            radio2ImageView.image = .radioOn1
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(manualTapped))
        tap.delegate = self
        manualOptionTextView.superview!.addGestureRecognizer(tap)
    }
    
    private func updateManualOptionTextView() {
        let text: String
        if savedEmotions.isEmpty {
            text = "Выберите от 1 до 12 эмоций, которые всегда будут отображаться на панели."
            manualOptionTextView.text = text
        } else {
            text = "Выберите от 1 до 12 эмоций, которые всегда будут отображаться на панели. Поменять выбранные эмоции."
            let attributedString = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: UIColor.textGrey60])
            let linkRange = (text as NSString).range(of: "Поменять выбранные эмоции.")
            attributedString.addAttribute(.link, value: "app://emotions_panel", range: linkRange)
            manualOptionTextView.attributedText = attributedString
        }
        manualOptionHeight.constant = text.height(withWidth: UIScreen.main.bounds.width - 80, font: UIFont.systemFont(ofSize: 12, weight: .medium))
    }
    
    private func openManualSetup() {
        let vc = storyboard!.instantiateViewController(withIdentifier: "EmotionsPanelVC") as! EmotionsPanelViewController
        let window = UIApplication.shared.windows.first
        let top = (window?.safeAreaInsets.top ?? 20) + 84
        vc.savedEmotions = savedEmotions
        vc.onEmotionsSelected = { [unowned self] emotions in
            savedEmotions = emotions
            updateManualOptionTextView()
        }
        presentBottomSheet(vc, height: UIScreen.main.bounds.height - top)
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func option1Tapped(_ sender: Any) {
        if mode != "auto" {
            mode = "auto"
            radio1ImageView.image = .radioOn1
            radio2ImageView.image = .radioOff1
        }
    }
    
    @IBAction func option2Tapped(_ sender: Any) {
        if mode != "manual" {
            mode = "manual"
            radio1ImageView.image = .radioOff1
            radio2ImageView.image = .radioOn1
            if savedEmotions.isEmpty {
                openManualSetup()
            }
        }
    }
    
    @objc func manualTapped(_ gesture: UITapGestureRecognizer) {
        option2Tapped(gesture)
    }
    
    @IBAction func saveTapped() {
        UserDefaults.standard.set(mode, forKey: "EmotionsMode")
        onSaved?()
        dismiss(animated: true)
    }
}

extension EmotionSettingsViewController: UITextViewDelegate, UIGestureRecognizerDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.absoluteString == "app://emotions_panel" {
            openManualSetup()
            return false
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
