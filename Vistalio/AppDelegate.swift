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
    
    func addNotification(text: String, secondaryText: String? = nil, onTapped: (() -> ())? = nil) {
        (UIApplication.shared.keyWindow?.rootViewController as? MainViewController)?.addNotification(text: text, secondaryText: secondaryText, onTapped: onTapped)
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
//            openTemplate(id: templateId)
        }
        
        
    }
}

