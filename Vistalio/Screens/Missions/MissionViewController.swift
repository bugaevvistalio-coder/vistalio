//
//  MissionViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 06.04.2026.
//

import UIKit
import AppsFlyerLib

class MissionViewController: UIViewController {
    
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var headerControl: UIControl!
    @IBOutlet weak var headerShadowView: UIView!
    @IBOutlet weak var headerControlHeight: NSLayoutConstraint!
    
    @IBOutlet weak var segmentedControl: SegmentedControl!
    
    @IBOutlet weak var addItemView: UIView!
    @IBOutlet weak var addItemButton: UIButton!
    
    @IBOutlet weak var addNoteView: AddNoteView!
    @IBOutlet weak var addNoteViewBottom: NSLayoutConstraint!
    @IBOutlet weak var addItemButtonBottom: NSLayoutConstraint!
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var aboutLabel: UILabel!
    
    @IBOutlet weak var topBgViewHeight: NSLayoutConstraint!
    @IBOutlet weak var missionInfoTop: NSLayoutConstraint!
    @IBOutlet weak var missionInfoCenterY: NSLayoutConstraint!
    
    @IBOutlet weak var recommendedStepsControl: UIControl!
    @IBOutlet weak var recommendedArrow: UIImageView!
    @IBOutlet weak var addAllStepsView: UIView!
    
    @IBOutlet weak var headerBottom: NSLayoutConstraint!
    
    var mission: Mission!
    
    private var hasNavBarShadow = false
    private var isHeaderExpanded = false
    
    private var recommendedSteps = [MissionStep]()
    private var hiddenSteps = [MissionStep]()
    private var addedSteps = [MissionStep]()
    private var recommendedExpanded = true
    
    private var isEditingNote = false
    
    private let generator = UIImpactFeedbackGenerator(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        addItemButton.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18)
        
