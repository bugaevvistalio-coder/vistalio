//
//  MyDayViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 19.08.2026.
//

import UIKit

class MyDayViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bellBadge: UIView!
    @IBOutlet weak var calendarButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var weeklyView: WeeklyView!
    @IBOutlet weak var weeklyViewWidth: NSLayoutConstraint!
    
    @IBOutlet weak var headerUnderlayView: UIView!
    @IBOutlet weak var headerUnderlayBottom: NSLayoutConstraint!
    
    @IBOutlet weak var addMissionButton: UIButton!
    
    private var allMissions = [Mission]()
    private var missions = [Mission]()
    
    private let generator = UIImpactFeedbackGenerator(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let screenW = UIScreen.main.bounds.width
        
        calendarButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        headerUnderlayView.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 30, shadowOpacity: 0.1)
        addMissionButton.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 20, fixedBounds: CGRect(x: 0, y: 0, width: screenW  - 20, height: 40))
        
        if UIScreen.main.bounds.width <= 320 {
            weeklyViewWidth.constant = 308
        }
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableView.automaticDimension
        
        weeklyView.showWeekTitle = false
        weeklyView.showEmotions = true
        weeklyView.selectedDate = Date()
        
        weeklyView.generateWeeks()
        weeklyView.onDateSelected = { [unowned self] date in
            updateSteps()
            tableView.reloadData()
        }
        
        update()
        updateNotes()
        
        generator.prepare()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onMissionUpdated(notification:)), name: .missionUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onTemplatesUpdated(notification:)), name: .templatesUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onNoteUpdated(notification:)), name: .noteUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .missionUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: .templatesUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: .noteUpdated, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addMissionButton.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 22, fixedBounds: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 36, height: 44))
        tableView.layoutHeader()
        updateHeaderUnderlay()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        update()
    }
    
    private func updateHeaderUnderlay() {
        if let headerView = tableView.tableHeaderView {
            headerUnderlayBottom.constant = min(0, -(headerView.frame.height - 2 - tableView.contentOffset.y))
        }
    }
    
    @objc func onTemplatesUpdated(notification: Notification) {
        if missions.isEmpty {
            tableView.reloadData()
        }
    }
    
    @objc func onNoteUpdated(notification: Notification) {
        updateNotes()
    }
    
    private func update() {
        allMissions = MissionsHolder.shared.getMyMissions()
        updateSteps()
        tableView.reloadData()
    }
    
    private func updateNotes() {
        weeklyView.notes = allMissions.flatMap { $0.addedSteps }.flatMap { ($0.notes?.allObjects ?? []).map { $0 as! MissionNote } }
        weeklyView.refresh()
    }
    
    private func updateSteps() {
        let date = (weeklyView.selectedDate ?? Date()).startOfDay
        titleLabel.text = date.formatted1
        missions = allMissions.filter { $0.category != MissionCategory.notes.rawValue && ($0.archivedAt == nil || date < $0.archivedAt!.startOfDay) }
        let now = Date().startOfDay
        missions.forEach {
            $0.selectedSteps = $0.addedStepsSorted.filter { $0.id >= 0 && $0.hasItemForDate(date) && ($0.frequency != StepFrequency.untilDone.rawValue || date <= now) }
        }
        if missions.isEmpty {
            addMissionButton.superview?.isHidden = true
            tableView.tableFooterView?.frame = .zero
        } else {
            addMissionButton.superview?.isHidden = false
            tableView.tableFooterView?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 88)
        }
    }
    
    @IBAction func addMissionTapped(_ sender: Any) {
        let sb = UIStoryboard(name: "Missions", bundle: nil)
        let nc = sb.instantiateViewController(identifier: "CreateMissionNC") as! UINavigationController
        let vc = nc.viewControllers.first as! CreateMissionViewController
        vc.onMissionCreated = { [unowned self] mission in
            self.openMission(mission)
        }
        presentFullScreen(nc)
    }
    
    @IBAction func template1Tapped(_ sender: Any) {
        openTemplate(MissionsHolder.shared.templates.first { $0.id == 9 }!)
    }
    
    @IBAction func template2Tapped(_ sender: Any) {
        openTemplate(MissionsHolder.shared.templates.first { $0.id == 12 }!)
    }
    
    @IBAction func otherTemplatesTapped(_ sender: Any) {
        UIApplication.shared.mainViewController?.switchTab(tabIndex: 1, toRoot: true)
    }
    
    @objc func onMissionUpdated(notification: Notification) {
        update()
    }
    
    private func showMenu(mission: Mission, anchorRect: CGRect, image: UIImage) {
        let mainVC = UIApplication.shared.mainViewController!
        let menuUnderlayControl = mainVC.addMenuUnderlayControl(color: .black.withAlphaComponent(0.25))
        
        var items = [MenuItemData]()
        let index = missions.firstIndex(of: mission)!
        if index > 0 {
            items.append(
                MenuItemData(text: "Вверх списка", image: .arrowUp, type: .normal, action: { [unowned self] in
                    menuUnderlayControl.removeFromSuperview()
                    
                    CoreDataStack.shared.performAndWait { [unowned self] context in
                        mission.sortOrder = (self.allMissions.max(by: { $0.sortOrder < $1.sortOrder })?.sortOrder ?? 0) + 1
                    }
                    
                    missions.removeAll { $0.objectID == mission.objectID }
                    missions.insert(mission, at: 0)
                    
                    tableView.reloadData()
                    
                    NotificationCenter.default.post(name: .missionUpdated, object: nil)
                })
            )
        }
        items.append(
            MenuItemData(text: mission.archivedAt != nil ? "Убрать из архива" : "В архив", image: mission.archivedAt != nil ? .unarchive : .archive, type: .normal, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                openArchiveMission(mission)
            })
        )
        items.append(
            MenuItemData(text: "Удалить", image: .trash, type: .red, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                openDeleteMission(mission)
            })
        )
        showMenu(items: items, menuUnderlayControl: menuUnderlayControl, anchorRect: anchorRect, image: image, hMargin: 18)
    }
    
    private func showMenu(step: MissionStep, anchorRect: CGRect, image: UIImage) {
        let mainVC = UIApplication.shared.mainViewController!
        let menuUnderlayControl = mainVC.addMenuUnderlayControl(color: .black.withAlphaComponent(0.25))
        
        var items = [MenuItemData]()
        let missionSteps = step.block.mission.selectedSteps ?? []
        let stepIndex = missionSteps.firstIndex(of: step)!
        if stepIndex > 0 {
            items.append(
                MenuItemData(text: "Вверх списка", image: .arrowUp, type: .normal, action: { [unowned self] in
                    menuUnderlayControl.removeFromSuperview()
                    
                    step.moveUp()
                    
                    let mission = step.block.mission
                    let previousRow = missionSteps.firstIndex(of: step)!
                    mission.selectedSteps?.remove(at: previousRow)
                    mission.selectedSteps?.insert(step, at: 0)
                    
                    let section = missions.firstIndex(of: mission)!
                    if previousRow == mission.selectedSteps!.count - 1 {
                        tableView.reloadSections(IndexSet(arrayLiteral: section), with: .automatic)
                    } else {
                        tableView.moveRow(at: IndexPath(row: previousRow + 1, section: section), to: IndexPath(row: 1, section: section))
                    }
                    
                    NotificationCenter.default.post(name: .stepUpdated, object: step)
                })
            )
        }
        items.append(
            MenuItemData(text: "Удалить", image: .trash, type: .red, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                
                let mission = step.block.mission
                let row = missionSteps.firstIndex(of: step)!
                
                openDeleteStep(step, date: step.lastDate, onDeleted: { [unowned self] in
                    onStepDeleted(step, mission: mission)
                }, onUpdated: { [unowned self] in
                    onStepDeleted(step, mission: mission)
                })
            })
        )
        showMenu(items: items, menuUnderlayControl: menuUnderlayControl, anchorRect: anchorRect, image: image, hMargin: 10)
    }
    
    private func onStepDeleted(_ step: MissionStep, mission: Mission) {
        let missionSteps = mission.selectedSteps ?? []
        let section = missions.firstIndex(of: mission)!
        let row = missionSteps.firstIndex(of: step)!
        let isLastRow = row == mission.selectedSteps!.count - 1
        
        mission.selectedSteps?.remove(at: row)
        if isLastRow {
            tableView.reloadSections(IndexSet(arrayLiteral: section), with: .automatic)
        } else {
            tableView.deleteRows(at: [IndexPath(row: row + 1, section: section)], with: .automatic)
        }
        
        NotificationCenter.default.post(name: .stepUpdated, object: step)
    }
}

