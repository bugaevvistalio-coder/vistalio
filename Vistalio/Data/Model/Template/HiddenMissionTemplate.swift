//
//  HiddenMissionTemplate.swift
//  Vistalio
//
//  Created by Julia Konkova on 22.04.2026.
//

import UIKit
import CoreData

@objc(HiddenMissionTemplate)
public class HiddenMissionTemplate: NSManagedObject {
    
    @discardableResult
    class func create(context: NSManagedObjectContext, templateId: Int) -> HiddenMissionTemplate? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "HiddenMissionTemplate", in: context) else { return nil }
        
        let template =  HiddenMissionTemplate(entity: entityDescription, insertInto: context)
        template.templateId = templateId
        template.date = Date()
        return template
    }
}

extension HiddenMissionTemplate {

    @nonobjc public class func hiddenMissionTemplateFetchRequest() -> NSFetchRequest<HiddenMissionTemplate> {
        return NSFetchRequest<HiddenMissionTemplate>(entityName: "HiddenMissionTemplate")
    }

    @NSManaged public var templateId: Int
    @NSManaged public var date: Date?
}