        navBar.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        navBar.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 30, shadowOpacity: 0)
        progressIndicator.isHidden = true
        
        headerControl.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        headerShadowView.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 30, shadowOpacity: 0.1)
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        
        setupAddNoteView()
        updateSteps()
        updateAddItemViewVisibility()
        
        segmentedControl.tabs = [SegmentedTabData(text: "Шаги", image: .steps), SegmentedTabData(text: "Заметки", image: .notes)]
        segmentedControl.onTabSelected = { [unowned self] index in
            UIView.performWithoutAnimation {
                self.addItemButton.setTitle(index == 0 ? "Шаг" : "Заметка", for: .normal)
            }
            updateAddItemViewVisibility()
            // Reload data should be before layoutHeader(). Otherwise there will be a crash because cellForRow will be called without
            // numberOfRows. But numberOfRows must be called because tab is changed
            tableView.reloadData()
            updateRecommendedStepsVisibility()
            if index == 0 {
                hideAddNoteView()
            } else {
                if isEditingNote {
                    showAddNoteView()
                }
            }
            updateAddAllSteps()
        }
        
        displayMission()
        updateRecommendedStepsVisibility()
        
        generator.prepare()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onMissionsUpdated(notification:)), name: .missionUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onStepUpdated(notification:)), name: .stepUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onNoteUpdated(notification:)), name: .noteUpdated, object: nil)
    }
    
    deinit {
        print("Mission VC DEINIT")
        NotificationCenter.default.removeObserver(self, name: .missionUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: .stepUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: .noteUpdated, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if segmentedControl.selectedIndex == 0 {
            tableView.reloadSections(IndexSet(arrayLiteral: 3), with: .none)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutHeader()
        addItemButton.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18)
        addAllStepsView.setGradientLayer(colors: [UIColor(hex: "#F0F6FF"), UIColor(hex: "#EAF0FC"), UIColor(hex: "#E8EFFC")], locations: [0.0, 0.25, 0.9], cornerRadius: 16)
        
        if !isHeaderExpanded {
            
            let nameLines = titleLabel.calculateMaxLines()
            
            var aboutLines = 0
            if nameLines == 1 {
                aboutLines = 3
            } else if nameLines == 2 {
                aboutLines = 1
            }
            if aboutLines == 0 || (mission.about?.isEmpty ?? true) {
                aboutLabel.isHidden = true
            } else {
                aboutLabel.numberOfLines = aboutLines
                aboutLabel.isHidden = false
            }
            
            aboutLabel.invalidateIntrinsicContentSize()
            aboutLabel.superview!.layoutIfNeeded()
        }
    }
    
    private func updateRecommendedStepsVisibility() {
        recommendedStepsControl.isHidden = segmentedControl.selectedIndex == 1 || mission.templateId <= 0 || mission.skipRecommend
    }
    
    private func updateAddItemViewVisibility() {
        let hide = (mission.category == MissionCategory.notes.rawValue || (!mission.canCreateSteps && segmentedControl.selectedIndex == 0))
        addItemView.isHidden = hide
        headerBottom.constant = hide ? 0 : 4
    }
    
    private func setupAddNoteView() {
        addNoteView.isHidden = true
        addNoteView.mission = mission
        addNoteView.onHeightChanged = { [unowned self] in
            tableView.layoutHeader()
        }
        addNoteView.onCursorPositionChanged = { [unowned self] textView, rect in
            let view = UIView(frame: rect)
            view.alpha = 0
            textView.addSubview(view)
            tableView.scrollToViewBottom(view)
            view.removeFromSuperview()
        }
        addNoteView.onNoteAdded = { [unowned self] note in
            hideAddNoteView()
            isEditingNote = false
            addedSteps = mission.addedSteps
            sortAddedSteps()
            tableView.reloadData()
            
            (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Заметка добавлена", secondaryText: "К заметке →") { [unowned self] in
                openNote(note)
            }
        }
    }
    
    private func showAddNoteView() {
        addItemButton.superview!.isHidden = true
        addNoteView.isHidden = false
        addNoteViewBottom.priority = .defaultHigh
        addItemButtonBottom.priority = .defaultLow
        tableView.layoutHeader()
    }
    
    private func hideAddNoteView() {
        addItemButton.superview!.isHidden = false
        addNoteView.isHidden = true
        addNoteViewBottom.priority = .defaultLow
        addItemButtonBottom.priority = .defaultHigh
        tableView.layoutHeader()
    }
    
    private func updateSteps() {
        if !mission.skipRecommend {
            let blocks = (mission.blocks?.allObjects as? [StepsBlock])?.filter { $0.id >= 0 && $0.unlocked }.sorted(by: { $0.id < $1.id }) ?? []
            let steps = blocks.flatMap { $0.steps?.allObjects as? [MissionStep] ?? [] }
            recommendedSteps = steps.filter { !$0.hidden && $0.addedDate == nil }.sorted(by: { $0.id < $1.id })
            hiddenSteps = steps.filter { $0.hidden }
        }
        addedSteps = mission.addedSteps
        sortAddedSteps()
        updateAddAllSteps()
    }
    
    private func updateAddAllSteps() {
        addAllStepsView.superview?.superview?.isHidden = segmentedControl.selectedIndex != 0 || !recommendedExpanded || recommendedSteps.isEmpty
    }
    
    private func displayMission() {
        coverImageView.displayMissionCover(mission: mission)
        titleLabel.text = mission.name
        aboutLabel.text = mission.about
        
        if mission.category == MissionCategory.notes.rawValue {
            menuButton.isHidden = true
        }
    }
    
    private func notifyNoteWillBeDeleted() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
        vc.popupTitle = "Недобавленная заметка будет удалена"
        vc.buttons = [
            ActionButton(type: .red, title: "Удалить и закрыть", action: { [unowned self] _ in
                navigationController?.popViewController(animated: true)
            }),
            ActionButton(type: .secondary, title: "Вернуться к редактированию", action: { [unowned self] _ in
                segmentedControl.selectedIndex = 1
                segmentedControl.onTabSelected?(1)
            })
        ]
        presentBottomSheet(vc, height: 200)
    }
    
    @objc private func onMissionsUpdated(notification: Notification) {
        let context = mission.managedObjectContext
        let deleted = mission.isDeleted
        if context == nil || deleted {
            if let nc = navigationController {
                var controller: UIViewController?
                for vc in nc.viewControllers {
                    if vc === self {
                        break
                    }
                    controller = vc
                }
                if let vc = controller {
                    nc.popToViewController(vc, animated: true)
                }
            }
        }
    }
    
    @objc private func onStepUpdated(notification: Notification) {
        addedSteps = mission.addedSteps
        sortAddedSteps()
        tableView.reloadSections(IndexSet(arrayLiteral: 3), with: .none)
        
        if let step = notification.object as? MissionStep {
            print("Step \(step.isDeleted || step.managedObjectContext == nil), \(step.block.id)")
        }
        if let step = notification.object as? MissionStep, step.hidden {
            hiddenSteps.append(step)
            tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .none)
        }
    }
    
    @objc func onNoteUpdated(notification: Notification) {
        addedSteps = mission.addedSteps
        sortAddedSteps()
        tableView.reloadData()
    }
    
    @IBAction func backTapped(_ sender: Any) {
        if addNoteView.hasData {
            view.endEditing(true)
            notifyNoteWillBeDeleted()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func headerTapped(_ sender: Any) {
        if isHeaderExpanded {
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.headerControlHeight.constant = 156
                self?.tableView.layoutHeader()
            } completion: { [weak self] _ in
                self?.isHeaderExpanded = false
                self?.view.setNeedsLayout()
                self?.view.layoutIfNeeded()
            }
        } else {
            let width = titleLabel.frame.width
            var labelsHeight = mission.name!.height(withWidth: width, font: titleLabel.font)
            if let about = mission.about, !about.isEmpty {
                labelsHeight += 4
                labelsHeight += about.height(withWidth: width, font: aboutLabel.font)
            }
            
            if labelsHeight > titleLabel.superview!.frame.height + 1 {
                isHeaderExpanded = true
                titleLabel.numberOfLines = 0
                aboutLabel.numberOfLines = 0
                
                missionInfoTop.constant = titleLabel.superview!.frame.minY
                missionInfoCenterY.priority = .defaultLow
                missionInfoTop.priority = .defaultHigh
                
                UIView.animate(withDuration: 0.2) { [weak self] in
                    self?.headerControlHeight.constant = 92 + labelsHeight
                    self?.tableView.layoutHeader()
                }
            }
        }
    }
    
    @IBAction func menuTapped(_ sender: Any) {
        let mainVC = (UIApplication.shared.keyWindow?.rootViewController as! MainViewController)
        let menuUnderlayControl =  mainVC.addMenuUnderlayControl(color: .clear)
        
        let menuView = MenuView()
        var items = [MenuItemData]()
        items.append(MenuItemData(text: "Изменить", image: .edit, type: .normal, action: { [unowned self] in
            menuUnderlayControl.removeFromSuperview()
            openEditMission(mission) { [unowned self] mission in
                menuUnderlayControl.removeFromSuperview()
                self.mission = mission
                self.displayMission()
            }
        }))
        if mission.templateId > 0 {
            items.append(MenuItemData(text: "Поделиться", image: .share, type: .normal, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                
                menuButton.isHidden = true
                progressIndicator.startAnimating()
                progressIndicator.isHidden = false
                
                AppsFlyerHelper().generateLink(templateId: mission.templateId, viewController: self) { [weak self] in
                    self?.menuButton.isHidden = false
                    self?.progressIndicator.stopAnimating()
                    self?.progressIndicator.isHidden = true
                }
            }))
        }
        items.append(MenuItemData(text: mission.archivedAt != nil ? "Убрать из архива" : "В архив", image: mission.archivedAt != nil ? .unarchive : .archive, type: .normal, action: { [unowned self] in
            menuUnderlayControl.removeFromSuperview()
            openArchiveMission(mission)
        }))
        items.append(MenuItemData(text: "Удалить", image: .trash, type: .red, action: { [unowned self] in
            menuUnderlayControl.removeFromSuperview()
            openDeleteMission(mission)
        }))
        menuView.items = items
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(menuView)
        
        let constraints = [
            menuView.topAnchor.constraint(equalTo: menuButton.bottomAnchor, constant: 0),
            menuView.rightAnchor.constraint(equalTo: menuUnderlayControl.rightAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraints)
        
        menuView.setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 30, shadowOpacity: 0.22)
    }
    
    @IBAction func recommendedStepsTapped(_ sender: Any) {
        recommendedExpanded = !recommendedExpanded
        addAllStepsView.superview?.superview?.isHidden = !recommendedExpanded || recommendedSteps.isEmpty
        recommendedArrow.transform = CGAffineTransform(rotationAngle: recommendedExpanded ? 0 : .pi)
        tableView.layoutHeader()
        tableView.reloadData()
    }
    
    @IBAction func addAllStepsTapped(_ sender: Any) {
        var sortOrder = mission.maxSortOrder + 1 + Int32(recommendedSteps.count)
        let startDate = Date().toDateString
        CoreDataStack.shared.performAndWait { [unowned self] _ in
            recommendedSteps.forEach {
                $0.hidden = false
                $0.addedDate = Date()
                $0.startDate = startDate
                $0.sortOrder = sortOrder
                sortOrder -= 1
            }
        }
        let visibleCells = tableView.visibleCells
        for cell in visibleCells {
            if let recommendedStepCell = cell as? RecommendedStepCell {
                recommendedStepCell.animateAddStep() { }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            if let `self` = self {
                self.updateSteps()
                self.tableView.reloadSections(IndexSet(arrayLiteral: 0, 2, 3), with: .automatic)
            }
        }
    }
    
    @IBAction func hiddenStepsTapped(_ sender: Any) {
        let vc = storyboard!.instantiateViewController(identifier: "HiddenStepsVC") as! HiddenStepsViewController
        vc.mission = mission
        vc.onStepHidden = { [unowned self] in
            updateSteps()
            tableView.reloadData()
        }
        
        let window = UIApplication.shared.windows.first
        let top = (window?.safeAreaInsets.top ?? 20)
        presentBottomSheet(vc, height: UIScreen.main.bounds.height - top)
    }
    
    @IBAction func addItemTapped(_ sender: Any) {
        if segmentedControl.selectedIndex == 0 {
            openEditStep(mission: mission) { [unowned self] step in
                addedSteps.insert(step, at: 0)
                tableView.beginUpdates()
                tableView.insertRows(at: [IndexPath(row: 0, section: 3)], with: .none)
                tableView.endUpdates()
                (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Шаг добавлен", secondaryText: "К шагу →") { [unowned self] in
                    UIApplication.topViewController()?.openStep(step)
                }
            }
        } else {
            showAddNoteView()
            isEditingNote = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                if let `self` = self {
                    self.tableView.scrollToViewBottom(self.addNoteView)
                }
            }
        }
    }
    
    private func showMenu(step: MissionStep, anchorRect: CGRect, image: UIImage) {
        let mainVC = (UIApplication.shared.keyWindow?.rootViewController as! MainViewController)
        let menuUnderlayControl = mainVC.addMenuUnderlayControl(color: .black.withAlphaComponent(0.25))
        
        var items = [MenuItemData]()
        if step.addedDate != nil {
            let stepIndex = addedSteps.firstIndex(of: step)!
            if addedSteps.count > 1 && stepIndex > 0 {
                items.append(
                    MenuItemData(text: "Вверх списка", image: .arrowUp, type: .normal, action: { [unowned self] in
                        menuUnderlayControl.removeFromSuperview()
                        
                        CoreDataStack.shared.performAndWait { [unowned self] context in
                            step.sortOrder = (self.addedSteps.max(by: { $0.sortOrder < $1.sortOrder })?.sortOrder ?? 0) + 1
                        }
                        let previousRow = addedSteps.firstIndex(of: step)!
                        sortAddedSteps()
                        let newRow = addedSteps.firstIndex(of: step)!
                        tableView.moveRow(at: IndexPath(row: previousRow, section: 3), to: IndexPath(row: newRow, section: 3))
                    })
                )
            }
            items.append(
                MenuItemData(text: "Удалить", image: .trash, type: .red, action: { [unowned self] in
                    menuUnderlayControl.removeFromSuperview()
                    deleteStep(step)
                })
            )
        } else {
            items = [
                MenuItemData(text: "Изменить", image: .edit, type: .normal, action: { [unowned self] in
                    menuUnderlayControl.removeFromSuperview()
                    let row = recommendedSteps.firstIndex(of: step)!
                    openEditStep(mission: mission, step: step) { [unowned self] step in
                        tableView.beginUpdates()
                        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
                        tableView.endUpdates()
                        (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Шаг изменён")
                    }
                }),
                MenuItemData(text: "Скрыть", image: .eyeOff1, type: .red, action: { [unowned self] in
                    menuUnderlayControl.removeFromSuperview()
                    CoreDataStack.shared.performAndWait { context in
                        step.hidden = true
                    }
                    if let index = recommendedSteps.firstIndex(where: { $0.id == step.id }) {
                        recommendedSteps.remove(at: index)
                        hiddenSteps.append(step)
                        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                        tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .none)
                    }
                })
            ]
        }
        showMenu(items: items, menuUnderlayControl: menuUnderlayControl, anchorRect: anchorRect, image: image, hMargin: 20)
    }
    
    private func sortAddedSteps() {
        addedSteps.sort {
            if $0.sortOrder == 0 && $1.sortOrder == 0 {
                return $0.id > $1.id
            }
            return $0.sortOrder > $1.sortOrder
        }
    }
    
    private func deleteStep(_ step: MissionStep) {
        openDeleteStep(step, date: step.lastDate, onDeleted: { [unowned self] in
            onStepDeleted(step)
        }, onUpdated: { [unowned self] in
            onStepUpdated(step)
        })
    }
    
    private func onStepDeleted(_ step: MissionStep) {
        addedSteps = mission.addedSteps
        sortAddedSteps()
        tableView.reloadSections(IndexSet(arrayLiteral: 3), with: .automatic)
        if step.block.id > 0 {
            hiddenSteps.append(step)
            tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .none)
        }
    }
    
    private func onStepUpdated(_ step: MissionStep) {
        addedSteps = mission.addedSteps
        sortAddedSteps()
        tableView.reloadSections(IndexSet(arrayLiteral: 3), with: .automatic)
    }
    
    private func onNoteChanged(stepDeleted: Bool, missionDeleted: Bool) {
        if missionDeleted {
            navigationController?.popViewController(animated: true)
        } else {
            if stepDeleted {
                addedSteps = mission.addedSteps
                sortAddedSteps()
            }
            self.tableView.reloadData()
        }
    }
}

