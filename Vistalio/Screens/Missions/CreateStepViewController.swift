//
//  CreateStepViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 04.06.2026.
//

import UIKit
import FittedSheets
import IQKeyboardManagerSwift

class CreateStepViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var backToOriginalButton: UIButton!
    
    @IBOutlet weak var nameTextView: GrowingTextView!
    @IBOutlet weak var descriptionTextView: GrowingTextView!
    @IBOutlet weak var frequencyControl: DropDownControl!
    
    @IBOutlet weak var startDateCalendarView: CalendarView!
    @IBOutlet weak var startDateLabel: UILabel!
    
    @IBOutlet weak var endDateControl: UIControl!
    @IBOutlet weak var endDateCalendarView: CalendarView!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var endDateImageView: UIImageView!
    
    @IBOutlet weak var saveButton: UIButton!
    
    var mission: Mission!
    var step: MissionStep?
    var onStepSaved: ((MissionStep) -> ())?
    
    private var startDate: Date? {
        didSet {
            if let startDate = startDate {
                startDateLabel.text = startDate.formatted1
                endDateCalendarView.minDate = startDate
            }
        }
    }
    
    private var endDate: Date? {
        didSet {
            if let endDate = endDate {
                endDateLabel.text = endDate.formatted1
                endDateControl.backgroundColor = .darkGrey
                endDateLabel.textColor = .white
                endDateImageView.backgroundColor = .white.withAlphaComponent(0.4)
                endDateImageView.image = .cross2
            } else {
                endDateLabel.text = "Не указано"
                endDateControl.backgroundColor = .bgGrey
                endDateLabel.textColor = .textGrey10
                endDateImageView.backgroundColor = .lightGrey
                endDateImageView.image = .calendar
            }
            startDateCalendarView.maxDate = endDate
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        saveButton.isEnabled = false
        saveButton.superview!.bringSubviewToFront(saveButton)
        setupBottomConstraint(saveButton)
        
        backToOriginalButton.superview!.isHidden = step == nil || step!.isOriginal
        
        nameTextView.delegate = self
        
        frequencyControl.parentVC = sheetViewController
        frequencyControl.items = StepFrequency.allCases.map { DropItemData(text: $0.displayName) }
        frequencyControl.checkedIndex = 0
        frequencyControl.onBeforeShowItems = { [unowned self] in
            let screenHeight = UIScreen.main.bounds.height
            let origin = frequencyControl.superview!.convert(frequencyControl.frame.origin, to: nil)
            let window = UIApplication.shared.windows.first
            let bottom = max(window?.safeAreaInsets.bottom ?? 0, 8)
            let dropDownBottom = origin.y + 47 + CGFloat(frequencyControl.height)
            let maxY = screenHeight - bottom
            if dropDownBottom > maxY {
                contentView.transform = CGAffineTransform(translationX: 0, y: maxY - dropDownBottom)
            }
        }
        
        startDate = Date()
        startDateCalendarView.selectedDate = startDate
        startDateCalendarView.superview!.isHidden = true
        startDateCalendarView.onDateSelected = { [unowned self] date in
            self.startDate = date
            self.startDateCalendarView.superview!.isHidden = true
        }
        
        endDateLabel.text = "Не указано"
        endDateCalendarView.superview!.isHidden = true
        endDateCalendarView.onDateSelected = { [unowned self] date in
            self.endDate = date
            self.endDateCalendarView.superview!.isHidden = true
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(endDateImageTapped))
        endDateImageView.addGestureRecognizer(tapGesture)
        
        displayStep()
        
        startDateCalendarView.generateMonths()
        endDateCalendarView.generateMonths()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDropDownClosed(notification:)), name: .menuClosed, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .menuClosed, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        IQKeyboardManager.shared.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared.isEnabled = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.height - saveButton.frame.minY + 20, right: 0)
    }
    
    private func displayStep() {
        if let step = step {
            titleLabel.text = "Изменить шаг"
            nameTextView.text = step.name
            descriptionTextView.text = step.text
            frequencyControl.checkedIndex = Int(step.frequency)
            startDateCalendarView.selectedDate = step.startDate ?? Date()
            endDateCalendarView.selectedDate = step.endDate
            startDate = step.startDate
            endDate = step.endDate
            updateSaveButton()
        }
    }
    
    @IBAction func closeTapped() {
        var hasChanges = false
        let text = descriptionTextView.text.trim()
        
        if let step = step {
            hasChanges = name != step.name || text != step.text || frequencyControl.checkedIndex != step.frequency || startDate != step.startDate || endDate != step.endDate
        } else {
            hasChanges = !name.isEmpty || !text.isEmpty || frequencyControl.checkedIndex != 0 || !(startDate?.isSameDay(Date()) ?? true) || endDate != nil
        }
        
        if hasChanges {
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
            vc.popupTitle = "Изменения не сохранены"
            vc.buttons = [
                ActionButton(type: .red, title: "Выйти без сохранения", action: { [unowned self] in
                    self.dismiss(animated: true)
                }), ActionButton(type: .secondary, title: "Вернуться к редактированию", action: { })
            ]
            presentBottomSheet(vc, height: 200)
        } else {
            dismiss(animated: true)
        }
    }
    
    @IBAction func backToOriginalTapped(_ sender: AnyObject) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
        vc.popupTitle = "Вернуть исходный вариант?"
        vc.popupText = "Вернём те настройки шага, что были, когда вы его добавляли."
        vc.showClose = true
        vc.buttons = [
            ActionButton(type: .primary, title: "Вернуть", action: { [unowned self] in
                
                backToOriginalButton.superview!.isHidden = true
                
                nameTextView.text = step?.originalName
                descriptionTextView.text = step?.originalText
                frequencyControl.checkedIndex = 0
            })
        ]
        presentBottomSheet(vc, height: 200)
    }
    
    @IBAction func startDateTapped(_ sender: AnyObject) {
        view.endEditing(true)
        startDateCalendarView.superview!.isHidden = !startDateCalendarView.superview!.isHidden
        if !startDateCalendarView.superview!.isHidden {
            endDateCalendarView.superview!.isHidden = true
        }
        if !startDateCalendarView.superview!.isHidden {
            DispatchQueue.main.async {
                self.scrollView.scrollToViewBottom(self.startDateCalendarView)
            }
        }
    }
    
    @IBAction func endDateTapped(_ sender: AnyObject) {
        view.endEditing(true)
        endDateCalendarView.superview!.isHidden = !endDateCalendarView.superview!.isHidden
        if !endDateCalendarView.superview!.isHidden {
            startDateCalendarView.superview!.isHidden = true
        }
        if !endDateCalendarView.superview!.isHidden {
            DispatchQueue.main.async {
                self.scrollView.scrollToViewBottom(self.endDateCalendarView)
            }
        }
    }
    
    @IBAction func saveTapped(_ sender: AnyObject) {
        var step = self.step
        var isNew = step == nil
        let frequency = StepFrequency.allCases[frequencyControl.checkedIndex]
        CoreDataStack.shared.performAndWait { context in
            if step == nil {
                step = MissionStep.create(context: context, mission: mission, name: name, text: descriptionTextView.text.trim(), frequency: frequency, startDate: startDateCalendarView.selectedDate!, endDate: endDateCalendarView.selectedDate)
                step?.sortOrder = mission.maxSortOrder + 1
            } else {
                if step?.block.id != -1 {
                    if step?.originalName == nil {
                        step?.originalName = step?.name
                        step?.originalText = step?.text
                    }
                }
                step?.name = name
                step?.text = descriptionTextView.text.trim()
                step?.frequency = frequency.rawValue
                step?.startDate = startDateCalendarView.selectedDate!
                step?.endDate = endDateCalendarView.selectedDate
            }
        }
        if let step = step {
            dismiss(animated: true) { [weak self] in
                self?.onStepSaved?(step)
            }
        }
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        saveButton.isHidden = true
    }
    
    @objc func keyboardDidHide(notification: Notification) {
        saveButton.isHidden = false
    }
    
    @objc func onDropDownClosed(notification: Notification) {
        contentView.transform = CGAffineTransform(translationX: 0, y: 0)
    }
    
    @objc func endDateImageTapped(_ gesture: UITapGestureRecognizer) {
        if endDate != nil {
            endDate = nil
            endDateCalendarView.clearSelectionDate()
        } else {
            endDateTapped(endDateCalendarView)
        }
    }
    
    private func updateSaveButton() {
        saveButton.isEnabled = !name.isEmpty
    }
    
    private var name: String {
        return nameTextView.text.trim()
    }
}

extension CreateStepViewController: GrowingTextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateSaveButton()
    }
}
