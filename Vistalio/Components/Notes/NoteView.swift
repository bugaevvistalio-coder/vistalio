//
//  NoteView.swift
//  Vistalio
//
//  Created by Julia Konkova on 15.07.2026.
//

import UIKit

class NoteView: UIView {
    
    @IBOutlet private weak var roundedView: RoundedView!
    
    @IBOutlet private weak var emotionsStackView: UIStackView!
    
    @IBOutlet private weak var emotionsCounterView: UIView!
    @IBOutlet private weak var emotionsCounterLabel: UILabel!
    
    @IBOutlet private weak var emotion1View: EmotionCircleView!
    @IBOutlet private weak var emotion2View: EmotionCircleView!
    @IBOutlet private weak var emotion3View: EmotionCircleView!
    @IBOutlet private weak var emotion4View: EmotionCircleView!
    
    @IBOutlet private weak var mediaCollectionView: UICollectionView!
    @IBOutlet private weak var mediaTop: NSLayoutConstraint!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var titleTop: NSLayoutConstraint!
    
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var textTop: NSLayoutConstraint!
    
    @IBOutlet private weak var dateLabel: UILabel!
    
    var onLongGesture: ((MissionNote, UIImage, CGRect) -> ())?
    
    private var images = [MissionNoteImage]()
    
    private let totalHeight: CGFloat = 224
    private var top: CGFloat = 0
    
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
        backgroundColor = .clear
        
        emotion4View.layer.zPosition = 1
        emotion3View.layer.zPosition = 2
        emotion2View.layer.zPosition = 3
        emotion1View.layer.zPosition = 4
        
        let nib = UINib(nibName: "NoteSmallPhotoCell", bundle: nil)
        mediaCollectionView.register(nib, forCellWithReuseIdentifier: "NoteSmallPhotoCell")
    }
    
    var note: MissionNote! {
        didSet {
            top = 0
            
            if !(roundedView.gestureRecognizers?.contains(longGestureRecognizer) ?? false) {
                roundedView.addGestureRecognizer(longGestureRecognizer)
            }
            
            dateLabel.text = note.date!.formatted3
            displayEmotions()
            
            images = note.images?.allObjects.map { $0 as! MissionNoteImage }.sorted { $0.date > $1.date } ?? []
            if images.isEmpty {
                mediaCollectionView.isHidden = true
            } else {
                mediaCollectionView.isHidden = false
                mediaTop.constant = top - 6
                mediaCollectionView.reloadData()
                top += 70
            }
            
            if note.name?.isEmpty ?? true {
                titleLabel.isHidden = true
            } else {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineHeightMultiple = 0.9
                let font = UIFont.systemFont(ofSize: 16, weight: .semibold)
                titleLabel.attributedText = NSAttributedString(string: note.name!, attributes: [.font: font as Any, .paragraphStyle: paragraphStyle as Any])
                
                titleLabel.isHidden = false
                titleTop.constant = top
                
                let availableHeight = totalHeight - top - 46
                let lineHeight = font.lineHeight * 0.9
                titleLabel.numberOfLines = Int(floor(availableHeight / lineHeight))
                
                let width = (UIScreen.main.bounds.width - 24)/2 - 24
                let realNumberOfLines = min(titleLabel.calculateMaxLines(width: width, lineHeightMultiple: 0.9), titleLabel.numberOfLines)
                top += (lineHeight * CGFloat(realNumberOfLines))
                top += 4
            }
            
            let availableHeight = totalHeight - top - 46
            
            if note.text?.isEmpty ?? true || availableHeight < textLabel.font.lineHeight {
                textLabel.isHidden = true
            } else {
                textLabel.isHidden = false
                textLabel.text = note.text
                textTop.constant = top
                textLabel.numberOfLines = Int(floor(availableHeight / textLabel.font.lineHeight))
            }
        }
    }
    
    private func displayEmotions() {
        var displayedEmotions = note.emotions?.allObjects.map { $0 as! MissionNoteEmotion }.sorted { $0.date > $1.date } ?? []
        if displayedEmotions.isEmpty {
            emotionsStackView.isHidden = true
            top = 22
            return
        }
        emotionsStackView.isHidden = false
        top = 54
        
        if displayedEmotions.count > 4 {
            emotionsCounterView.isHidden = false
            emotionsCounterLabel.text = "+\(displayedEmotions.count - 3)"
            displayedEmotions = Array(displayedEmotions.prefix(3))
        } else {
            emotionsCounterView.isHidden = true
        }
        let views = [emotion1View, emotion2View, emotion3View, emotion4View]
        for i in 0..<views.count {
            let v = views[i]!
            if displayedEmotions.count > i {
                v.emotion = MissionEmotion(rawValue: displayedEmotions[i].emotion)
                v.isHidden = false
            } else {
                v.isHidden = true
            }
        }
    }
    
    @IBAction func tapped(_ sender: Any) {
        if parentViewController?.sheetViewController != nil {
            let note = note!
            parentViewController?.dismiss(animated: false) {
                UIApplication.topViewController()?.openNote(note)
            }
        } else {
            parentViewController?.openNote(note)
        }
    }
    
    private lazy var longGestureRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
    }()
    
    @objc private func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            if let origin = roundedView.superview?.convert(roundedView.frame.origin, to: nil) {
                roundedView.backgroundColor = .white
                onLongGesture?(note, roundedView.toImage(rect: roundedView.bounds), CGRect(origin: origin, size: roundedView.frame.size))
            }
        }
    }
}

extension NoteView: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoteSmallPhotoCell", for: indexPath) as! NoteSmallPhotoCell
        let image = images[indexPath.row]
        if let path = image.path {
            let type = (path.lowercased().hasSuffix(".mp4") || path.lowercased().hasSuffix(".mov")) ? "video" : "image"
            cell.media = MediaData(type: type, image: nil, path: path)
        }
        cell.canRemove = false
        
        if indexPath.row % 3 == 1 {
            cell.rotationDegrees = -5
        } else if indexPath.row % 3 == 2 {
            cell.rotationDegrees = 5
        } else {
            cell.rotationDegrees = 0
        }
        
        return cell
    }
}