extension MissionViewController: UITableViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView.contentOffset.y < 0 {
            topBgViewHeight.constant = -scrollView.contentOffset.y
        } else {
            topBgViewHeight.constant = 0
        }
        
        if scrollView.contentOffset.y > headerControl.frame.maxY {
            if !hasNavBarShadow {
                hasNavBarShadow = true
                navBar.layer.shadowOpacity = 0.1
            }
        } else {
            if hasNavBarShadow {
                hasNavBarShadow = false
                navBar.layer.shadowOpacity = 0
            }
        }
    }
}

extension MissionViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if segmentedControl.selectedIndex == 0 {
            return 4
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedIndex == 0 {
            if section == 1 || section == 2 {
                return 1
            }
            if section == 3 {
                return addedSteps.count
            }
            return recommendedExpanded ? (recommendedSteps.count ) : 0
        } else {
            let notesCount = addedSteps.flatMap { $0.notes?.allObjects ?? [] }.count
            return notesCount / 2 + notesCount % 2
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if segmentedControl.selectedIndex == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCell", for: indexPath)
            let notes = addedSteps.flatMap { $0.notes?.allObjects.map { $0 as! MissionNote } ?? [] }.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
            
            let onNoteLongTap: (MissionNote, UIImage, CGRect) -> () = { [unowned self] note, image, rect in
                self.generator.impactOccurred()
                self.generator.prepare()
                self.showNoteMenu(note: note, anchorRect: rect, image: image, onDeleted: { [unowned self] stepDeleted, missionDeleted in
                    self.onNoteChanged(stepDeleted: stepDeleted, missionDeleted: missionDeleted)
                }, onMoved: { [unowned self] stepDeleted, missionDeleted in
                    self.onNoteChanged(stepDeleted: stepDeleted, missionDeleted: missionDeleted)
                    if note.step?.hasFrequency == false {
                        addedSteps = mission.addedSteps
                        sortAddedSteps()
                    }
                })
            }
            
            let view1 = cell.viewWithTag(1) as! NoteView
            view1.note = notes[indexPath.row * 2]
            view1.onLongGesture = onNoteLongTap
            
            let view2 = cell.viewWithTag(2) as! NoteView
            if notes.count > indexPath.row * 2 + 1 {
                view2.alpha = 1
                view2.note = notes[indexPath.row * 2 + 1]
                view2.onLongGesture = onNoteLongTap
            } else {
                view2.alpha = 0
                view2.onLongGesture = nil
            }
            
            return cell
        }
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HiddenStepsCell", for: indexPath)
            return cell
        }
        if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddedStepsCell", for: indexPath)
            return cell
        }
        if indexPath.section == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StepCell", for: indexPath) as! AddedStepCell
            let step = addedSteps[indexPath.row]
            cell.step = step
            cell.onLongGesture = { [unowned self] step, image, rect in
                if step.id >= 0 && (step.editable || (addedSteps.count > 1 && indexPath.row > 0)) {
                    self.generator.impactOccurred()
                    self.generator.prepare()
                    self.showMenu(step: step, anchorRect: rect, image: image)
                }
            }
            cell.onOpenStep = { [unowned self] step, date, createNote in
                openStep(step, date: date, createNote: createNote)
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecommendedStepCell", for: indexPath) as! RecommendedStepCell
        let step = recommendedSteps[indexPath.row]
        cell.step = step
        cell.onStepTapped = { [unowned self] in
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
        cell.onStepAdded = { [unowned self] step in
            if let index = recommendedSteps.firstIndex(of: step) {
                recommendedSteps.remove(at: index)
                addedSteps.insert(step, at: 0)
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 3)], with: .automatic)
                self.tableView.endUpdates()
            }
        }
        cell.onLongGesture = { [unowned self] image, rect in
            self.generator.impactOccurred()
            self.generator.prepare()
            self.showMenu(step: step, anchorRect: rect, image: image)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if segmentedControl.selectedIndex == 1 {
            return 228
        }
        if indexPath.section == 1 {
            return hiddenSteps.isEmpty ? 1 : 48
        }
        if indexPath.section == 2 {
            return (mission.templateId <= 0 || addedSteps.isEmpty || mission.skipRecommend) ? 1 : 66
        }
        return UITableView.automaticDimension
    }
}
