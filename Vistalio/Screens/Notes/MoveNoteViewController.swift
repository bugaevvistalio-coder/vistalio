//
//  MoveNoteViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 19.07.2026.
//

import UIKit

class MoveNoteViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    
    var step: MissionStep!
    var mission: Mission?
    var onMoved: ((Mission, MissionStep?) -> ())?
    
    private var selectedMission: Mission?
    private var selectedStep: MissionStep?
    
    private var missions = [Mission]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        setupBottomConstraint(saveButton)
        
        let window = UIApplication.shared.windows.first
        var bottom = window?.safeAreaInsets.bottom ?? 0
        if bottom == 0 {
            bottom = 20
        }
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70 + bottom, right: 0)
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableView.automaticDimension
        
        if let mission = mission {
            missions = [mission]
            selectedMission = mission
        } else {
            missions = MissionsHolder.shared.getMyMissions()
        }
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func saveTapped() {
        onMoved?(selectedMission!, selectedStep)
        dismiss(animated: true)
    }
}

extension MoveNoteViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return missions.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let stepsCount = missions[section].addedSteps.count
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
        
        let steps = mission.addedSteps
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
}
