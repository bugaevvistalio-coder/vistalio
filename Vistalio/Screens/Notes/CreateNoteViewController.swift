//
//  CreateNoteViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 29.07.2026.
//

import UIKit
import PhotosUI
import IQKeyboardManagerSwift

class CreateNoteViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var emotionsFlowView: EmotionsFlowView!
    
    @IBOutlet weak var addEmotionControl: UIControl!
    @IBOutlet private weak var addEmotionInnerView: UIView!
    @IBOutlet private weak var emotionLabel: UILabel!
    
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var changeDateButton: UIButton!
    
    @IBOutlet private weak var titleTextView: GrowingTextView!
    @IBOutlet private weak var bodyTextView: GrowingTextView!
    
    @IBOutlet private weak var finishButtonsStackView: UIStackView!
    @IBOutlet private weak var buttonsStackView: UIStackView!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet private weak var mediaCollectionView: UICollectionView!
    
    var emotions = [MissionEmotion]()
    var note: MissionNote?
    
    private var mediaHolder = MediaHolder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if note != nil {
            backButton.isHidden = true
        } else {
            backButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
            titleLabel.isHidden = true
        }
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        changeDateButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 3, cornerRadius: 10, shadowOpacity: 0.09, bounds: CGRect(x: 0, y: 0, width: 20, height: 20))
        setupBottomConstraint(mainStackView)
        
        for v in self.buttonsStackView.arrangedSubviews {
            if let b = v as? UIButton {
                b.setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 26, shadowOpacity: 0.12, bounds: CGRect(x: 0, y: 0, width: 52, height: 52))
            }
        }
        
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 84, right: 0)
        
        emotionsFlowView.maxWidth = UIScreen.main.bounds.width - 52
        emotionsFlowView.canEdit = (note != nil)
        emotionsFlowView.emotions = emotions
        
        titleTextView.textContainer.lineFragmentPadding = 0
        titleTextView.textContainerInset = .zero
        titleTextView.delegate = self
        
        bodyTextView.textContainer.lineFragmentPadding = 0
        bodyTextView.textContainerInset = .zero
        bodyTextView.delegate = self
        
        if let nc = navigationController as? CreateNoteNavigationController {
            titleTextView.text = nc.noteTitle
            bodyTextView.text = nc.body
            date = nc.date ?? Date()
            mediaHolder = nc.mediaHolder
            saveButton.isHidden = true
            addEmotionControl.removeFromSuperview()
        } else if let note = note {
            emotionsFlowView.emotions = note.emotions?.allObjects.map { $0 as! MissionNoteEmotion }.sorted { $0.date > $1.date }.map { MissionEmotion(rawValue: ($0.emotion))! } ?? []
            titleTextView.text = note.name
            bodyTextView.text = note.text
            date = note.date ?? Date()
            mediaHolder.media = note.images?.allObjects.map { $0 as! MissionNoteImage }.sorted { $0.date > $1.date }.map { $0.mediaData } ?? []
            mediaHolder.media.forEach { $0.saved = true }
            finishButtonsStackView.isHidden = true
            
            addEmotionControl.setShadow(offset: CGSize(width: 0, height: 0), radius: 5, cornerRadius: 20, shadowOpacity: 0.09)
            
            let width = "Эмоция".width(withHeight: 34, font: emotionLabel.font) + 42
            addEmotionInnerView.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 17, fixedBounds: CGRect(x: 0, y: 0, width: width, height: 34))
            addEmotionControl.isHidden = !emotionsFlowView.emotions.isEmpty
            emotionsFlowView.onEdit = { [unowned self] in
                editEmotions()
            }
        } else {
            date = Date()
            saveButton.isHidden = true
            addEmotionControl.removeFromSuperview()
        }
        
        titleTextView.highlightLinks()
        bodyTextView.highlightLinks()
        
        let nib = UINib(nibName: "NoteBiggerPhotoCell", bundle: nil)
        mediaCollectionView.register(nib, forCellWithReuseIdentifier: "NoteBiggerPhotoCell")
        updateMedia()
        
        mediaHolder.onReloadNeeded = { [weak self] indexes in
            self?.mediaCollectionView.reloadItems(at: indexes.map { IndexPath(row: $0 + 1, section: 0) })
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
        
        if note != nil {
            mediaHolder.reset()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        IQKeyboardManager.shared.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared.isEnabled = true
        
        if let nc = navigationController as? CreateNoteNavigationController {
            nc.noteTitle = titleTextView.text.trim()
            nc.body = bodyTextView.text.trim()
            nc.date = date
            nc.mediaHolder = mediaHolder
        }
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        UIView.performWithoutAnimation {
            finishButtonsStackView.isHidden = true
        }
        buttonsStackView.isHidden = true
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
    }
    
    @objc func keyboardDidHide(notification: Notification) {
        finishButtonsStackView.isHidden = false
        buttonsStackView.isHidden = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 84, right: 0)
    }
    
    var date: Date? {
        didSet {
            dateLabel.text = date?.formatted3
        }
    }
    
    @IBAction func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func closeTapped() {
        dismiss(animated: true)
    }
    
    @IBAction func addEmotionTapped() {
        editEmotions()
    }
    
    @IBAction func changeDateTapped(_ sender: UIButton) {
        view.endEditing(true)
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectDateVC") as! SelectDateViewController
        vc.popupTitle = "Изменить\nдату заметки"
        vc.maxDate = Date()
        vc.selectedDate = date
        vc.onDateSelected = { [unowned self] date in
            self.date = date
        }
        let bottom = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        presentBottomSheet(vc, height: 400 + bottom)
    }
    
    @IBAction func addMediaTapped(_ sender: Any) {
        if titleTextView.isFirstResponder || bodyTextView.isFirstResponder {
            view.endEditing(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showMediaMenu(sender: sender)
            }
        } else {
            showMediaMenu(sender: sender)
        }
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        view.endEditing(true)
        
        if mediaHolder.hasUnloadedMedia {
            mediaHolder.warnAboutUnloadedMedia(from: self)
            return
        }
        
        var note: MissionNote?
        let name = titleTextView.text.trim()
        let text = bodyTextView.text.trim()
        
        CoreDataStack.shared.performAndWait { [unowned self] context in
            if let mission = MissionsHolder.shared.getNotesMission(context: context), let step = mission.getNotesStep() {
                note = MissionNote.create(context: context, step: step, date: self.date ?? Date(), name: !name.isEmpty ? name : nil, text: !text.isEmpty ? text : nil, emotions: self.emotions, media: self.mediaHolder.media)
            }
        }
        mediaHolder.media.forEach { $0.saved = true }
        
        if let note = note {
            NotificationCenter.default.post(name: .noteUpdated, object: note)
            
            let presenting = presentingViewController
            (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Заметка добавлена", secondaryText: "К заметке →") {
                presenting?.openNote(note)
            }
        }
        self.dismiss(animated: true)
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        if mediaHolder.hasUnloadedMedia {
            mediaHolder.warnAboutUnloadedMedia(from: self)
            return
        }
        
        let sb = UIStoryboard(name: "Missions", bundle: nil)
        let vc = sb.instantiateViewController(identifier: "MoveNoteVC") as! MoveNoteViewController
        vc.showCalendar = true
        vc.date = date
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func saveChangesTapped(_ sender: Any) {
        view.endEditing(true)
        
        if mediaHolder.hasUnloadedMedia {
            mediaHolder.warnAboutUnloadedMedia(from: self)
            return
        }
        
        guard let note = note else { return }
        
        let name = titleTextView.text.trim()
        let text = bodyTextView.text.trim()
        
        CoreDataStack.shared.performAndWait { [unowned self] context in
            note.date = self.date ?? Date()
            note.name = name
            note.text = text
            
            note.emotions?.allObjects.forEach {
                context.delete($0 as! MissionNoteEmotion)
            }
            emotionsFlowView.emotions.forEach {
                MissionNoteEmotion.create(context: context, note: note, e: $0)
            }
            
            let paths = mediaHolder.media.compactMap { $0.path }
            note.images?.allObjects.forEach {
                if let image = $0 as? MissionNoteImage {
                    if let path = image.path, paths.contains(path) {
                        image.saveImageOnDelete = true
                    }
                    context.delete(image)
                }
            }
            mediaHolder.media.reversed().forEach {
                MissionNoteImage.create(context: context, note: note, media: $0)
                $0.saved = true
            }
        }
        
        NotificationCenter.default.post(name: .noteUpdated, object: note)
        self.dismiss(animated: true)
    }
    
    private func showMediaMenu(sender: Any) {
        let menuUnderlayControl = sheetViewController!.addMenuUnderlayControl(color: .clear)
        
        let menuView = MenuView()
        menuView.items = [
            MenuItemData(text: "Галерея", image: .gallery, type: .normal, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                openGallery(delegate: self, limit: 0, video: true)
            }),
            MenuItemData(text: "Камера", image: .camera, type: .normal, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                openCamera(delegate: self, video: true)
            })
        ]
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(menuView)
        
        let view = (sender is UIButton) ? buttonsStackView.arrangedSubviews.first! : mediaCollectionView!
        var location = view.superview!.convert(view.frame.origin, to: nil)
        if !(sender is UIButton) {
            location.y += 16
        }
        
        let verticalConstraint: NSLayoutConstraint
        if sender is UIButton {
            verticalConstraint = Int(location.y) - menuView.height >= 20 ? menuView.bottomAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: location.y - 20) : menuView.topAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: location.y + view.frame.height + 20)
        } else {
            let buttonsLocation = buttonsStackView.superview!.convert(buttonsStackView.frame.origin, to: nil)
            let showUnder = Int(location.y) + 136 + menuView.height <= Int(buttonsLocation.y - 16)
            verticalConstraint = showUnder ? menuView.topAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: location.y + 136) : menuView.bottomAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: location.y - 20)
        }
        
        let constraints = [
            menuView.leftAnchor.constraint(equalTo: menuUnderlayControl.leftAnchor, constant: 26),
            verticalConstraint,
        ]
        NSLayoutConstraint.activate(constraints)
        
        menuView.setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 30, shadowOpacity: 0.22)
    }
    
    private func updateMedia() {
        mediaCollectionView.reloadData()
        mediaCollectionView.isHidden = mediaHolder.media.count == 0
        buttonsStackView.arrangedSubviews.first!.isHidden = mediaHolder.media.count > 0
    }
    
    private func editEmotions() {
        let sb = UIStoryboard(name: "Missions", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectEmotionVC") as! SelectEmotionViewController
        vc.selectedEmotions = emotionsFlowView.emotions
        vc.onEmotionsSelected = { [unowned self] emotions in
            self.emotionsFlowView.emotions = emotions
            self.addEmotionControl.isHidden = !emotions.isEmpty
        }
        presentFullScreen(vc)
    }
}

