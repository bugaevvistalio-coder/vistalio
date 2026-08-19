//
//  UIApplication+Utils.swift
//  Vistalio
//
//  Created by Julia Konkova on 07.04.2026.
//

import UIKit

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        
        if let tabVC = controller as? UITabBarController {
            return topViewController(controller: tabVC.selectedViewController)
        }
        
        if let navigationController = controller as? UINavigationController {
            let dismissed = navigationController.visibleViewController?.isBeingDismissed
            if dismissed == true {
                return navigationController
            }
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        if let child = controller?.children.first {
            return topViewController(controller: child)
        }
        return controller
    }
    
    var mainViewController: MainViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let mainVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController as? MainViewController else {
            return nil
        }
        return mainVC
    }
}
