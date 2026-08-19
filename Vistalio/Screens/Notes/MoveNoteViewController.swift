//
//  MoveNoteViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 19.07.2026.
//

import UIKit

class MoveNoteViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var addNoteButton: UIControl!
    
    @IBOutlet weak var weeklyView: WeeklyView!
    @IBOutlet weak var headerUnderlayView: UIView!
    @IBOutlet weak var headerUnderlayBottom: NSLayoutConstraint!
    
    var step: MissionStep!
    var mission: Mission?
    var onMoved: ((Mission, MissionStep?, Bool, Bool) -> ())?
    var showCalendar = false
    var date: Date?
    var note: MissionNote?
    
    private var selectedMission: Mission?
    private var selectedStep: MissionStep?
    
    private var missions = [Mission]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        backButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        setupBottomConstraint(saveButton)
        setupBottomConstraint(addNoteButton)
        
        let window = UIApplication.shared.windows.first
        var bottom = window?.safeAreaInsets.bottom ?? 0
        if bottom == 0 {
            bottom = 20
        }
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70 + bottom, right: 0)
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableView.automaticDimension
        
        backButton.isHidden = (navigationController == nil)
        addNoteButton.isHidden = (navigationController == nil)
        saveButton.isHidden = (navigationController != nil)
        
        if showCalendar {
            if let nc = navigationController as? CreateNoteNavigationController, let stepDate = nc.stepDate {
                weeklyView.selectedDate = stepDate
            } else if let step = note?.step {
                if step.id >= 0 {
                    weeklyView.selectedDate = step.lastDate ?? note!.date!
                } else {
                    weeklyView.selectedDate = note!.date!
                }
            } else {
                weeklyView.selectedDate = date ?? Date()
            }
            weeklyView.generateWeeks()
            weeklyView.onDateSelected = { [unowned self] date in
                updateSteps()
                tableView.reloadData()
            }
            headerUnderlayView.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 30, shadowOpacity: 0.1)
        } else {
            tableView.tableHeaderView = nil
            headerUnderlayView.isHidden = true
        }
        
        if let mission = mission {
            missions = [mission]
            selectedMission = mission
        } else {
            if note != nil {
                titleLabel.text = "Переместить заметку"
                saveButton.setTitle("Сохранить", for: .normal)
                if let step = note?.step, step.id >= 0 {
                    selectedStep = note?.step
                }
                selectedMission = note?.step?.block.mission
            } else {
                titleLabel.text = "Куда поместить заметку?"
            }
            missions = MissionsHolder.shared.getMyMissions().filter { $0.category != MissionCategory.notes.rawValue }
        }
        updateSteps()
        
        if let nc = navigationController as? CreateNoteNavigationController, nc.stepDate != nil {
            selectedMission = nc.selectedMission
            selectedStep = nc.selectedStep
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutHeader()
        updateHeaderUnderlay()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let nc = navigationController as? CreateNoteNavigationController {
            nc.selectedMission = selectedMission
            nc.selectedStep = selectedStep
            nc.stepDate = weeklyView.selectedDate
        }
    }
    
    private func updateSteps() {
        if showCalendar, let date = weeklyView.selectedDate {
            missions.forEach {
                $0.selectedSteps = $0.addedSteps.filter { $0.id >= 0 && $0.hasItemForDate(date) }
            }
        } else {
            missions.forEach {
                $0.selectedSteps = $0.addedSteps.filter { $0.id >= 0 }
            }
        }
    }
    
    private func updateHeaderUnderlay() {
        if let headerView = tableView.tableHeaderView {
            headerUnderlayBottom.constant = min(0, -(headerView.frame.height - 2 - tableView.contentOffset.y))
        }
    }
    
    @IBAction func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func saveTapped() {
        var moved = false
        if let mission = mission {
            onMoved?(mission, selectedStep, false, false)
        } else if let note = note, let selectedMission = selectedMission {
            if let step = (selectedStep ?? selectedMission.getNotesStep()), step.objectID != note.step?.objectID {
                
                var missionDeleted = false
                var stepDeleted = false
                
                CoreDataStack.shared.performAndWait { context in
                    let previousStep = note.step
                    note.step = step
                    
                    if previousStep?.hasFrequency == false && previousStep?.notes?.count == 0 {
                        if let mission = previousStep?.block.mission, mission.category == MissionCategory.notes.rawValue, mission.addedSteps.count == 1 {
                            context.delete(mission)
                            missionDeleted = true
                        } else {
                            context.delete(previousStep!)
                        }
                        stepDeleted = true
                    }
                }
                onMoved?(selectedMission, selectedStep, stepDeleted, missionDeleted)
                moved = true
                
                print("Mission deleted \(missionDeleted), step deleted \(stepDeleted)")
                
                if missionDeleted {
                    NotificationCenter.default.post(name: .missionUpdated, object: nil)
                }
            }
        }
        
        dismiss(animated: true) {
            if moved {
                (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Заметка перемещена")
            }
        }
    }
    
    @IBAction func addNoteTapped() {
        guard let nc = navigationController as? CreateNoteNavigationController else {
            return
        }
        
        var note: MissionNote?
        
        CoreDataStack.shared.performAndWait { [unowned self] context in
            var step = selectedStep
            if step == nil {
                step = selectedMission?.getNotesStep()
                if step == nil {
                    step = MissionsHolder.shared.getNotesMission(context: context)?.getNotesStep()
                }
            }
            if let step = step {
                note = MissionNote.create(context: context, step: step, date: nc.date ?? Date(), name: nc.noteTitle, text: nc.body, emotions: nc.emotions, media: nc.mediaHolder.media)
            }
        }
        
        nc.mediaHolder.media.forEach { $0.saved = true }
        
        if let note = note {
            NotificationCenter.default.post(name: .noteUpdated, object: note)
        }
        let presenting = presentingViewController
        self.dismiss(animated: true) {
            if let note = note {
                (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Заметка добавлена", secondaryText: "К заметке →") {
                    presenting?.openNote(note)
                }
            }
        }
    }
}

extension MoveNoteViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return missions.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let stepsCount = missions[section].selectedSteps?.count ?? 0
        if stepsCount == 0 {
            return 2
        }
        return stepsCount + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mission = missions[indexPath.section]
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoteToMissionCell", for: indexPath) as! NoteToMissionCell
            cell.mission = mission
            cell.isMissionSelected = (selectedStep == nil && cell.mission === selectedMission)
            cell.onTapped = { [unowned self] mission in
                selectedMission = mission
                selectedStep = nil
                tableView.reloadData()
            }
            return cell
        }
        
        let steps = mission.selectedSteps ?? []
        if steps.isEmpty {
            return tableView.dequeueReusableCell(withIdentifier: "NoStepsCell", for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteToStepCell", for: indexPath) as! NoteToStepCell
        cell.step = steps[indexPath.row - 1]
        cell.isLastStep = indexPath.row == steps.count
        cell.isStepSelected = (cell.step === selectedStep)
        cell.onTapped = { [unowned self] step in
            selectedMission = step.block.mission
            selectedStep = step
            tableView.reloadData()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderUnderlay()
    }
}