extension MyDayViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return missions.isEmpty ? 1 : missions.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if missions.isEmpty {
            return 1
        }
        let stepsCount = missions[section].selectedSteps?.count ?? 0
        if stepsCount == 0 {
            return 2
        }
        return stepsCount + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if missions.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoMissionsCell", for: indexPath) as! NoMissionsCell
            cell.update()
            return cell
        }
        let mission = missions[indexPath.section]
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MissionCell", for: indexPath) as! DayMissionCell
            let w = UIScreen.main.bounds.width
            cell.innerViewWidth = w - 40
            cell.labelWidth = w - 150
            cell.mission = mission
            cell.onAddStep = { [unowned self] mission in
                openEditStep(mission: mission) { [unowned self] step in
                    (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Шаг добавлен", secondaryText: "К шагу →") {
                        UIApplication.topViewController()?.openStep(step)
                    }
                    let date = weeklyView.selectedDate ?? Date()
                    if !step.hasItemForDate(date) {
                        weeklyView.selectedDate = step.lastDate
                        weeklyView.generateWeeks()
                        weeklyView.refresh()
                    }
                    updateSteps()
                    tableView.reloadData()
                    
                    NotificationCenter.default.post(name: .stepUpdated, object: step)
                }
            }
            cell.onLongGesture = { [unowned self] mission, image, rect in
                self.generator.impactOccurred()
                self.generator.prepare()
                self.showMenu(mission: mission, anchorRect: rect, image: image)
            }
            return cell
        }
        
        let steps = mission.selectedSteps ?? []
        if steps.isEmpty {
            return tableView.dequeueReusableCell(withIdentifier: "NoStepsCell", for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "StepCell", for: indexPath) as! AddedStepCell
        // Первым делом date
        cell.date = weeklyView.selectedDate ?? Date()
        cell.step = steps[indexPath.row - 1]
        cell.isLastStep = indexPath.row == steps.count
        cell.onLongGesture = { [unowned self] step, image, rect in
            self.generator.impactOccurred()
            self.generator.prepare()
            self.showMenu(step: step, anchorRect: rect, image: image)
        }
        cell.onOpenStep = { [unowned self] step, date, createNote in
            openStep(step, date: date, createNote: createNote)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if missions.isEmpty {
            return CGFloat.leastNormalMagnitude
        }
        return 8
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderUnderlay()
    }
}
