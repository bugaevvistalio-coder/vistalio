//
//  UIViewController+Utils.swift
//  Vistalio
//
//  Created by Julia Konkova on 29.03.2026.
//

import UIKit
import FittedSheets
import PhotosUI

extension UIViewController {
    
    func presentFullScreen(_ vc: UIViewController) {
        let window = UIApplication.shared.windows.first
        let top = (window?.safeAreaInsets.top ?? 20)
        presentBottomSheet(vc, height: UIScreen.main.bounds.height - top)
    }
    
    func presentBottomSheet(_ controller: UIViewController, height: CGFloat? = nil) {
        let options = SheetOptions(shrinkPresentingViewController: false)
        let sizes: [SheetSize] = height != nil ? [.fixed(height!)] : [.intrinsic]
        let sheetController = SheetViewController(controller: controller, sizes: sizes, options: options)
        sheetController.allowPullingPastMaxHeight = false
        sheetController.cornerRadius = 30
        sheetController.gripColor = .clear
        present(sheetController, animated: true, completion: nil)
    }
    
    func setupBottomConstraint(_ view: UIView) {
        let window = UIApplication.shared.windows.first
        let hasSafeArea = (window?.safeAreaInsets.bottom ?? 0) > 0
        view.superview?.constraints.filter { $0.firstAttribute == .bottom && $0.firstItem === view || $0.secondAttribute == .bottom && $0.secondItem === view }.forEach {
            $0.constant = hasSafeArea ? 0 : 20
        }
    }
    
