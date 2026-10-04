//
//  Reminder.swift
//  Vistalio
//
//  Created by Julia Konkova on 11.09.2026.
//

import Foundation
import CoreData

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
    @NSManaged public var isEmotionReminder: Bool
    
    @NSManaged public var mission: Mission
    
    @discardableResult
    class func create(context: NSManagedObjectContext, templateReminder: TemplateReminder, mission: Mission, isEmotionReminder: Bool) -> Reminder? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Reminder", in: context) else { return nil }
        
        let reminder =  Reminder(entity: entityDescription, insertInto: context)
        reminder.id = Int16(templateReminder.id)
        reminder.title = templateReminder.title
        reminder.body = templateReminder.body
        reminder.isEmotionReminder = isEmotionReminder
        reminder.mission = mission
        
        return reminder
    }
}
