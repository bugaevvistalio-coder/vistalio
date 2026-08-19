//
//  MissionsViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 21.03.2026.
//

import UIKit

class MissionsViewController: UIViewController {
    
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var myMissionsButton: UIButton!
    @IBOutlet weak var addMissionButton: UIButton!
    @IBOutlet weak var myMissionsCollectionView: UICollectionView!
    @IBOutlet weak var myMissionsSpacing: NSLayoutConstraint!
    
    private var myMissions = [Mission]()
    
    private var templates = [MissionTemplate]()
    private var hiddenTemplates = [MissionTemplate]()
    private var hiddenTemplatesExpanded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBar.layer.cornerRadius = 30
        navBar.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        navBar.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 30, shadowOpacity: 0.1)
        
        myMissionsButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        addMissionButton.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18)
        
        tableView.estimatedRowHeight = 380.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        
        updateMyMissions()
        
        templates = MissionsHolder.shared.templates.filter { $0.hiddenAt == nil }
        hiddenTemplates = MissionsHolder.shared.templates.filter { $0.hiddenAt != nil }.sorted(by: { $0.hiddenAt! > $1.hiddenAt! })
        
        NotificationCenter.default.addObserver(self, selector: #selector(onMissionUpdated(notification:)), name: .missionUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onNoteUpdated(notification:)), name: .noteUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onTemplatesUpdated(notification:)), name: .templatesUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .missionUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: .noteUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: .templatesUpdated, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutHeader()
        addMissionButton.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18)
    }
    
    private func updateMyMissions() {
        myMissions = MissionsHolder.shared.getMyMissions().filter { !$0.archived }
        myMissionsCollectionView.reloadData()
        myMissionsCollectionView.isHidden = myMissions.isEmpty
        myMissionsSpacing.constant = myMissions.isEmpty ? 24 : 16
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
        updateMyMissions()
    }
    
    @objc func onNoteUpdated(notification: Notification) {
        let notesCategory = MissionCategory.notes.rawValue
        if let note = notification.object as? MissionNote, note.step?.block.mission.category == notesCategory, myMissions.last?.category != notesCategory {
            updateMyMissions()
        }
    }
    
    @objc func onTemplatesUpdated(notification: Notification) {
        templates = MissionsHolder.shared.templates.filter { $0.hiddenAt == nil }
        hiddenTemplates = MissionsHolder.shared.templates.filter { $0.hiddenAt != nil }.sorted(by: { $0.hiddenAt! > $1.hiddenAt! })
        tableView.reloadData()
    }
}

extension MissionsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return templates.count
        } else if section == 2 {
            return hiddenTemplatesExpanded ? hiddenTemplates.count : 0
        }
        return hiddenTemplates.isEmpty ? 0 : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HiddenMissionsCell", for: indexPath)
            cell.selectionStyle = .none
            let arrow = cell.viewWithTag(1) as! UIImageView
            arrow.transform = CGAffineTransform(rotationAngle: hiddenTemplatesExpanded ? .pi/2 : -.pi/2)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "TemplateCell", for: indexPath) as! TemplateCell
        let templates = indexPath.section == 0 ? self.templates : hiddenTemplates
        cell.template = templates[indexPath.row]
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == 1 {
            hiddenTemplatesExpanded = !hiddenTemplatesExpanded
            tableView.reloadSections(IndexSet(arrayLiteral: 1, 2), with: .automatic)
        } else {
            let templates = indexPath.section == 0 ? self.templates : hiddenTemplates
            let vc = storyboard!.instantiateViewController(withIdentifier: "TemplateVC") as! TemplateViewController
            vc.template = templates[indexPath.row]
            let window = UIApplication.shared.windows.first
            let top = (window?.safeAreaInsets.top ?? 20)
            presentBottomSheet(vc, height: UIScreen.main.bounds.height - top)
        }
    }
}

extension MissionsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myMissions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyMissionCell", for: indexPath) as! MyMissionCell
        cell.mission = myMissions[indexPath.row]
        return cell
    }
}

extension MissionsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        openMission(myMissions[indexPath.row])
    }
}
