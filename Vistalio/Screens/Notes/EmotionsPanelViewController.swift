//
//  Untitled.swift
//  Vistalio
//
//  Created by Julia Konkova on 12.07.2026.
//

import UIKit

class EmotionsPanelViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var selectionLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var saveButton: UIControl!
    @IBOutlet weak var saveButtonLabel1: UILabel!
    @IBOutlet weak var saveButtonLabel2: UILabel!
    @IBOutlet weak var topGradientView: UIView!
    
    private var emotions = MissionEmotion.allCases
    private var selectionAvailable = true
    private var selectedEmotions = [MissionEmotion]()
    
    var savedEmotions = [SelectedEmotion]()
    var onEmotionsSelected: (([SelectedEmotion]) -> ())?
    
    private lazy var flowLayout: EmotionPositionFlowLayout = {
        return EmotionPositionFlowLayout(emotions: emotions, showAll: true, topOffset: 16)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        setupBottomConstraint(saveButton)
        topGradientView.setGradientLayer(colors: [.white, .white.withAlphaComponent(0.01)], startPoint: CGPoint(x: 0.5, y: 0.0), endPoint: CGPoint(x: 0.5, y: 1.0), cornerRadius: 0)
        
        let window = UIApplication.shared.windows.first
        var bottom = window?.safeAreaInsets.bottom ?? 0
        if bottom == 0 {
            bottom = 20
        }
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 88 + bottom, right: 0)
        collectionView.collectionViewLayout = flowLayout
        
        selectedEmotions = savedEmotions.map { MissionEmotion(rawValue: $0.emotion)! }
        if selectedEmotions.isEmpty {
            selectedEmotions = EmotionGroup.allCases.flatMap { Array($0.emotions.prefix(3)) }
        }
        
        onSelectionChanged(canReload: false)
    }
    
    private func onSelectionChanged(canReload: Bool = true) {
        selectionLabel.text = "Выбрано \(selectedEmotions.count)"
        if selectedEmotions.isEmpty {
            saveButton.isEnabled = false
            saveButton.backgroundColor = .bgGrey
            saveButtonLabel1.textColor = .textGrey30
            saveButtonLabel2.textColor = .textGrey30
        } else {
            saveButton.isEnabled = true
            saveButton.backgroundColor = .darkGrey
            saveButtonLabel1.textColor = .white
            saveButtonLabel2.textColor = .white.withAlphaComponent(0.4)
        }
        let previousSelectionAvailable = selectionAvailable
        selectionAvailable = selectedEmotions.count < 12
        if previousSelectionAvailable != selectionAvailable && canReload {
            collectionView.reloadData()
        }
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func cleanTapped(_ sender: Any) {
        selectedEmotions.removeAll()
        onSelectionChanged(canReload: false)
        collectionView.reloadData()
    }
    
    @IBAction func saveTapped() {
        CoreDataStack.shared.performAndWait { [unowned self] context in
            savedEmotions.forEach { context.delete($0) }
            selectedEmotions.forEach {
                let emotion = SelectedEmotion.create(context: context, emotion: $0, auto: false)!
                savedEmotions.append(emotion)
            }
        }
        onEmotionsSelected?(savedEmotions)
        dismiss(animated: true)
    }
}

extension EmotionsPanelViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emotions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmotionCell", for: indexPath) as! SelectEmotionCell
        cell.emotion = emotions[indexPath.row]
        cell.isEmotionSelected = selectedEmotions.contains(cell.emotion)
        let firstEmotions = EmotionGroup.allCases.map { $0.emotions.first! }
        cell.isSmall = !firstEmotions.contains(cell.emotion)
        cell.updateBorders()
        cell.onEmotionSelected = { [unowned self] emotion, selected in
            if selected {
                selectedEmotions.append(emotion)
            } else {
                selectedEmotions.removeAll { $0 == emotion }
            }
            onSelectionChanged()
        }
        cell.contentView.isUserInteractionEnabled = selectionAvailable || cell.isEmotionSelected
        cell.contentView.alpha = (selectionAvailable || cell.isEmotionSelected) ? 1 : 0.6
        return cell
    }
}