    func openCamera(delegate: Any? = nil, video: Bool = false) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = ((delegate ?? self) as? UIImagePickerControllerDelegate & UINavigationControllerDelegate)
            imagePicker.sourceType = .camera
            if video {
                imagePicker.mediaTypes = ["public.image", "public.movie"]
            }
            imagePicker.modalPresentationStyle = .overFullScreen
            present(imagePicker, animated: true, completion: nil)
        } else {
            print("Camera not available on this device/simulator.")
        }
    }
    
    func openGallery(delegate: Any? = nil, limit: Int = 1, video: Bool = false) {
        var configuration = PHPickerConfiguration()
        configuration.filter = video ? .any(of: [.images, .videos]) : .images
        configuration.selectionLimit = limit
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = (delegate ?? self)  as? PHPickerViewControllerDelegate
        present(picker, animated: true)
    }
    
    func openMission(_ mission: Mission) {
        let sb = UIStoryboard(name: "Missions", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "MissionVC") as! MissionViewController
        vc.mission = mission
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func openEditMission(_ mission: Mission, onMissionUpdated: ((Mission) -> ())?) {
        let storyboard = UIStoryboard(name: "Missions", bundle: nil)
        let nc = storyboard.instantiateViewController(identifier: "CreateMissionNC") as! UINavigationController
        let vc = nc.viewControllers.first as! CreateMissionViewController
        vc.mission = mission
        vc.onMissionUpdated = onMissionUpdated
        
        let window = UIApplication.shared.windows.first
        let top = (window?.safeAreaInsets.top ?? 20)
        presentBottomSheet(nc, height: UIScreen.main.bounds.height - top)
    }
    
    func openArchiveMission(_ mission: Mission) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
        vc.popupTitle = mission.archivedAt != nil ? "Убрать миссию из архива?" : "Убрать миссию в архив?"
        vc.popupText = mission.archivedAt != nil ? "Снова начнём напоминать о её шагах и предлагать новые. Можно отменить в любой момент." : "Мы перестанем напоминать о её шагах и предлагать новые. Можно отменить в любой момент."
        vc.buttons = [
            ActionButton(type: mission.archivedAt != nil ? .blue : .red, title: mission.archivedAt != nil ? "Убрать из архива" : "Убрать в архив", action: { _ in CoreDataStack.shared.performAndWait { context in
                if mission.archivedAt != nil {
                    mission.archivedAt = nil
                } else {
                    mission.archivedAt = Date()
                }
                }
                NotificationCenter.default.post(name: .missionUpdated, object: nil)
                (UIApplication.shared.delegate as! AppDelegate).addNotification(text: mission.archivedAt != nil ? "Миссия перемещена в архив" : "Миссия убрана из архива")
            }),
            ActionButton(type: .secondary, title: "Отменить", action: { _ in })
        ]
        presentBottomSheet(vc, height: 200)
    }
    
    func openDeleteMission(_ mission: Mission) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
        vc.popupTitle = "Удалить миссию?"
        vc.popupText = "Нельзя отменить. По умолчанию все заметки удаляемой миссии помещаются в миссию «Общие заметки»."
        vc.checkText = "Удалить вместе с заметками"
        vc.buttons = [
            ActionButton(type: .red, title: "Удалить", action: { [unowned self] checked in
                CoreDataStack.shared.performAndWait { context in
                    if !checked {
                        let notes = mission.addedSteps.flatMap { $0.notes?.allObjects ?? [] }.map { $0 as! MissionNote }
                        if !notes.isEmpty, let notesMission = MissionsHolder.shared.getNotesMission(context: context), let step = MissionStep.create(context: context, mission: notesMission, name: "Удалённые заметки миссии «\(mission.name ?? "")»", text: nil, frequency: .once, startDate: Date(), endDate: nil) {
                            notes.forEach { $0.step = step }
                        }
                    }
                    context.delete(mission)
                }
                NotificationCenter.default.post(name: .missionUpdated, object: nil)
                self.navigationController?.popViewController(animated: true)
                (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Миссия удалена")
            }),
            ActionButton(type: .secondary, title: "Отменить", action: { _ in })
        ]
        presentBottomSheet(vc, height: 200)
    }
    
    func openHideMissionTemplate(_ template: MissionTemplate, onHidden: (() -> ())? = nil) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
        vc.popupTitle = "Скрыть миссию?"
        vc.popupText = "Перестанем её рекомендовать.\nМожно отменить в любой момент."
        vc.showClose = true
        vc.buttons = [
            ActionButton(type: .red, title: "Скрыть", action: { _ in
                template.hiddenAt = Date()
                CoreDataStack.shared.performAndWait { context in
                    HiddenMissionTemplate.create(context: context, templateId: template.id)
                }
                NotificationCenter.default.post(name: .templatesUpdated, object: nil)
                onHidden?()
            })
        ]
        presentBottomSheet(vc, height: 200)
    }
    
    func openShowMissionTemplate(_ template: MissionTemplate, onShown: (() -> ())? = nil) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
        vc.popupTitle = "Убрать миссию из скрытых?"
        vc.popupText = "Снова будем её рекомендовать.\nМожно отменить в любой момент."
        vc.showClose = true
        vc.buttons = [
            ActionButton(type: .primary, title: "Показать", action: { _ in
                template.hiddenAt = nil
                CoreDataStack.shared.performAndWait { context in
                    let request = HiddenMissionTemplate.hiddenMissionTemplateFetchRequest()
                    request.predicate = NSPredicate(format: "templateId == %d", template.id)
                    do {
                        let objects = try context.fetch(request)
                        for object in objects {
                            context.delete(object)
                        }
                    } catch {
                        print("Delete template failed: \(error)")
                    }
                }
                NotificationCenter.default.post(name: .templatesUpdated, object: nil)
                onShown?()
            })
        ]
        presentBottomSheet(vc, height: 200)
    }
    
    func openDeleteStep(_ step: MissionStep, date: Date? = nil, onDeleted: @escaping () -> (), onUpdated: @escaping () -> ()) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
        vc.popupTitle = "Удалить шаг?"
        vc.popupText = "Нельзя отменить. По умолчанию все заметки удаляемого шага помещаются в шаг «Шаг для общих заметок»."
        if (step.notes?.count ?? 0) > 0 {
            vc.checkText = "Удалить вместе с заметками"
        }
        
        var buttons = [ActionButton]()
        
        if let date = date, !step.hasSingleDate {
            buttons.append(ActionButton(type: .red, title: "Удалить текущий", action: { checked in
                CoreDataStack.shared.performAndWait { context in
                    RemovedStep.create(context: context, step: step, date: date)
                    for item in step.implementedSteps?.allObjects ?? [] {
                        let implemented = item as! ImplementedStep
                        if implemented.date.toDay == date {
                            context.delete(implemented)
                        }
                    }
                    if !checked && (step.notes?.count ?? 0) > 0 {
                        step.moveNotesToNotesStep(context: context, date: date, afterDate: false)
                    }
                }
                onUpdated()
                (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Экземпляр шага удалён")
            }))
            buttons.append(ActionButton(type: .red, title: "Удалить этот и все последующие", action: { checked in
                if date == step.startDate?.toDay {
                    step.delete(withNotes: checked)
                    onDeleted()
                    (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Шаг удалён")
                } else {
                    CoreDataStack.shared.performAndWait { context in
                        let endDate = date.startOfDay.addingTimeInterval(-24 * 60 * 60)
                        step.endDate = endDate.toDateString
                        for item in step.implementedSteps?.allObjects ?? [] {
                            let implemented = item as! ImplementedStep
                            if implemented.date.toDay > endDate {
                                context.delete(implemented)
                            }
                        }
                        if !checked && (step.notes?.count ?? 0) > 0 {
                            step.moveNotesToNotesStep(context: context, date: date, afterDate: true)
                        }
                    }
                    onUpdated()
                    (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Экземпляры шага удалены")
                }
            }))
            buttons.append(ActionButton(type: .red, title: "Удалить всю серию", action: { checked in
                step.delete(withNotes: checked)
                onDeleted()
                (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Шаг удалён")
            }))
        } else {
            buttons.append(ActionButton(type: .red, title: "Удалить", action: { checked in
                step.delete(withNotes: checked)
                onDeleted()
                (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Шаг удалён")
            }))
        }
        buttons.append(ActionButton(type: .secondary, title: "Отменить", action: { _ in }))
        vc.buttons = buttons
        presentBottomSheet(vc, height: 200)
    }
    
    func openEditStep(mission: Mission, step: MissionStep? = nil, onStepSaved: @escaping (MissionStep) -> ()) {
        let sb = UIStoryboard(name: "Missions", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "CreateStepVC") as! CreateStepViewController
        vc.mission = mission
        vc.step = step
        vc.onStepSaved = onStepSaved
        let window = UIApplication.shared.windows.first
        let top = (window?.safeAreaInsets.top ?? 20)
        presentBottomSheet(vc, height: UIScreen.main.bounds.height - top)
    }
    
    func openStep(_ step: MissionStep, date: Date? = nil, createNote: Bool = false) {
        let sb = UIStoryboard(name: "Missions", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "StepVC") as! StepViewController
        vc.step = step
        vc.date = date
        vc.createNote = createNote
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func openNote(_ note: MissionNote) {
        let sb = UIStoryboard(name: "Missions", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "NoteVC") as! NoteViewController
        vc.note = note
        UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
    }
    
    func addMenuUnderlayControl(color: UIColor) -> UIControl {
        let control = UIControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(control)
        
        let constraints = [
            control.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            control.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            control.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            control.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
        ]
        NSLayoutConstraint.activate(constraints)
        
        control.backgroundColor = color
        control.addTarget(self, action: #selector(menuTappedOutside), for: .touchUpInside)
        
        return control
    }
    
    @objc func menuTappedOutside(_ sender: Any) {
        let menuUnderlayControl = sender as! UIControl
        menuUnderlayControl.removeFromSuperview()
        NotificationCenter.default.post(name: .menuClosed, object: nil)
    }
    
    func switchStepImplemented(_ step: MissionStep, date: Date, onSwitched: @escaping (Bool) -> ()) {
        let implemented = step.getImplementedForDate(date)
        if implemented == nil && step.frequency == StepFrequency.untilDone.rawValue {
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
            vc.popupTitle = "Все повторы шага после даты выполнения будут удалены"
            vc.popupText = "Заметки будут сохранены."
            vc.buttons = [
                ActionButton(type: .primary, title: "Сделать шаг выполненным", action: { [unowned self] _ in
                    switchImplemented(step, date: date, implementedStep: implemented, onSwitched: onSwitched)
                }),
                ActionButton(type: .secondary, title: "Отменить", action: { _ in })
            ]
            presentBottomSheet(vc, height: 200)
        } else {
            switchImplemented(step, date: date, implementedStep: implemented, onSwitched: onSwitched)
        }
    }
    
    private func switchImplemented(_ step: MissionStep, date: Date, implementedStep: ImplementedStep?, onSwitched: (Bool) -> ()) {
        var checked = false
        CoreDataStack.shared.performAndWait { context in
            if let implemented = implementedStep {
                context.delete(implemented)
            } else {
                ImplementedStep.create(context: context, step: step, date: date)
                checked = true
            }
        }
        onSwitched(checked)
    }
    
    func showMenu(items: [MenuItemData], menuUnderlayControl: UIControl, anchorRect: CGRect, image: UIImage, hMargin: CGFloat) {
        
        let menuView = MenuView()
        menuView.items = items
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(menuView)
        
        let screenHeight = UIScreen.main.bounds.height
        let menuHeight = CGFloat(menuView.height)
        let horizontalConstraint: NSLayoutConstraint
        if anchorRect.minX < UIScreen.main.bounds.width / 2 {
            horizontalConstraint = menuView.leftAnchor.constraint(equalTo: menuUnderlayControl.leftAnchor, constant: hMargin)
        } else {
            horizontalConstraint = menuView.rightAnchor.constraint(equalTo: menuUnderlayControl.rightAnchor, constant: -hMargin)
        }
        let verticalConstraint = anchorRect.maxY + 20 + menuHeight > screenHeight ? menuView.bottomAnchor.constraint(equalTo: menuUnderlayControl.bottomAnchor, constant: anchorRect.minY - 7 - screenHeight) : menuView.topAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: anchorRect.maxY + 7)
        NSLayoutConstraint.activate([verticalConstraint, horizontalConstraint])
        
        menuView.layer.cornerRadius = 30
        
        let highlightedItemImageView = UIImageView()
        highlightedItemImageView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(highlightedItemImageView)
        
        let constraints = [
            highlightedItemImageView.topAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: anchorRect.minY),
            highlightedItemImageView.leftAnchor.constraint(equalTo: menuUnderlayControl.leftAnchor, constant: anchorRect.minX),
            highlightedItemImageView.widthAnchor.constraint(equalToConstant: anchorRect.width),
            highlightedItemImageView.heightAnchor.constraint(equalToConstant: anchorRect.height),
        ]
        NSLayoutConstraint.activate(constraints)
        
        highlightedItemImageView.image = image
    }
    
    func showNoteMenu(note: MissionNote, anchorRect: CGRect, image: UIImage, onDeleted: @escaping (Bool, Bool) -> (), onMoved: @escaping (Bool, Bool) -> ()) {
        let mainVC = UIApplication.shared.mainViewController!
        showNoteMenu(note: note, from: mainVC, anchorRect: anchorRect, image: image, onDeleted: onDeleted, onMoved: onMoved)
    }
    
    func showNoteMenu(note: MissionNote, from vc: UIViewController, anchorRect: CGRect, image: UIImage, hMargin: CGFloat = 10, onDeleted: @escaping (Bool, Bool) -> (), onMoved: @escaping (Bool, Bool) -> ()) {
        let menuUnderlayControl = vc.addMenuUnderlayControl(color: .black.withAlphaComponent(0.25))
        let items = getNoteMenuItems(note: note, menuUnderlayControl: menuUnderlayControl, onDeleted: onDeleted, onMoved: onMoved)
        showMenu(items: items, menuUnderlayControl: menuUnderlayControl, anchorRect: anchorRect, image: image, hMargin: hMargin)
    }
    
    func getNoteMenuItems(note: MissionNote, menuUnderlayControl: UIView, onDeleted: @escaping (Bool, Bool) -> (), onMoved: @escaping (Bool, Bool) -> ()) -> [MenuItemData] {
        return [
            MenuItemData(text: "Изменить", image: .edit, type: .normal, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                let sb = UIStoryboard(name: "Missions", bundle: nil)
                let vc = sb.instantiateViewController(identifier: "CreateNoteVC") as! CreateNoteViewController
                vc.note = note
                self.presentFullScreen(vc)
            }),
            MenuItemData(text: "Переместить", image: .target, type: .normal, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                
                let sb = UIStoryboard(name: "Missions", bundle: nil)
                let vc = sb.instantiateViewController(identifier: "MoveNoteVC") as! MoveNoteViewController
                vc.showCalendar = true
                vc.note = note
                vc.onMoved = { mission, step, stepDeleted, missionDeleted in
                    onMoved(stepDeleted, missionDeleted)
                }
                self.presentFullScreen(vc)
            }),
            MenuItemData(text: "Удалить", image: .trash, type: .red, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                openDeleteNote(note, onDeleted: onDeleted)
            })
        ]
    }
    
    func openDeleteNote(_ note: MissionNote, onDeleted: @escaping (Bool, Bool) -> ()) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
        vc.popupTitle = "Удалить заметку?"
        vc.popupText = "Также из Vistalio будут удалены все её медиа и голосовые. Нельзя отменить."
        
        vc.buttons = [
            ActionButton(type: .red, title: "Удалить", action: { _ in
                var stepDeleted = false
                var missionDeleted = false
                CoreDataStack.shared.performAndWait { context in
                    if note.step?.hasFrequency == false && note.step?.notes?.count == 1 {
                        if let mission = note.step?.block.mission, mission.category == MissionCategory.notes.rawValue, mission.addedSteps.count == 1 {
                            context.delete(mission)
                            missionDeleted = true
                        } else {
                            context.delete(note.step!)
                        }
                        stepDeleted = true
                    } else {
                        context.delete(note)
                    }
                }
                onDeleted(stepDeleted, missionDeleted)
                (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Заметка удалена")
                if missionDeleted {
                    NotificationCenter.default.post(name: .missionUpdated, object: nil)
                }
                NotificationCenter.default.post(name: .noteUpdated, object: note)
            }),
            ActionButton(type: .secondary, title: "Отменить", action: { _ in })
        ]
        presentBottomSheet(vc, height: 200)
    }
    
    func openGallery(media: [MediaData], at index: Int) {
        let galleryView = GalleryView(frame: .zero)
        galleryView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(galleryView)
        
        let constraints = [
            galleryView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            galleryView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            galleryView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            galleryView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ]
        NSLayoutConstraint.activate(constraints)
        
        var media = media
        if index > 0 {
            let firstItems = media.prefix(upTo: index)
            media.removeFirst(index)
            media.append(contentsOf: firstItems)
        }
        galleryView.media = media
        
        view.gestureRecognizers?.first { $0 is UIPanGestureRecognizer }?.isEnabled = false
        galleryView.onDismiss = { [unowned self] in
            self.view.gestureRecognizers?.first { $0 is UIPanGestureRecognizer }?.isEnabled = true
        }
    }
    
    func openTemplate(_ template: MissionTemplate) {
        let sb = UIStoryboard(name: "Missions", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "TemplateVC") as! TemplateViewController
        vc.template = template
        presentFullScreen(vc)
    }
}
