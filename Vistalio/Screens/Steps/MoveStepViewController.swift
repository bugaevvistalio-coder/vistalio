//
//  MoveStepViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 29.06.2026.
//

import UIKit

class MoveStepViewController: UIViewController {

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var saveButton: UIButton!
    
    var step: MissionStep!
    var onMoved: (() -> ())?
    
    private var segmentedControl: SegmentedControl?
    
    private var allMissions = [Mission]()
    private var missions = [Mission]()
    private var tabSelected = 0
    private var selectedMission: Mission?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        setupBottomConstraint(saveButton)
        
        let window = UIApplication.shared.windows.first
        var bottom = window?.safeAreaInsets.bottom ?? 0
        if bottom == 0 {
            bottom = 20
        }
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70 + bottom, right: 0)
        
        allMissions = MissionsHolder.shared.getMyMissions()
        if step.block.mission.archived {
            missions = allMissions.filter { $0.archived }
            tabSelected = 1
        } else {
            missions = allMissions.filter { !$0.archived }
        }
        
        selectedMission = step.block.mission
        let selectionIndex = missions.firstIndex { $0.objectID == step.block.mission.objectID } ?? 0
        let indexPath = IndexPath(row: selectionIndex, section: 1)
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func saveTapped() {
        guard let mission = selectedMission else {
            return
        }
        if mission.objectID == step.block.mission.objectID {
            dismiss(animated: true)
            return
        }
        CoreDataStack.shared.performAndWait { context in
            if let originalBlock = step.originalBlock, originalBlock.mission.objectID == mission.objectID {
                step.block = originalBlock
            } else {
                let blocks = mission.blocks?.allObjects.map { $0 as! StepsBlock } ?? []
                guard let block = blocks.first(where: { $0.id == -1 }) ?? StepsBlock.create(context: context, mission: mission) else {
                    return
                }
                if step.originalBlock == nil {
                    step.originalBlock = step.block
                }
                step.block = block
            }
        }
        onMoved?()
        dismiss(animated: true)
    }
}

extension MoveStepViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return missions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeaderCell", for: indexPath)
            
            if segmentedControl == nil {
                segmentedControl = cell.viewWithTag(1) as? SegmentedControl
                segmentedControl?.selectedIndex = tabSelected
                segmentedControl?.tabs = [SegmentedTabData(text: "Активные", image: .bell), SegmentedTabData(text: "Архив", image: .archive, tooltip: "Здесь собраны неактивные или завершённые миссии и «Общие заметки». Они не появляются в рекомендациях и для них отключены напоминания.")]
                segmentedControl?.onTabSelected = { [unowned self] index in
                    self.tabSelected = index
                    self.missions = self.allMissions.filter { index == 1 ? $0.archived : !$0.archived }
                    self.collectionView.reloadData()
                    
                    if let mission = selectedMission, mission.archived == (index == 1) {
                        let selectionIndex = missions.firstIndex { $0.objectID == mission.objectID } ?? 0
                        let indexPath = IndexPath(row: selectionIndex, section: 1)
                        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
                    }
                }
            }
        
            return cell
        }
       
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MissionCell", for: indexPath) as! MyMissionCell
        let mission = missions[indexPath.row]
        cell.mission = mission
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedMission = missions[indexPath.row]
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width
        if indexPath.section == 0 {
            return CGSize(width: width - 20, height: 84)
        }
        let size = (width - 24) / 2
        return CGSize(width: size, height: 194)
    }
}
