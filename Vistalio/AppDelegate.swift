//
//  AppDelegate.swift
//  Vistalio
//
//  Created by Julia Konkova on 20.03.2026.
//

import UIKit
import IQKeyboardManagerSwift
import AppsFlyerLib

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.enableAutoToolbar = true
//        IQKeyboardManager.shared.toolbarConfiguration.previousNextDisplayMode = .alwaysHide
        IQKeyboardManager.shared.resignOnTouchOutside = true
        
        AppsFlyerLib.shared().appsFlyerDevKey = "Msm9X2Sp9ZbqfkdPym4eAF"
        AppsFlyerLib.shared().appleAppID = "1632381333"
        AppsFlyerLib.shared().deepLinkDelegate = self
        #if DEBUG
            AppsFlyerLib.shared().isDebug = true
        #endif
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            AppsFlyerLib.shared().appInviteOneLinkID = "eU8s"
            AppsFlyerLib.shared().start()
        }
        
        setupNotifications()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func addNotification(text: String, secondaryText: String? = nil, mission: Mission? = nil, onTapped: (() -> ())? = nil) {
        (UIApplication.shared.keyWindow?.rootViewController as? MainViewController)?.addNotification(text: text, secondaryText: secondaryText, mission: mission, onTapped: onTapped)
    }
    
    func openTemplate(id: Int) {
        if let template = MissionsHolder.shared.templates.filter({ $0.id == id }).first {
            let sb = UIStoryboard(name: "Missions", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "TemplateVC") as! TemplateViewController
            vc.template = template
            if let mainVC = UIApplication.shared.mainViewController {
                mainVC.dismiss(animated: false)
                mainVC.presentFullScreen(vc)
            }
        } else {
            MissionsHolder.shared.openTemplateId = id
        }
    }
}

extension AppDelegate: DeepLinkDelegate {
    func didResolveDeepLink(_ result: DeepLinkResult) {
        switch result.status {
        case .notFound:
            print("[AFSDK] Deep link not found")
            return
        case .failure:
            print("Error %@", result.error!)
            return
        case .found:
            print("[AFSDK] Deep link found")
        }
        
        guard let deepLink = result.deepLink else {
            print("[AFSDK] Could not extract deep link object")
            return
        }
        
        if deepLink.deeplinkValue == "recommended" && deepLink.clickEvent.keys.contains("deep_link_sub1"), let param = deepLink.clickEvent["deep_link_sub1"] as? String, let templateId = Int(param) {
            openTemplate(id: templateId)
        }
        
        
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func setupNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound];
        
        notificationCenter.requestAuthorization(options: options) {
            (granted, error) in
            if granted {
                print("Notifications are granted")
            } else {
                print("Notifications are not granted")
            }
        }
        notificationCenter.delegate = self
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let isReminder = response.notification.request.content.userInfo["isReminder"] as? Bool ?? false
        
        if let mainVC = UIApplication.shared.mainViewController {
            mainVC.dismiss(animated: false)
            mainVC.switchTab(tabIndex: 1, toRoot: true)
            
            if isReminder {
                if let mission = MissionsHolder.shared.getNotificationMission(notificationId: response.notification.request.identifier) {
                    (mainVC.controllers[1] as! UINavigationController).topViewController?.openMission(mission)
                }
            } else if let block = MissionsHolder.shared.getNotificationBlock(notificationId: response.notification.request.identifier) {
                (mainVC.controllers[1] as! UINavigationController).topViewController?.openMission(block.mission, recommendedExpanded: true)
            }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let isReminder = notification.request.content.userInfo["isReminder"] as? Bool ?? false
        if isReminder {
            if let mission = MissionsHolder.shared.getNotificationMission(notificationId: notification.request.identifier) {
                print("Scheduled when notification presented")
                if mission.reminderNotificationRequestId == notification.request.identifier {
                    if let lastReminderAt = mission.lastReminderAt {
                        MissionsHolder.shared.scheduleReminderNotificationOnStepImplemented(mission: mission, date: lastReminderAt)
                        MissionsHolder.shared.removeEmotionNotification(mission: mission)
                    }
                } else if mission.emotionReminderNotificationRequestId == notification.request.identifier {
                    MissionsHolder.shared.rescheduleEmotionNotifications(mission: mission)
                }
            }
        } else if notification.request.trigger != nil {
            MissionsHolder.shared.getNotificationBlock(notificationId: notification.request.identifier)?.unlockNextBlock()
        }
        completionHandler([.banner, .list, .sound])
    }
}

