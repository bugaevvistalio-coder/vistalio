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
    
    var step: MissionStep!
    var date: Date?
    
    var onStepDeleted: ((MissionStep) -> ())?
    var onStepUpdated: ((MissionStep) -> ())?
    
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
                checkImageView.isHidden = step.frequency != StepFrequency.once.rawValue
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        addNoteButton.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18)
        headerShadowView.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 30, shadowOpacity: 0.09)
        
        navigationMissionButton.setTitle(step.block.mission.name?.limitCharacters(20), for: .normal)
        navigationStepButton.setTitle(step.name?.limitCharacters(20), for: .normal)
        
        navigationGradientLeft.setGradientLayer(colors: [.white, .white.withAlphaComponent(0.01)], startPoint: CGPoint(x: 0.0, y: 0.5), endPoint: CGPoint(x: 1.0, y: 0.5), cornerRadius: 0)
        navigationGradientRight.setGradientLayer(colors: [.white, .white.withAlphaComponent(0.01)], startPoint: CGPoint(x: 1.0, y: 0.5), endPoint: CGPoint(x: 0.0, y: 0.5), cornerRadius: 0)
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        
        nameTextView.textContainer.lineFragmentPadding = 0
        nameTextView.textContainerInset = .zero
        descriptionTextView.textContainer.lineFragmentPadding = 0
        descriptionTextView.textContainerInset = .zero
        
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
        addNoteView.onHeightChanged = { [unowned self] in
            tableView.layoutHeader()
        }
        addNoteView.onCursorPositionChanged = { [unowned self] textView, rect in
            let view = UIView(frame: rect)
            view.alpha = 0
            textView.addSubview(view)
            tableView.scrollToViewBottom(view)
        }
        
        displayStep()

        if step.frequency == StepFrequency.once.rawValue {
            checkImageView.isHidden = false
            checkImageView.image = step.isImplementedForDate(step.startDate?.toDay) ? .checkCircleOn : .checkCircleOff
        } else {
            checkImageView.isHidden = true
        }
        
        if let date = date {
            selectedDate = date
            calendarView.selectedDate = date
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutHeader()
        addNoteButton.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18)
    }
    
    private func displayStep() {
        nameTextView.text = step.name
        if let text = step.text, !text.isEmpty {
            descriptionTextView.text = text
            descriptionTextView.isHidden = false
        } else {
            descriptionTextView.isHidden = true
        }
    }
    
    private func resetCalendar() {
        calendarView.refresh()
        calendarView.selectedDate = nil
        selectedDate = nil
        if step.frequency == StepFrequency.once.rawValue {
            checkImageView.image = step.isImplementedForDate(step.startDate?.toDay) ? .checkCircleOn : .checkCircleOff
        }
    }
    
    @IBAction func backTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
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
