//
//  AddNoteView.swift
//  Vistalio
//
//  Created by Julia Konkova on 02.07.2026.
//

import UIKit

class AddNoteView: UIView {
    
    @IBOutlet private weak var addEmotionControl: UIControl!
    @IBOutlet private weak var addEmotionInnerView: UIView!
    @IBOutlet private weak var emotionLabel: UILabel!
    
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var changeDateButton: UIButton!
    @IBOutlet private weak var titleTextView: GrowingTextView!
    @IBOutlet private weak var bodyTextView: GrowingTextView!
    @IBOutlet private weak var buttonsStackView: UIStackView!
    
    @IBOutlet private weak var emotionsStackView: UIStackView!
    @IBOutlet private weak var editEmotionImageView: UIImageView!
    @IBOutlet private weak var emotionsCounterView: UIView!
    @IBOutlet private weak var emotionsCounterLabel: UILabel!
    
    @IBOutlet private weak var emotion1View: EmotionCircleView!
    @IBOutlet private weak var emotion2View: EmotionCircleView!
    @IBOutlet private weak var emotion3View: EmotionCircleView!
    
    
    var onHeightChanged: (() -> ())?
    var onCursorPositionChanged: ((UITextView, CGRect) -> ())?
    
    var emotions = [MissionEmotion]() {
        didSet {
            var displayedEmotions = emotions
            if emotions.count > 3 {
                emotionsCounterView.isHidden = false
                emotionsCounterLabel.text = "+\(emotions.count - 2)"
                displayedEmotions = Array(emotions.prefix(2))
            } else {
                emotionsCounterView.isHidden = true
            }
            let views = [emotion1View, emotion2View, emotion3View]
            for i in 0..<views.count {
                let v = views[i]!
                if displayedEmotions.count > i {
                    v.emotion = displayedEmotions[i]
                    v.isHidden = false
                } else {
                    v.isHidden = true
                }
            }
            editEmotionImageView.image = emotions.isEmpty ? .plus : .edit
        }
    }
    
    private var view: UIView!
    
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
    
    func setup() {
        addEmotionControl.setShadow(offset: CGSize(width: 0, height: 0), radius: 5, cornerRadius: 20, shadowOpacity: 0.09)
        changeDateButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 3, cornerRadius: 8, shadowOpacity: 0.09)
        
        let width = "Эмоция".width(withHeight: 34, font: emotionLabel.font) + 42
        addEmotionInnerView.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 17, fixedBounds: CGRect(x: 0, y: 0, width: width, height: 34))
        
        for v in buttonsStackView.arrangedSubviews {
            if let b = v as? UIButton {
                b.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.09)
            }
        }
        
        titleTextView.textContainer.lineFragmentPadding = 0
        titleTextView.textContainerInset = .zero
        bodyTextView.textContainer.lineFragmentPadding = 0
        bodyTextView.textContainerInset = .zero
        
        titleTextView.delegate = self
        bodyTextView.delegate = self
        
        date = Date()
        emotions = []
    }
    
    var date: Date? {
        didSet {
            dateLabel.text = date?.formatted3
        }
    }
    
    @IBAction func changeDateTapped(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectDateVC") as! SelectDateViewController
        vc.popupTitle = "Изменить\nдату заметки"
        vc.onDateSelected = { [unowned self] date in
            self.date = date
        }
        let bottom = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        parentViewController?.presentBottomSheet(vc, height: 400 + bottom)
    }
    
    @IBAction func emotionTapped(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Missions", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectEmotionVC") as! SelectEmotionViewController
        vc.selectedEmotions = emotions
        vc.onEmotionsSelected = { [unowned self] emotions in
            self.emotions = emotions
        }
        parentViewController?.presentFullScreen(vc)
    }
}

extension AddNoteView: GrowingTextViewDelegate {
    func textViewDidChangeHeight(_ textView: GrowingTextView, height: CGFloat) {
        onHeightChanged?()
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if let selectedRange = textView.selectedTextRange {
            let cursorRect = textView.caretRect(for: selectedRange.start)
            onCursorPositionChanged?(textView, cursorRect)
        }
    }
}
