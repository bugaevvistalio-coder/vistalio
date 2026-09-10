//
//  NotificationsPresenter.swift
//  Vistalio
//
//  Created by Julia Konkova on 07.09.2026.
//

import Foundation
import UserNotifications

func addNotification(title: String, body: String, notificationId: String, userInfo: [AnyHashable: Any]? = nil, trigger: UNNotificationTrigger? = nil) {
    let content = UNMutableNotificationContent()
    content.sound = UNNotificationSound.default
    content.title = title
    content.body = body
    if let userInfo = userInfo {
        content.userInfo = userInfo
    }
    
    let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("ERROR!!! Notification \(error.localizedDescription)")
        } else {
            print("Notification scheduled =\(title)= =\(body)= =\(notificationId)= \(userInfo?["fireDate"] ?? "now")")
        }
    }
}

func removeScheduledNotifications(_ ids: [String]) {
    if !ids.isEmpty {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        print("Notifications removed: \(ids)")
    }
}
