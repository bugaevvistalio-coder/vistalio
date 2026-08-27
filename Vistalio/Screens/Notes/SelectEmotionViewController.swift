//
//  SelectEmotionViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 04.07.2026.
//

import UIKit

class SelectEmotionViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var addNoteButton: UIControl!
    
    @IBOutlet weak var bottomGradientView: UIView!
    
    private var panelEmotions = [MissionEmotion]()
    private var emotions = [MissionEmotion]()
    
    var isNoteCreation = false
    var selectedEmotions = [MissionEmotion]()
    var onEmotionsSelected: (([MissionEmotion]) -> ())?

    private var showAll = false
    private lazy var flowLayout: EmotionPositionFlowLayout = {
        return EmotionPositionFlowLayout(emotions: emotions)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        settingsButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        setupBottomConstraint(saveButton)
        setupBottomConstraint(buttonsStackView)
        bottomGradientView.applyBottomGradient(color: .white)
        
        saveButton.isHidden = isNoteCreation
        buttonsStackView.isHidden = !isNoteCreation
        
        let window = UIApplication.shared.windows.first
        var bottom = window?.safeAreaInsets.bottom ?? 0
        if bottom == 0 {
            bottom = 20
        }
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50 + bottom, right: 0)
        
        updatePanel(reload: false)
        
        collectionView.collectionViewLayout = flowLayout
        updateButtonsOnSelection()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let nc = navigationController as? CreateNoteNavigationController {
            nc.emotions = MissionEmotion.allCases.filter { selectedEmotions.contains($0) }
        }
    }
    
    private func updatePanel(reload: Bool) {
        if (UserDefaults.standard.string(forKey: "EmotionsMode") ?? "auto") == "auto" {
            buildAutoEmotions()
        } else {
            buildManualEmotions()
        }
        if showAll {
            emotions = MissionEmotion.allCases
        } else {
            emotions = panelEmotions
        }
        if reload {
            flowLayout.emotions = emotions
            collectionView.reloadData()
        }
    }
    
    private func buildAutoEmotions() {
        panelEmotions.removeAll()
        
        let request = SelectedEmotion.selectedEmotionFetchRequest()
        request.predicate = NSPredicate(format: "auto == YES")
        var selectedEmotions = [SelectedEmotion]()
        do {
            selectedEmotions = try CoreDataStack.shared.mainContext.fetch(request)
        } catch {
            print("Failed to retrive missions and folders")
        }
        for g in EmotionGroup.allCases {
            var groupEmotions = Array(g.emotions.prefix(3))
            let selected = selectedEmotions.filter { $0.group == g.rawValue }.sorted { $0.date < $1.date }
            if selected.count > 0 {
                groupEmotions.removeLast(selected.count)
                selected.forEach {
                    groupEmotions.append(MissionEmotion(rawValue: $0.emotion)!)
                }
            }
            panelEmotions.append(contentsOf: groupEmotions)
        }
    }
    
    private func buildManualEmotions() {
        let request = SelectedEmotion.selectedEmotionFetchRequest()
        request.predicate = NSPredicate(format: "auto == NO")
        do {
            let emotions = try CoreDataStack.shared.mainContext.fetch(request).map { $0.emotion }
            panelEmotions = MissionEmotion.allCases.filter { emotions.contains($0.rawValue) }
        } catch {
            print("Failed to retrive missions and folders")
        }
    }
    
    private func updateButtonsOnSelection() {
        UIView.performWithoutAnimation {
            if selectedEmotions.count > 0 {
                saveButton.setTitle("Сохранить (\(selectedEmotions.count))", for: .normal)
            } else {
                saveButton.setTitle("Сохранить", for: .normal)
            }
            saveButton.layoutIfNeeded()
        }
        addNoteButton.isHidden = selectedEmotions.isEmpty
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func settingsTapped(_ sender: Any) {
        let vc = storyboard!.instantiateViewController(withIdentifier: "EmotionSettingsVC") as! EmotionSettingsViewController
        vc.onSaved = { [unowned self] in
            updatePanel(reload: true)
        }
        presentFullScreen(vc)
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        onEmotionsSelected?(MissionEmotion.allCases.filter { selectedEmotions.contains($0) })
        dismiss(animated: true)
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        let vc = storyboard!.instantiateViewController(withIdentifier: "CreateNoteVC") as! CreateNoteViewController
        vc.emotions = MissionEmotion.allCases.filter { selectedEmotions.contains($0) }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func addNoteTapped(_ sender: Any) {
        var note: MissionNote?
        CoreDataStack.shared.performAndWait { [unowned self] context in
            if let mission = MissionsHolder.shared.getNotesMission(context: context), let step = mission.getNotesStep() {
                note = MissionNote.create(context: context, step: step, date: Date(), name: nil, text: nil, emotions: selectedEmotions, media: [])
            }
        }
        if let note = note {
            NotificationCenter.default.post(name: .noteUpdated, object: note)
            
            let presenting = presentingViewController
            (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Заметка добавлена", secondaryText: "К заметке →") {
                presenting?.openNote(note)
            }
        }
        self.dismiss(animated: true)
    }
}

extension SelectEmotionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emotions.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == emotions.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ModeCell", for: indexPath) as! EmotionsModeCell
            cell.onSwitchMode = { [unowned self] in
                showAll = !showAll
                emotions = showAll ? MissionEmotion.allCases : panelEmotions
                flowLayout.emotions = emotions
                flowLayout.showAll = showAll
                collectionView.reloadData()
            }
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmotionCell", for: indexPath) as! SelectEmotionCell
        cell.emotion = emotions[indexPath.row]
        cell.isEmotionSelected = selectedEmotions.contains(cell.emotion)
        if showAll {
            let firstEmotions = EmotionGroup.allCases.map { $0.emotions.first! }
            cell.isSmall = !firstEmotions.contains(cell.emotion)
            print("Emotion \(cell.emotion.rawValue)")
        } else {
            cell.isSmall = false
        }
        cell.updateBorders()
        cell.onEmotionSelected = { [unowned self] emotion, selected in
            if selected {
                selectedEmotions.append(emotion)
            } else {
                selectedEmotions.removeAll { $0 == emotion }
            }
            updateButtonsOnSelection()
        }
        return cell
    }
}