extension CreateNoteViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaHolder.media.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoteBiggerPhotoCell", for: indexPath) as! NoteBiggerPhotoCell
        if indexPath.row == 0 {
            cell.plusImage = .plus2
            cell.media = nil
            cell.canRemove = false
            cell.onTapped = { [unowned self] cell in
                addMediaTapped(cell)
            }
        } else {
            cell.media = mediaHolder.media[indexPath.row - 1]
            cell.canRemove = true
            cell.onTapped = { [unowned self] cell in
                guard let currentIndexPath = collectionView.indexPath(for: cell) else { return }
                sheetViewController!.openGallery(media: mediaHolder.media, at: currentIndexPath.row - 1)
            }
        }
        if indexPath.row % 3 == 1 {
            cell.rotationDegrees = -5
        } else if indexPath.row % 3 == 2 {
            cell.rotationDegrees = 5
        } else {
            cell.rotationDegrees = 0
        }
        cell.onRemove = { [unowned self] item in
            mediaHolder.remove(item)
            updateMedia()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return indexPath.row > 0
    }
}

extension CreateNoteViewController: PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        picker.dismiss(animated: true)
        let media = processPickerResults(results, folder: "Notes")
        insertMedia(media)
        mediaHolder.startTimer()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [unowned self] in
            processCameraResults(info: info, folder: "Notes") { [weak self] media in
                self?.insertMedia([media])
            }
        }
    }
    
    private func insertMedia(_ media: [MediaData]) {
        if media.count == 0 {
            return
        }
        
        let indexPaths = (0..<media.count).map { IndexPath(item: $0 + 1, section: 0) }
        self.mediaCollectionView.isHidden = false
        
        self.mediaCollectionView.performBatchUpdates({
            self.mediaHolder.media.insert(contentsOf: media, at: 0)
            self.buttonsStackView.arrangedSubviews.first!.isHidden = self.mediaHolder.media.count > 0
            self.mediaCollectionView.insertItems(at: indexPaths)
        }, completion: { _ in })
    }
}

extension CreateNoteViewController: GrowingTextViewDelegate {

    func textViewDidChangeSelection(_ textView: UITextView) {
        if let selectedRange = textView.selectedTextRange {
            let cursorRect = textView.caretRect(for: selectedRange.start)
            let view = UIView(frame: cursorRect)
            view.alpha = 0
            textView.addSubview(view)
            scrollView.scrollToViewBottom(view)
            view.removeFromSuperview()
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        textView.highlightLinks()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        titleTextView.highlightLinks()
        bodyTextView.highlightLinks()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        DispatchQueue.main.async {
            textView.highlightLinks()
        }
    }
    
}
