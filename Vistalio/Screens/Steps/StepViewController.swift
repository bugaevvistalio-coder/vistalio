//
//  StepViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 09.06.2026.
//

import UIKit

class StepViewController: UIViewController {
    
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerShadowView: UIView!
    
    @IBOutlet weak var navigationMissionButton: UIButton!
    @IBOutlet weak var navigationStepButton: UIButton!
    @IBOutlet weak var navigationGradientLeft: UIView!
    @IBOutlet weak var navigationGradientRight: UIView!
    
    @IBOutlet weak var nameTextView: UITextView!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    @IBOutlet weak var dateControl: UIControl!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dateImageView: UIImageView!
    @IBOutlet weak var calendarView: CalendarView!
    @IBOutlet weak var checkImageView: UIImageView!
    
    @IBOutlet weak var addNoteButton: UIButton!
    @IBOutlet weak var addNoteView: AddNoteView!
    @IBOutlet weak var addNoteViewBottom: NSLayoutConstraint!
    @IBOutlet weak var addNoteButtonBottom: NSLayoutConstraint!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var stackViewTopToNavigation: NSLayoutConstraint!
    @IBOutlet weak var stackViewTopToDate: NSLayoutConstraint!
    
    @IBOutlet weak var topBgViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var smallHeaderView: UIView!
    @IBOutlet weak var smallHeaderNameLabel: UILabel!
    @IBOutlet weak var smallHeaderDescriptionLabel: UILabel!
    
    private var showsSmallHeader = false
    private var isSmallHeaderExpanded = false
    
    var step: MissionStep!
    var date: Date?
    var createNote: Bool = false
    
    var onStepDeleted: ((MissionStep) -> ())?
    var onStepUpdated: ((MissionStep) -> ())?
    
    private let generator = UIImpactFeedbackGenerator(style: .medium)
    
    private var selectedDate: Date? {
        didSet {
            if let selectedDate = selectedDate {
                dateLabel.text = "За \(selectedDate.formatted1.lowercased())"
                dateControl.backgroundColor = .darkGrey
                dateLabel.textColor = .white
                dateImageView.backgroundColor = .white.withAlphaComponent(0.4)
                dateImageView.tintColor = .darkGrey
                dateImageView.image = .cross2
                checkImageView.isHidden = false
                checkImageView.image = step.isImplementedForDate(selectedDate) ? .checkCircleOn : .checkCircleOff
            } else {
                dateLabel.text = "За всё время"
                dateControl.backgroundColor = .bgGrey
                dateLabel.textColor = .textGrey10
                dateImageView.backgroundColor = .lightGrey
                dateImageView.tintColor = .textGrey10
                dateImageView.image = .calendar
                checkImageView.isHidden = step.frequency != StepFrequency.once.rawValue || step.id == -1
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        addNoteButton.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18)
        headerShadowView.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 30, shadowOpacity: 0.09)
        headerShadowView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        smallHeaderView.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 30, shadowOpacity: 0.09)
        smallHeaderView.isHidden = true
        
        navigationMissionButton.setTitle(step.block.mission.name?.limitCharacters(20), for: .normal)
        navigationStepButton.setTitle(step.name?.limitCharacters(20), for: .normal)
        
        navigationGradientLeft.setGradientLayer(colors: [.white, .white.withAlphaComponent(0.01)], startPoint: CGPoint(x: 0.0, y: 0.5), endPoint: CGPoint(x: 1.0, y: 0.5), cornerRadius: 0)
        navigationGradientRight.setGradientLayer(colors: [.white, .white.withAlphaComponent(0.01)], startPoint: CGPoint(x: 1.0, y: 0.5), endPoint: CGPoint(x: 0.0, y: 0.5), cornerRadius: 0)
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        stackView.setCustomSpacing(16, after: calendarView.superview!)
        
        if step.id == -1 {
            dateControl.isHidden = true
            stackViewTopToDate.priority = .defaultLow
            stackViewTopToNavigation.priority = UILayoutPriority(999)
            menuButton.isHidden = true
        }
        