class EmotionPositionFlowLayout: UICollectionViewFlowLayout {
    
    var emotions = [MissionEmotion]() {
        didSet {
            calculateTopY()
        }
    }
    
    var showAll = false
    private var topY = 0
    private var emotionWidth = 0
    private var smallEmotionWidth = 0
    private let spacing = 3
    private let smallSpacing = 3
    private var topOffset: CGFloat = 0
    
    init(emotions: [MissionEmotion], showAll: Bool = false, topOffset: CGFloat = 0) {
        super.init()
        self.emotions = emotions
        self.showAll = showAll
        self.topOffset = topOffset

        emotionWidth = (Int(UIScreen.main.bounds.width) - 20 - spacing * 2) / 3
        smallEmotionWidth = (Int(UIScreen.main.bounds.width) - 20 - smallSpacing * 3) / 4
        calculateTopY()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var cache: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private var contentSize: CGSize = .zero
    
    private func calculateTopY() {
        let window = UIApplication.shared.windows.first
        let top = (window?.safeAreaInsets.top ?? 20)
        let bottom = (window?.safeAreaInsets.bottom ?? 20)
        let fullHeight = Int(UIScreen.main.bounds.height - top - 52 - bottom)
        
        var rowsCount = emotions.count / 3
        if emotions.count % 3 > 0 {
            rowsCount += 1
        }
        
        let emotionsHeight = rowsCount * emotionWidth + (rowsCount - 1) * spacing
        let minY = 72
        topY = max(0, (fullHeight - emotionsHeight)/2 - minY)
        let collectionViewHeight = fullHeight - minY
        if topY + 96 > collectionViewHeight {
            topY = max(0, collectionViewHeight - 96 - emotionsHeight)
        }
    }
       
    override var collectionViewContentSize: CGSize {
        return contentSize
    }
    
    override func prepare() {
        cache.removeAll()
        
        guard let collectionView = collectionView else { return }
        let itemCount = collectionView.numberOfItems(inSection: 0)
        
        if showAll {
            var height: CGFloat = 0
            for (i, group) in EmotionGroup.allCases.enumerated() {
                let rowsCount = ((group.emotions.count - 1) + 3) / 4
                height += CGFloat(emotionWidth + 12)
                height += CGFloat(rowsCount * (smallEmotionWidth + smallSpacing))
                if i > 0 {
                    height += CGFloat(12 - smallSpacing)
                }
            }
            height -= CGFloat(smallSpacing)
            contentSize = CGSize(width: UIScreen.main.bounds.width, height: height)
        } else {
            var rowsCount = emotions.count / 3
            if emotions.count % 3 > 0 {
                rowsCount += 1
            }
            contentSize = CGSize(width: UIScreen.main.bounds.width, height: CGFloat(topY + rowsCount * emotionWidth + (rowsCount - 1) * spacing))
        }
        if itemCount > emotions.count {
            contentSize.height += 96
        }
        if topOffset > 0 {
            contentSize.height += topOffset
        }
        
        for i in 0..<itemCount {
            let indexPath = IndexPath(item: i, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            
            if showAll {
                attributes.frame = frameForAllMode(index: i)
            } else {
                attributes.frame = frameForPanelMode(index: i)
            }
            if topOffset > 0 {
                attributes.frame.origin.y += topOffset
            }
            cache[indexPath] = attributes
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache.values.filter { $0.frame.intersects(rect) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath]
    }
    
    private func frameForPanelMode(index: Int) -> CGRect {
        var frame = CGRect.zero
        
        var rowsCount = emotions.count / 3
        if emotions.count % 3 > 0 {
            rowsCount += 1
        }
        
        if index == emotions.count {
            frame.origin.x = 0
            frame.origin.y = CGFloat(topY + rowsCount * emotionWidth + (rowsCount - 1) * spacing)
            frame.size = CGSize(width: UIScreen.main.bounds.width, height: 96)
        } else {
            let row = index / 3
            var itemsInRow = 3
            if row == rowsCount - 1 {
                itemsInRow = emotions.count - (rowsCount - 1) * 3
            }
            
            let leftX = (Int(UIScreen.main.bounds.width) - itemsInRow * emotionWidth - (itemsInRow - 1) * spacing) / 2
            let column = index % 3
            frame.origin.x = CGFloat(leftX + column * (emotionWidth + spacing))
            frame.origin.y = CGFloat(topY + row * emotionWidth + row * spacing)
            frame.size = CGSize(width: emotionWidth, height: emotionWidth)
        }
        return frame
    }
    
    private func frameForAllMode(index: Int) -> CGRect {
        var frame = CGRect.zero

        if index == emotions.count {
            frame.origin.x = 0
            frame.origin.y = collectionViewContentSize.height - 96
            frame.size = CGSize(width: UIScreen.main.bounds.width, height: 96)
        } else {
            var topY = 0
            var itemsInRowCount = 0
            for i in 0..<emotions.count {
                let emotion = emotions[i]
                let group = emotion.group
                let lastRowItemsCount = (group.emotions.count - 1) % 4
                let indexInGroup = group.emotions.firstIndex(of: emotion)!
                let rowsCount = ((group.emotions.count - 1) + 3) / 4
                let isLastRaw = (indexInGroup - 1) >= (rowsCount - 1) * 4
                
                if indexInGroup == 0 {
                    if i > 0 {
                        topY += (12 - smallSpacing)
                    }
                    if i == index {
                        frame.origin.x = (UIScreen.main.bounds.width - CGFloat(emotionWidth))/2
                        frame.origin.y = CGFloat(topY)
                        frame.size = CGSize(width: emotionWidth, height: emotionWidth)
                    }
                    topY += (emotionWidth + 12)
                } else {
                    if i == index {
                        var offset: CGFloat = 10
                        if isLastRaw && lastRowItemsCount > 0 {
                            offset = (UIScreen.main.bounds.width - CGFloat(lastRowItemsCount * smallEmotionWidth + (lastRowItemsCount - 1) * smallSpacing)) / 2
                        }
                        frame.origin.x = offset + CGFloat(itemsInRowCount * (smallEmotionWidth + smallSpacing))
                        frame.origin.y = CGFloat(topY)
                        frame.size = CGSize(width: smallEmotionWidth, height: smallEmotionWidth)
                    }
                    itemsInRowCount += 1
                    if itemsInRowCount == 4 || indexInGroup == group.emotions.count - 1 {
                        topY += (smallEmotionWidth + smallSpacing)
                        itemsInRowCount = 0
                    }
                }
                
                if i == index {
                    break
                }
            }
        }
        return frame
    }
}
