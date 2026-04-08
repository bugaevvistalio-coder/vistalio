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
}
