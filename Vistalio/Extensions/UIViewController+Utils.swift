//
//  UIViewController+Utils.swift
//  Vistalio
//
//  Created by Julia Konkova on 29.03.2026.
//

import UIKit
import FittedSheets

extension UIViewController {
    
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
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = (self as? UIImagePickerControllerDelegate & UINavigationControllerDelegate)
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = true
            
            let width = UIScreen.main.bounds.width
            let overlayView = UIView(frame: imagePicker.view.frame)
            let circlePath = UIBezierPath(ovalIn: CGRect(x: 0, y: (imagePicker.view.frame.height - width)/2, width: width, height: width))
            imagePicker.cameraOverlayView = overlayView
            
            present(imagePicker, animated: true, completion: nil)
        } else {
            print("Camera not available on this device/simulator.")
        }
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
    
    func openShareMission(_ mission: Mission) {
        
    }
    
    func openArchiveMission(_ mission: Mission) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
        vc.popupTitle = mission.archived ? "Убрать миссию из архива?" : "Убрать миссию в архив?"
        vc.popupText = mission.archived ? "Снова начнём напоминать о её шагах и предлагать новые. Можно отменить в любой момент." : "Мы перестанем напоминать о её шагах и предлагать новые. Можно отменить в любой момент."
        vc.buttons = [
            ActionButton(type: mission.archived ? .blue : .red, title: mission.archived ? "Убрать из архива" : "Убрать в архив", action: { CoreDataStack.shared.performAndWait { context in
                    mission.archived = !mission.archived
                }
                NotificationCenter.default.post(name: .missionUpdated, object: nil)
                (UIApplication.shared.delegate as! AppDelegate).addNotification(text: mission.archived ? "Миссия перемещена в архив" : "Миссия убрана из архива")
            }),
            ActionButton(type: .secondary, title: "Отменить", action: { })
        ]
        presentBottomSheet(vc, height: 200)
    }
    
    func openDeleteMission(_ mission: Mission) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
        vc.popupTitle = "Удалить миссию?"
        vc.popupText = "Нельзя отменить. По умолчанию все заметки удаляемой миссии помещаются в миссию «Общие заметки»."
        vc.buttons = [
            ActionButton(type: .red, title: "Удалить", action: { [unowned self] in
                CoreDataStack.shared.performAndWait { context in
                    context.delete(mission)
                }
                NotificationCenter.default.post(name: .missionUpdated, object: nil)
                self.navigationController?.popViewController(animated: true)
                (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Миссия удалена")
            }),
            ActionButton(type: .secondary, title: "Отменить", action: { })
        ]
        presentBottomSheet(vc, height: 200)
    }
}
