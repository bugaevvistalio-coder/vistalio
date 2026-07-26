//
//  AddNoteView.swift
//  Vistalio
//
//  Created by Julia Konkova on 02.07.2026.
//

import UIKit
import PhotosUI

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
    
    @IBOutlet private weak var mediaCollectionView: UICollectionView!
    
    var step: MissionStep?
    var mission: Mission?
    var onHeightChanged: (() -> ())?
    var onCursorPositionChanged: ((UITextView, CGRect) -> ())?
    var onNoteAdded: ((MissionNote) -> ())?
    
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
    
    private var media = [MediaData]()
    
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
        
        let nib = UINib(nibName: "NoteBigPhotoCell", bundle: nil)
        mediaCollectionView.register(nib, forCellWithReuseIdentifier: "NoteBigPhotoCell")
        mediaCollectionView.isHidden = true
    }
    
    deinit {
        media.forEach {
            if let path = $0.path {
                let url = FilesHelper().buildFileUrl(path: path)
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
    
    var date: Date? {
        didSet {
            dateLabel.text = date?.formatted3
        }
    }
    
    var hasData: Bool {
        return !titleTextView.text.trim().isEmpty || !bodyTextView.text.trim().isEmpty || !media.isEmpty || !emotions.isEmpty || !date!.isSameDay(Date())
    }
    
    func save() {
        if let step = step ?? mission?.getNotesStep() {
            let name = titleTextView.text.trim()
            let text = bodyTextView.text.trim()
            CoreDataStack.shared.performAndWait { [unowned self] context in
                if let note = MissionNote.create(context: context, step: step, date: self.date ?? Date(), name: !name.isEmpty ? name : nil, text: !text.isEmpty ? text : nil, emotions: self.emotions, media: self.media) {
                    DispatchQueue.main.async {
                        self.clear()
                        self.onNoteAdded?(note)
                    }
                }
            }
        }
    }
    
    private func updateMedia() {
        mediaCollectionView.reloadData()
        mediaCollectionView.isHidden = media.count == 0
        buttonsStackView.arrangedSubviews.first!.isHidden = media.count > 0
    }
    
    @IBAction func changeDateTapped(_ sender: UIButton) {
        endEditing(true)
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectDateVC") as! SelectDateViewController
        vc.popupTitle = "Изменить\nдату заметки"
        vc.maxDate = Date()
        vc.selectedDate = date
        vc.onDateSelected = { [unowned self] date in
            self.date = date
        }
        let bottom = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        parentViewController?.presentBottomSheet(vc, height: 400 + bottom)
    }
    
    @IBAction func emotionTapped(_ sender: UIButton) {
        endEditing(true)
        
        let sb = UIStoryboard(name: "Missions", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectEmotionVC") as! SelectEmotionViewController
        vc.selectedEmotions = emotions
        vc.onEmotionsSelected = { [unowned self] emotions in
            self.emotions = emotions
        }
        parentViewController?.presentFullScreen(vc)
    }
    
    @IBAction func addPhotoTapped(_ sender: Any) {
        if titleTextView.isFirstResponder || bodyTextView.isFirstResponder {
            endEditing(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showMediaMenu(sender: sender)
            }
        } else {
            showMediaMenu(sender: sender)
        }
    }
    
    private func showMediaMenu(sender: Any) {
        let mainVC = (UIApplication.shared.keyWindow?.rootViewController as! MainViewController)
        let menuUnderlayControl = mainVC.addMenuUnderlayControl(color: .clear)
        
        let menuView = MenuView()
        menuView.items = [
            MenuItemData(text: "Галерея", image: .gallery, type: .normal, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                parentViewController!.openGallery(delegate: self, limit: 0, video: true)
            }),
            MenuItemData(text: "Камера", image: .camera, type: .normal, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                parentViewController!.openCamera(delegate: self, video: true)
            })
        ]
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(menuView)
        
        let view = (sender is UIButton) ? buttonsStackView.arrangedSubviews.first! : mediaCollectionView!
        var location = view.superview!.convert(view.frame.origin, to: nil)
        if !(sender is UIButton) {
            location.y += 8
        }
        
        let verticalConstraint = Int(location.y) - menuView.height >= 20 ? menuView.bottomAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: location.y - 7) : menuView.topAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: location.y + view.frame.height + 7)
        
        let constraints = [
            menuView.leftAnchor.constraint(equalTo: menuUnderlayControl.leftAnchor, constant: 22),
            verticalConstraint,
        ]
        NSLayoutConstraint.activate(constraints)
        
        menuView.setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 30, shadowOpacity: 0.22)
    }
    
    @IBAction func addLocationTapped(_ sender: Any) {
        endEditing(true)
    }
    
    @IBAction func addAudioTapped(_ sender: Any) {
        endEditing(true)
    }
    
    @IBAction func okTapped(_ sender: Any) {
        endEditing(true)
        if step != nil {
            save()
        } else {
            let sb = UIStoryboard(name: "Missions", bundle: nil)
            let vc = sb.instantiateViewController(identifier: "MoveNoteVC") as! MoveNoteViewController
            vc.step = step
            vc.mission = mission
            vc.onMoved = { [unowned self] mission, step in
                self.step = step
                save()
            }
            parentViewController?.presentFullScreen(vc)
        }
    }
    
    private func clear() {
        emotions = []
        date = Date()
        media.removeAll()
        titleTextView.text = nil
        bodyTextView.text = nil
        mediaCollectionView.reloadData()
        mediaCollectionView.isHidden = true
        for v in buttonsStackView.arrangedSubviews {
            v.isHidden = false
        }
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

extension AddNoteView: PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        picker.dismiss(animated: true)
        
        for result in results {
            let provider = result.itemProvider
            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                    guard let `self` = self else {
                        return
                    }
                    guard let url = url else {
                        print("Error loading video: \(String(describing: error))")
                        return
                    }
                    
                    let path = "\(self.step?.block.mission.name ?? self.mission?.name ?? "Notes")/\(url.lastPathComponent)"
                    let destinationURL = FilesHelper().buildFileUrl(path: path)
                    
                    do {
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.removeItem(at: destinationURL)
                        }
                        try FileManager.default.copyItem(at: url, to: destinationURL)
                        
                        DispatchQueue.main.async { [weak self] in
                            if let snapshot = createVideoSnapshot(from: destinationURL) {
                                self?.media.insert(MediaData(type: "video", image: snapshot, path: path), at: 0)
                                self?.updateMedia()
                            }
                        }
                    } catch {
                        print("File copy error: \(error)")
                    }
                }
            } else if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { (image, error) in
                    if let selectedImage = image as? UIImage {
                        DispatchQueue.main.async { [weak self] in
                            self?.media.insert(MediaData(type: "image", image: selectedImage, path: nil), at: 0)
                            self?.mediaCollectionView.insertItems(at: [IndexPath(row: 1, section: 0)])
                            self?.mediaCollectionView.isHidden = false
                            self?.buttonsStackView.arrangedSubviews.first!.isHidden = true
                        }
                    }
                }
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [unowned self] in
            let mediaType = info[.mediaType] as! String
            if mediaType == "public.image" {
                if let image = info[.originalImage] as? UIImage {
                    media.insert(MediaData(type: "image", image: image, path: nil), at: 0)
                }
            } else if mediaType == "public.movie" {
                if let videoURL = info[.mediaURL] as? URL {
                    if let snapshot = createVideoSnapshot(from: videoURL) {
                        let path = "\(self.step?.block.mission.name ?? self.mission?.name ?? "Notes")/\(videoURL.lastPathComponent)"
                        let destinationURL = FilesHelper().buildFileUrl(path: path)
                        print("Save camera video \(path)")
                        do {
                            try FileManager.default.copyItem(at: videoURL, to: destinationURL)
                        } catch {
                            print("File copy error: \(error)")
                        }
                        media.insert(MediaData(type: "video", image: snapshot, path: path), at: 0)
                    }
                }
            }
            updateMedia()
        }
    }
}

extension AddNoteView: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return media.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoteBigPhotoCell", for: indexPath) as! NoteBigPhotoCell
        if indexPath.row == 0 {
            cell.media = nil
            cell.canRemove = false
            cell.onTapped = { [unowned self] in
                addPhotoTapped(cell)
            }
        } else {
            cell.media = media[indexPath.row - 1]
            cell.canRemove = true
            cell.onTapped = nil
        }
        if indexPath.row % 3 == 1 {
            cell.rotationDegrees = -5
        } else if indexPath.row % 3 == 2 {
            cell.rotationDegrees = 5
        } else {
            cell.rotationDegrees = 0
        }
        cell.onRemove = { [unowned self] item in
            media.removeAll { $0.image === item.image }
            updateMedia()
        }
        return cell
    }
}