        nameTextView.textContainer.lineFragmentPadding = 0
        nameTextView.textContainerInset = .zero
        descriptionTextView.textContainer.lineFragmentPadding = 0
        descriptionTextView.textContainerInset = .zero
        
        
        if let date = date, step.id >= 0 {
            selectedDate = date
            calendarView.selectedDate = date
        }
        calendarView.generateMonths()
        calendarView.missionStep = step
        calendarView.superview?.isHidden = true
        calendarView.onDateSelected = { [unowned self] date in
            self.selectedDate = date
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dateImageTapped))
        dateImageView.addGestureRecognizer(tapGesture)
        
        let checkTapGesture = UITapGestureRecognizer(target: self, action: #selector(checkImageTapped))
        checkImageView.addGestureRecognizer(checkTapGesture)
        
        addNoteView.isHidden = true
        addNoteView.step = step
        addNoteView.onHeightChanged = { [unowned self] in
            tableView.layoutHeader()
            updateAddNoteViewShadows()
        }
        addNoteView.onCursorPositionChanged = { [unowned self] textView, rect in
            let view = UIView(frame: rect)
            view.alpha = 0
            textView.addSubview(view)
            tableView.scrollToViewBottom(view)
        }
        addNoteView.onNoteAdded = { [unowned self] note in
            addNoteButton.superview!.isHidden = false
            addNoteView.isHidden = true
            addNoteViewBottom.priority = .defaultLow
            addNoteButtonBottom.priority = .defaultHigh
            tableView.layoutHeader()
            tableView.reloadData()
            
            (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Заметка добавлена", secondaryText: "К заметке →") { [unowned self] in
                openNote(note)
            }
        }
        
        displayStep()

        if step.frequency == StepFrequency.once.rawValue && step.id >= 0 {
            checkImageView.isHidden = false
            checkImageView.image = step.isImplementedForDate(step.startDate?.toDay) ? .checkCircleOn : .checkCircleOff
        } else {
            checkImageView.isHidden = true
        }
        
        if createNote {
            addNoteTapped(addNoteButton!)
            addNoteView.layer.cornerRadius = 30
            addNoteView.layer.borderColor = UIColor.lightBlue1.cgColor
            addNoteView.layer.borderWidth = 3
        }
        
        generator.prepare()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutHeader()
        addNoteButton.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18)
        updateAddNoteViewShadows()
    }
    
    private func updateAddNoteViewShadows() {
        if createNote {
            addNoteView.addShadow(offset: CGSize(width: 0, height: 2), radius: 3, cornerRadius: 30, color: UIColor(hex: "#0AB05B"), shadowOpacity: 0.5, layerName: "GreenShadow")
            addNoteView.addShadow(offset: CGSize(width: 2, height: 0), radius: 3, cornerRadius: 30, color: UIColor(hex: "#454FDE"), shadowOpacity: 0.5, layerName: "BlueShadow")
            addNoteView.addShadow(offset: CGSize(width: -2, height: 0), radius: 3, cornerRadius: 30, color: UIColor(hex: "#FFAE00"), shadowOpacity: 0.5, layerName: "YellowShadow")
            addNoteView.addShadow(offset: CGSize(width: 0, height: -2), radius: 3, cornerRadius: 30, color: UIColor(hex: "#EE6B57"), shadowOpacity: 0.5, layerName: "RedShadow")
            addNoteView.addShadow(offset: CGSize(width: 0, height: 1.5), radius: 1, cornerRadius: 30, color: .black, shadowOpacity: 0.18)
        }
    }
    
    private func displayStep() {
        nameTextView.text = step.name
        smallHeaderNameLabel.text = step.name
        if let text = step.text, !text.isEmpty {
            descriptionTextView.text = text
            descriptionTextView.isHidden = false
            smallHeaderDescriptionLabel.text = text
            smallHeaderDescriptionLabel.isHidden = false
        } else {
            descriptionTextView.isHidden = true
            smallHeaderDescriptionLabel.isHidden = true
        }
        tableView.layoutHeader()
    }
    
    private func resetCalendar() {
        calendarView.refresh()
        calendarView.selectedDate = nil
        selectedDate = nil
        if step.frequency == StepFrequency.once.rawValue {
            checkImageView.image = step.isImplementedForDate(step.startDate?.toDay) ? .checkCircleOn : .checkCircleOff
        }
    }
    
    private func notifyNoteWillBeDeleted(tabIndex: Int? = nil) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
        vc.popupTitle = "Недобавленная заметка будет удалена"
        vc.buttons = [
            ActionButton(type: .red, title: "Удалить и закрыть", action: { [unowned self] _ in
                close(tabIndex: tabIndex)
            }),
            ActionButton(type: .blue, title: "Добавить и закрыть", action: { [unowned self] _ in
                addNoteView.save()
                close(tabIndex: tabIndex)
            }),
            ActionButton(type: .secondary, title: "Вернуться к редактированию", action: { _ in })
        ]
        presentBottomSheet(vc, height: 200)
    }
    
    private func close(tabIndex: Int? = nil) {
        if let tabIndex = tabIndex {
            let mainVC = (UIApplication.shared.keyWindow?.rootViewController as! MainViewController)
            mainVC.switchTab(tabIndex: tabIndex)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func backTapped(_ sender: Any) {
        if addNoteView.hasData {
            notifyNoteWillBeDeleted()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func navigationMyMissionsTapped(_ sender: Any) {
        if let nc = navigationController {
            var controllers = nc.viewControllers
            for vc in controllers {
                if vc is MyMissionsViewController {
                    nc.popToViewController(vc, animated: true)
                    return
                }
            }
            controllers.removeLast(controllers.count - 1)
            let myMissionsVC = storyboard!.instantiateViewController(withIdentifier: "MyMissionsVC")
            controllers.append(myMissionsVC)
            nc.setViewControllers(controllers, animated: true)
        }
    }
    
    @IBAction func navigationMissionTapped(_ sender: Any) {
        guard let nc = navigationController else { return }
        var controllers = nc.viewControllers
        controllers.removeLast()
        if let missionVC = controllers.last as? MissionViewController {
            if missionVC.mission.objectID == step.block.mission.objectID {
                navigationController?.popViewController(animated: true)
            } else {
                controllers.removeLast()
                let vc = storyboard?.instantiateViewController(withIdentifier: "MissionVC") as! MissionViewController
                vc.mission = step.block.mission
                controllers.append(vc)
            }
        }
        nc.setViewControllers(controllers, animated: true)
    }
    
    @IBAction func menuTapped(_ sender: Any) {
        let mainVC = (UIApplication.shared.keyWindow?.rootViewController as! MainViewController)
        let menuUnderlayControl =  mainVC.addMenuUnderlayControl(color: .clear)
        
        let menuView = MenuView()
        var items = [MenuItemData]()
        items.append(MenuItemData(text: "Изменить", image: .edit, type: .normal, action: { [unowned self] in
            menuUnderlayControl.removeFromSuperview()
            openEditStep(mission: step.block.mission, step: step) { [unowned self] step in
                navigationStepButton.setTitle(step.name?.limitCharacters(20), for: .normal)
                displayStep()
                resetCalendar()
                (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Шаг изменён")
            }
        }))
        items.append(MenuItemData(text: "Переместить", image: .target, type: .normal, action: { [unowned self] in
            menuUnderlayControl.removeFromSuperview()
            
            let vc = storyboard!.instantiateViewController(identifier: "MoveStepVC") as! MoveStepViewController
            vc.step = step
            vc.onMoved = { [unowned self] in
                (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Шаг перемещён")
                navigationMissionButton.setTitle(step.block.mission.name?.limitCharacters(20), for: .normal)
            }
            presentFullScreen(vc)
        }))
        items.append(MenuItemData(text: "Удалить", image: .trash, type: .red, action: { [unowned self] in
            menuUnderlayControl.removeFromSuperview()
            
            openDeleteStep(step, date: selectedDate, onDeleted: { [unowned self] in
                onStepDeleted?(step)
                navigationController?.popViewController(animated: true)
            }, onUpdated: { [unowned self] in
                onStepUpdated?(step)
                resetCalendar()
                tableView.reloadData()
            })
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
    
    @IBAction func dateTapped(_ sender: Any) {
        calendarView.superview?.isHidden = !calendarView.superview!.isHidden
        tableView.layoutHeader()
    }
    
    @IBAction func addNoteTapped(_ sender: Any) {
        addNoteButton.superview!.isHidden = true
        addNoteView.isHidden = false
        addNoteViewBottom.priority = .defaultHigh
        addNoteButtonBottom.priority = .defaultLow
        tableView.layoutHeader()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if let `self` = self {
                self.tableView.scrollToViewBottom(self.addNoteView)
            }
        }
    }
    
    @IBAction func smallHeaderTapped(_ sender: Any) {
        isSmallHeaderExpanded = !isSmallHeaderExpanded
        if isSmallHeaderExpanded {
            smallHeaderNameLabel.numberOfLines = 0
            smallHeaderDescriptionLabel.numberOfLines = 0
        } else {
            smallHeaderNameLabel.numberOfLines = 1
            smallHeaderDescriptionLabel.numberOfLines = 1
        }
        smallHeaderNameLabel.invalidateIntrinsicContentSize()
        smallHeaderDescriptionLabel.invalidateIntrinsicContentSize()
        smallHeaderNameLabel.superview!.layoutIfNeeded()
    }
    
    @objc func dateImageTapped(_ gesture: UITapGestureRecognizer) {
        if selectedDate != nil {
            selectedDate = nil
            calendarView.clearSelectionDate()
            calendarView.superview?.isHidden = true
            tableView.layoutHeader()
        } else {
            dateTapped(dateControl!)
        }
    }
    
    @objc func checkImageTapped(_ gesture: UITapGestureRecognizer) {
        guard let date = (step.frequency == StepFrequency.once.rawValue ? step.startDate?.toDay : selectedDate) else {
            return
        }
        switchStepImplemented(step, date: date) { [unowned self] checked in
            checkImageView.image = checked ? .checkCircleOn : .checkCircleOff
            calendarView.refresh()
        }
    }
}

extension StepViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let notesCount = step.notes?.allObjects.count ?? 0
        return notesCount / 2 + notesCount % 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCell", for: indexPath)
        let notes = step.notes?.allObjects.map { $0 as! MissionNote }.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) } ?? []
        
        let view1 = cell.viewWithTag(1) as! NoteView
        let onNoteLongTap: (MissionNote, UIImage, CGRect) -> () = { [unowned self] note, image, rect in
            self.generator.impactOccurred()
            self.generator.prepare()
            self.showNoteMenu(note: note, anchorRect: rect, image: image, onDeleted: { [unowned self] stepDeleted in
                if stepDeleted {
                    self.onStepDeleted?(step)
                    self.navigationController?.popViewController(animated: true)
                } else {
                    self.tableView.reloadData()
                }
            })
        }
        
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView.contentOffset.y < 0 {
            topBgViewHeight.constant = -scrollView.contentOffset.y
        } else {
            topBgViewHeight.constant = 0
        }

        if scrollView.contentOffset.y > addNoteButton.superview!.frame.minY - 16 - smallHeaderView.frame.height + 30 {
            if !showsSmallHeader {
                showsSmallHeader = true
                smallHeaderView.isHidden = false
            }
        } else {
            if showsSmallHeader {
                showsSmallHeader = false
                smallHeaderView.isHidden = true
                
                if isSmallHeaderExpanded {
                    isSmallHeaderExpanded = false
                    smallHeaderNameLabel.numberOfLines = 1
                    smallHeaderDescriptionLabel.numberOfLines = 1
                    smallHeaderNameLabel.invalidateIntrinsicContentSize()
                    smallHeaderDescriptionLabel.invalidateIntrinsicContentSize()
                    smallHeaderNameLabel.superview!.layoutIfNeeded()
                }
            }
        }
    }
}
