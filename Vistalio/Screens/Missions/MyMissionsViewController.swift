//
//  MyMissionsViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 15.04.2026.
//

import UIKit

class MyMissionsViewController: UIViewController {
    
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var segmentedControl: SegmentedControl?
    private var addMissionButton: UIButton?
    
    @IBOutlet weak var emptyArchiveView: UIView!
    @IBOutlet weak var emptyArchiveCircle: UIView!
    
    private var allMissions = [Mission]()
    private var missions = [Mission]()
    private var tabSelected = 0
    
    private let generator = UIImpactFeedbackGenerator(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        emptyArchiveCircle.setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 20, shadowOpacity: 0.22)
        
        navBar.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        navBar.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 30, shadowOpacity: 0.1)
        
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        emptyArchiveView.isHidden = true
        
        allMissions = MissionsHolder.shared.getMyMissions()
        missions = allMissions.filter { !$0.archived }
        
        generator.prepare()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onMissionUpdated(notification:)), name: .missionUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onNoteAdded(notification:)), name: .noteUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .missionUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: .noteUpdated, object: nil)
    }
    
    @IBAction func backTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func addMissionTapped(_ sender: Any) {
        let nc = storyboard!.instantiateViewController(identifier: "CreateMissionNC") as! UINavigationController
        let vc = nc.viewControllers.first as! CreateMissionViewController
        vc.onMissionCreated = { [unowned self] mission in
            self.openMission(mission)
        }
        
        let window = UIApplication.shared.windows.first
        let top = (window?.safeAreaInsets.top ?? 20)
        presentBottomSheet(nc, height: UIScreen.main.bounds.height - top)
    }
    
    @objc func onMissionUpdated(notification: Notification) {
        updateMissions()
    }
    
    @objc func onNoteAdded(notification: Notification) {
        let notesCategory = MissionCategory.notes.rawValue
        if let note = notification.object as? MissionNote, note.step?.block.mission.category == notesCategory, missions.last?.category != notesCategory {
            updateMissions()
        }
    }
    
    private func updateMissions() {
        self.allMissions = MissionsHolder.shared.getMyMissions()
        self.missions = self.allMissions.filter { tabSelected == 1 ? $0.archived : !$0.archived }
        self.collectionView.reloadData()
        self.emptyArchiveView.isHidden = tabSelected != 1 || !self.missions.isEmpty
    }
    
    private func showMenu(mission: Mission, anchorRect: CGRect, image: UIImage) {
        
        let mainVC = (UIApplication.shared.keyWindow?.rootViewController as! MainViewController)
        let menuUnderlayControl = mainVC.addMenuUnderlayControl(color: .black.withAlphaComponent(0.25))
        
        let menuView = MenuView()
        menuView.items = [
            MenuItemData(text: "Изменить", image: .edit, type: .normal, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                openEditMission(mission, onMissionUpdated: nil)
            }),
            MenuItemData(text: mission.archived ? "Убрать из архива" : "В архив", image: mission.archived ? .unarchive : .archive, type: .normal, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                openArchiveMission(mission)
            }),
            MenuItemData(text: "Удалить", image: .trash, type: .red, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                openDeleteMission(mission)
            })
        ]
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(menuView)
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let menuHeight = CGFloat(menuView.height)
        let horizontalConstraint = anchorRect.minX < screenWidth/2 ? menuView.leftAnchor.constraint(equalTo: menuUnderlayControl.leftAnchor, constant: anchorRect.minX) : menuView.rightAnchor.constraint(equalTo: menuUnderlayControl.rightAnchor, constant: anchorRect.maxX - screenWidth)
        let verticalConstraint = anchorRect.maxY + 20 + menuHeight > screenHeight ? menuView.bottomAnchor.constraint(equalTo: menuUnderlayControl.bottomAnchor, constant: anchorRect.minY - 7 - screenHeight) : menuView.topAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: anchorRect.maxY + 7)
        NSLayoutConstraint.activate([verticalConstraint, horizontalConstraint])
        
        menuView.layer.cornerRadius = 30
        
        let highlightedItemImageView = UIImageView()
        highlightedItemImageView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(highlightedItemImageView)
        
        let constraints = [
            highlightedItemImageView.topAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: anchorRect.minY),
            highlightedItemImageView.leftAnchor.constraint(equalTo: menuUnderlayControl.leftAnchor, constant: anchorRect.minX),
            highlightedItemImageView.widthAnchor.constraint(equalToConstant: anchorRect.width),
            highlightedItemImageView.heightAnchor.constraint(equalToConstant: anchorRect.height),
        ]
        NSLayoutConstraint.activate(constraints)
        
        highlightedItemImageView.image = image
    }
}

extension MyMissionsViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        if missions.last?.category == MissionCategory.notes.rawValue && missions.count % 2 == 1 {
            return missions.count + 1
        }
        return missions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeaderCell", for: indexPath)
            
            if segmentedControl == nil {
                segmentedControl = cell.viewWithTag(1) as? SegmentedControl
                segmentedControl?.tabs = [SegmentedTabData(text: "Активные", image: .bell), SegmentedTabData(text: "Архив", image: .archive, tooltip: "Здесь собраны неактивные или завершённые миссии и «Общие заметки». Они не появляются в рекомендациях и для них отключены напоминания.")]
                segmentedControl?.onTabSelected = { [unowned self] index in
                    self.tabSelected = index
                    self.addMissionButton?.superview?.isHidden = (index == 1)
                    self.missions = self.allMissions.filter { index == 1 ? $0.archived : !$0.archived }
                    self.collectionView.reloadData()
                    self.emptyArchiveView.isHidden = index != 1 || !self.missions.isEmpty
                }
            }
            
            addMissionButton = cell.viewWithTag(2) as? UIButton
            addMissionButton?.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 22, fixedBounds: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 36, height: 44))
        
            return cell
        }
       
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MissionCell", for: indexPath) as! MyMissionCell
        if let mission = getMission(index: indexPath.row) {
            cell.mission = mission
            cell.addLongGesture() { [unowned self] image, rect in
                self.generator.impactOccurred()
                self.generator.prepare()
                self.showMenu(mission: mission, anchorRect: rect, image: image)
            }
        } else {
            cell.mission = nil
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let mission = getMission(index: indexPath.row) {
            openMission(mission)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width
        if indexPath.section == 0 {
            return CGSize(width: width - 20, height: tabSelected == 1 ? 88 : 148)
        }
        let size = (width - 24) / 2
        return CGSize(width: size, height: 194)
    }
    
    private func getMission(index: Int) -> Mission? {
        if missions.last?.category == MissionCategory.notes.rawValue {
            if index < missions.count - 1 || missions.count % 2 == 0 {
                return missions[index]
            } else if index == missions.count {
                return missions[index - 1]
            } else {
                return nil
            }
        } else {
            return missions[index]
        }
    }
}
