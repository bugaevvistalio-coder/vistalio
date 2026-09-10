//
//  AppNotification.swift
//  Vistalio
//
//  Created by Julia Konkova on 09.09.2026.
//

import Foundation
import CoreData

enum AppNotificationType: String {
case newSteps
}

@objc(AppNotification)
public class AppNotification: NSManagedObject {
    
    @discardableResult
    class func create(context: NSManagedObjectContext, title: String, text: String, isRead: Bool, mission: Mission?, type: AppNotificationType) -> AppNotification? {
        
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "AppNotification", in: context) else { return nil }
        
        let n =  AppNotification(entity: entityDescription, insertInto: context)
        n.title = title
        n.text = text
        n.isRead = isRead
        n.date = Date()
        n.notificationType = type.rawValue
        n.mission = mission
        return n
    }
}

extension AppNotification {

    @nonobjc public class func appNotificationFetchRequest() -> NSFetchRequest<AppNotification> {
        return NSFetchRequest<AppNotification>(entityName: "AppNotification")
    }

    @NSManaged public var date: Date?
    @NSManaged public var title: String?
    @NSManaged public var text: String?
    @NSManaged public var isRead: Bool
    @NSManaged public var notificationType: String
    
    @NSManaged public var mission: Mission?
}
