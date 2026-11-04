//
//  EditTimeViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 05.10.2026.
//

import UIKit
import FittedSheets

class EditTimeViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var timeControl: UIControl!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var drinkControl: DropDownControl!
    @IBOutlet weak var mlControl: DropDownControl!
    @IBOutlet weak var mlTextField: UITextField!
    @IBOutlet weak var mlLabel: UILabel!
    @IBOutlet weak var mlLabelLeading: NSLayoutConstraint!
    
    @IBOutlet weak var saveButton: UIButton!
    
    var step: MissionStep!
    var onStepSaved: (() -> ())?
    
    private var time: String? {
        didSet {
            timeLabel.text = time
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        setupBottomConstraint(saveButton)
        
        time = step.formattedTime
        
        if step.ml == 0 {
            drinkControl.superview?.isHidden = true
            mlControl.superview?.isHidden = true
        } else {
            setupDropDowns()
            NotificationCenter.default.addObserver(self, selector: #selector(onDropDownClosed(notification:)), name: .menuClosed, object: nil)
        }
    }
    
    deinit {
        if step.ml != 0 {
            NotificationCenter.default.removeObserver(self, name: .menuClosed, object: nil)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        timeControl.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        drinkControl.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        mlControl.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.height - saveButton.frame.minY + 20, right: 0)
    }
    
    private func setupDropDowns() {
        drinkControl.parentVC = sheetViewController
        drinkControl.items = [DropItemData(text: "☕ Кофе", image: nil), DropItemData(text: "🫖 Чай", image: nil), DropItemData(text: "💧 Вода", image: nil), DropItemData(text: "🍎 Сок", image: nil), DropItemData(text: "🥤 Газировка", image: nil)]
        drinkControl.checkedIndex = drinkControl.items.firstIndex(where: { $0.text == step.name! }) ?? 0
        drinkControl.onBeforeShowItems = { [unowned self] in
            beforeDropDownOpened(drinkControl)
        }
        
        mlControl.parentVC = sheetViewController
        mlControl.items = [DropItemData(text: "200 мл", image: .ml200), DropItemData(text: "250 мл", image: .ml250), DropItemData(text: "300 мл", image: .ml300), DropItemData(text: "330 мл", image: .ml330), DropItemData(text: "500 мл", image: .ml500), DropItemData(text: "Другой", image: nil)]
        mlControl.checkedIndex = mlControl.items.firstIndex(where: { $0.text == "\(step.ml) мл" } ) ?? 5
        mlControl.onBeforeShowItems = { [unowned self] in
            beforeDropDownOpened(drinkControl)
        }
        mlControl.onChecked = { [unowned self] index in
            if index == 5 {
                if mlTextField.isHidden {
                    mlTextField.isHidden = false
                    mlTextField.text = nil
                    mlTextField.becomeFirstResponder()
                }
            } else {
                mlTextField.isHidden = true
                mlLabel.isHidden = true
            }
        }
        
        mlTextField.layer.cornerRadius = 20
        mlTextField.setLeftPadding(8)
        mlTextField.setRightPadding(8)
        mlTextField.delegate = self
        
        if mlControl.checkedIndex == 5 {
            mlTextField.isHidden = false
            mlTextField.text = "\(step.ml)"
            mlChanged(mlTextField)
        } else {
            mlTextField.isHidden = true
            mlLabel.isHidden = true
        }
    }
    
    private func beforeDropDownOpened(_ dropDownControl: DropDownControl) {
        let screenHeight = UIScreen.main.bounds.height
        let origin = dropDownControl.superview!.convert(dropDownControl.frame.origin, to: nil)
        let window = UIApplication.shared.windows.first
        let bottom = max(window?.safeAreaInsets.bottom ?? 0, 8)
        let dropDownBottom = origin.y + 47 + CGFloat(dropDownControl.height)
        let maxY = screenHeight - bottom
        if dropDownBottom > maxY {
            contentView.transform = CGAffineTransform(translationX: 0, y: maxY - dropDownBottom)
        }
    }
    
    @IBAction func closeTapped() {
        dismiss(animated: true)
    }
    
    @IBAction func timeTapped(_ sender: AnyObject) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectTimeVC") as! SelectTimeViewController
        vc.time = time
        vc.onTimeSelected = { [unowned self] time in
            self.time = time
        }
        let bottom = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        presentBottomSheet(vc, height: 400 + bottom)
    }
    
    @IBAction func mlChanged(_ sender: AnyObject) {
        let text = mlTextField.text ?? ""
        mlLabel.isHidden = text.isEmpty
        mlLabelLeading.constant = text.width(withHeight: 20, font: mlLabel.font) + 12
    }
    
    @IBAction func saveTapped(_ sender: AnyObject) {
        var newName: String?
        var newMl: Int16? = -1
        var drinkStepUpdated = false
        if step.ml > 0 {
            newName = drinkControl.items[drinkControl.checkedIndex].text
            if self.mlControl.checkedIndex < 5 {
                newMl = [200, 250, 300, 330, 500][self.mlControl.checkedIndex]
            } else if let text = mlTextField.text {
                newMl = Int16(text) ?? 1
            }
            drinkStepUpdated = step.name != newName || step.ml != newMl
        }
        if let time = time, (step.time != time || drinkStepUpdated) {
            CoreDataStack.shared.performAndWait { [unowned self] context in
                self.step.time = time
                if self.step.ml > 0 {
                    self.step.name = newName
                    self.step.ml = newMl ?? 0
                }
            }
            NotificationCenter.default.post(name: .stepUpdated, object: nil)
            onStepSaved?()
            
            step.scheduleDailyNotifications(time: time, rescheduleExisting: true)
            step.block.mission.addedSteps.forEach {
                if let t = $0.time, t.hasSuffix("/\(step.id)"), let formattedTime = $0.formattedTime {
                    $0.scheduleDailyNotifications(time: formattedTime, rescheduleExisting: true)
                }
            }
        }
        if step.ml > 0 {
            step.block.unlockNextBlock()
        }
        dismiss(animated: true)
    }
    
    @objc func onDropDownClosed(notification: Notification) {
        contentView.transform = CGAffineTransform(translationX: 0, y: 0)
        drinkControl.reset()
        mlControl.reset()
    }
}

extension EditTimeViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 1. Получаем текущий текст в UITextField
        let currentText = textField.text ?? ""
        
        // 2. Формируем будущий текст, который получится после изменения
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        // 3. Если пользователь полностью стирает текст — разрешаем
        if updatedText.isEmpty {
            return true
        }
        
        // 4. Проверка на валидность целого числа (разрешены только цифры 0-9)
        // Это также защищает от вставки букв или спецсимволов из буфера обмена
        let isNumeric = updatedText.allSatisfy { $0.isNumber }
        if !isNumeric {
            return false
        }
        
        // 5. Запрет нуля в самом начале строки
        if updatedText.hasPrefix("0") {
            return false
        }
        
        // 6. Ограничение по длине — не более 3 символов
        if updatedText.count > 3 {
            return false
        }
        
        return true
    }
}
