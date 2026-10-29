//
//  Reminder.swift
//  Vistalio
//
//  Created by Julia Konkova on 11.09.2026.
//

import Foundation
import CoreData

@objc(RemindersGroup)
public class RemindersGroup: NSManagedObject {
    
}

extension RemindersGroup {
    
    @nonobjc public class func remindersGroupFetchRequest() -> NSFetchRequest<RemindersGroup> {
        return NSFetchRequest<RemindersGroup>(entityName: "RemindersGroup")
    }
    
    @NSManaged public var isEmotionReminder: Bool
    @NSManaged public var lastScheduledAt: Date?
    @NSManaged public var reminderDays: Int16
    @NSManaged public var lastReminderId: Int16
    @NSManaged public var notificationRequestId: String
    
    @NSManaged public var mission: Mission
    @NSManaged public var reminders: NSSet?
    
    @discardableResult
    class func create(context: NSManagedObjectContext, templateGroup: TemplateRemindersGroup, mission: Mission) -> RemindersGroup? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "RemindersGroup", in: context) else { return nil }
            
        let remindersGroup =  RemindersGroup(entity: entityDescription, insertInto: context)
        remindersGroup.notificationRequestId = UUID().uuidString
        remindersGroup.reminderDays = Int16(templateGroup.reminderDays)
        remindersGroup.isEmotionReminder = templateGroup.isEmotionReminder ?? false
        remindersGroup.mission = mission
        
        for r in templateGroup.reminders {
            Reminder.create(context: context, templateReminder: r, group: remindersGroup)
        }
        
        return remindersGroup
    }
    
    var remindersSorted: [Reminder]? {
        return reminders?.allObjects.map { $0 as! Reminder }.sorted {
            return $0.id < $1.id
        }
    }
}

@objc(Reminder)
public class Reminder: NSManagedObject {
    
}

extension Reminder {
    
    @nonobjc public class func reminderFetchRequest() -> NSFetchRequest<Reminder> {
        return NSFetchRequest<Reminder>(entityName: "Reminder")
    }
    
    @NSManaged public var id: Int16
    @NSManaged public var title: String?
    @NSManaged public var body: String?
    
    @NSManaged public var remindersGroup: RemindersGroup
    
    @discardableResult
    class func create(context: NSManagedObjectContext, templateReminder: TemplateReminder, group: RemindersGroup) -> Reminder? {
        
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Reminder", in: context) else { return nil }
        
        let reminder =  Reminder(entity: entityDescription, insertInto: context)
        reminder.id = Int16(templateReminder.id)
        reminder.title = templateReminder.title
        reminder.body = templateReminder.body
        reminder.remindersGroup = group
        
        return reminder
    }
}
