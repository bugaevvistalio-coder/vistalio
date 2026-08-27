//
//  DayNotesViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 24.08.2026.
//

import UIKit

class DayNotesViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var emotionView: UIView!
    @IBOutlet weak var emotionImageView: UIImageView!
    @IBOutlet weak var emotionNameLabel: UILabel!
    @IBOutlet weak var emotionBorderView: UIView!
    @IBOutlet weak var emotionBgView: UIView!
    @IBOutlet weak var emotionOuterView: RoundedView!
    
    @IBOutlet weak var addNoteButton: UIButton!
    @IBOutlet weak var addNoteView: AddNoteView!
    @IBOutlet weak var addNoteScrollView: UIScrollView!
    
    @IBOutlet weak var notificationsStackView: UIStackView!
    
    @IBOutlet weak var bottomGradientView: UIView!
    
    var day: Date!
    var notes = [MissionNote]()
    var emotion: MissionEmotion?
    
    private var missions = [Mission]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        bottomGradientView.applyBottomGradient(color: .bgGrey)
        
        titleLabel.text = "Заметки, созданные\n\(day.formatted1.lowercased())"
        
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableView.automaticDimension
        
        displayEmotion()
        
        addNoteScrollView.isHidden = true
        if notes.isEmpty {
            tableView.isHidden = true
            addNoteButton.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18, fixedBounds: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 32, height: 72))
            setupAddNoteView()
        } else {
            addNoteButton.superview?.isHidden = true
            updateMissions()
        }
    }
    
    private func setupAddNoteView() {
        addNoteView.date = day
        addNoteView.onCursorPositionChanged = { [unowned self] textView, rect in
            let view = UIView(frame: rect)
            view.alpha = 0
            textView.addSubview(view)
            addNoteScrollView.scrollToViewBottom(view)
            view.removeFromSuperview()
        }
        addNoteView.onNoteAdded = { [unowned self] note in
            
            if note.date?.startOfDay != day {
                day = note.date!.startOfDay
                titleLabel.text = "Заметки, созданные\n\(day.formatted1.lowercased())"
            }
            
            notes = [note]
            missions = [note.step!.block.mission]
            if let emotions = note.emotions?.allObjects.map({ $0 as! MissionNoteEmotion }), emotions.count > 0 {
                let grouped = Dictionary(grouping: emotions, by: { MissionEmotion(rawValue: $0.emotion)!.group.rawValue } )
                if let maxCount = grouped.values.map({ $0.count }).max() {
                    let leadGroups = grouped.filter { $0.value.count == maxCount }
                    let leadGroupsEmotions = leadGroups.flatMap { $0.value }.sorted { $0.date > $1.date }
                    if let e = leadGroupsEmotions.first {
                        emotion = MissionEmotion(rawValue: e.emotion)
                        displayEmotion()
                        tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 172)
                        emotionView.isHidden = false
                    }
                }
            }

            addNoteScrollView.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
            
            notificationsStackView.addNotification(text: "Заметка добавлена", secondaryText: "К заметке →") { [unowned self] in
                dismiss(animated: false) {
                    UIApplication.topViewController()?.openNote(note)
                }
            }
        }
    }
    
    private func updateMissions() {
        missions = Array(Set(notes.compactMap { $0.step!.block.mission })).sorted {
            if $0.sortOrder == 0 && $1.sortOrder == 0 {
                return $0.creationDate! > $1.creationDate!
            }
            return $0.sortOrder > $1.sortOrder
        }
    }
    
    private func displayEmotion() {
        if let emotion = emotion {
            emotionView.setShadow(offset: CGSize(width: 0, height: 0), radius: 12, cornerRadius: 30, shadowOpacity: 0.09, bounds: CGRect(x: 0, y: 0, width: 140, height: 160))
            
            let nameAndImage = emotion.nameAndImage
            emotionNameLabel.text = nameAndImage.0
            emotionImageView.image = nameAndImage.1
            
            let colors = emotion.colors
            emotionBgView.setGradientLayer(colors: colors.0, startPoint: CGPoint(x: 0.5, y: 0.0), endPoint: CGPoint(x: 0.5, y: 1.0), cornerRadius: 34, bounds: CGRect(x: 0, y: 0, width: 68, height: 68))
            emotionBorderView.setGradientLayer(colors: colors.1, startPoint: CGPoint(x: 0.5, y: 0.0), endPoint: CGPoint(x: 0.5, y: 1.0), cornerRadius: 37, bounds: CGRect(x: 0, y: 0, width: 74, height: 74))
            emotionBorderView.setShadow(offset: CGSize(width: 0, height: 1.24), radius: 1.6, cornerRadius: 37, shadowOpacity: 0.12)
            emotionOuterView.layer.borderColor = colors.2.cgColor
        } else {
            tableView.tableHeaderView?.frame = .zero
            emotionView.isHidden = true
        }
    }
    
    @IBAction func closeTapped() {
        dismiss(animated: true)
    }
    
    @IBAction func addNoteTapped() {
        addNoteButton.superview?.isHidden = true
        addNoteScrollView.isHidden = false
    }
}

extension DayNotesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return missions.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let mission = missions[section]
        let notes = notes.filter { $0.step?.block.mission.objectID == mission.objectID }
        return notes.count / 2 + notes.count % 2 + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mission = missions[indexPath.section]
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MissionCell", for: indexPath) as! DayMissionCell
            let w = UIScreen.main.bounds.width
            cell.innerViewWidth = w - 52
            cell.labelWidth = w - 102
            cell.mission = mission
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCell", for: indexPath)
        let notes = notes.filter { $0.step?.block.mission.objectID == mission.objectID }
        
        let view1 = cell.viewWithTag(1) as! NoteView
        let index = indexPath.row - 1
        view1.note = notes[index * 2]
        
        let view2 = cell.viewWithTag(2) as! NoteView
        if notes.count > index * 2 + 1 {
            view2.alpha = 1
            view2.note = notes[index * 2 + 1]
        } else {
            view2.alpha = 0
            view2.onLongGesture = nil
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 12
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
