//
//  NotificationsPresenter.swift
//  Vistalio
//
//  Created by Julia Konkova on 07.09.2026.
//

import Foundation
import UserNotifications

func addNotification(title: String, body: String, notificationId: String, userInfo: [AnyHashable: Any]? = nil, triggerDate: Date? = nil) {
    let content = UNMutableNotificationContent()
    content.sound = UNNotificationSound.default
    content.title = title
    content.body = body
    if let userInfo = userInfo {
        content.userInfo = userInfo
    }
    
    var trigger: UNNotificationTrigger?
    if let date = triggerDate {
        let components = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second], from: date)
        trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }
    
    let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("ERROR!!! Notification \(error.localizedDescription)")
        } else {
            print("\(Date()) Notification scheduled =\(title)= =\(body)= =\(notificationId)= \(triggerDate)")
        }
    }
}

func addDailyNotification(title: String, body: String, hour: Int, minute: Int, notificationId: String, userInfo: [AnyHashable: Any]? = nil) {
    let content = UNMutableNotificationContent()
    content.sound = UNNotificationSound.default
    content.title = title
    content.body = body
    if let userInfo = userInfo {
        content.userInfo = userInfo
    }
    
    var dateComponents = DateComponents()
    dateComponents.hour = hour
    dateComponents.minute = minute
    
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("ERROR!!! Notification \(error.localizedDescription)")
        } else {
            print("\(Date()) Daily notification scheduled =\(title)= =\(body)= =\(notificationId)= \(hour) \(minute)")
        }
    }
}

func removeScheduledNotifications(_ ids: [String]) {
    if !ids.isEmpty {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        print("Scheduled notifications removed: \(ids)")
    }
}
