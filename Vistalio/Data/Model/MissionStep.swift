//
//  MissionStep.swift
//  Vistalio
//
//  Created by Julia Konkova on 27.04.2026.
//

import Foundation
import CoreData

@objc(MissionStep)
public class MissionStep: NSManagedObject {
    
    var expanded = false
    
}

extension MissionStep {

    @nonobjc public class func stepFetchRequest() -> NSFetchRequest<MissionStep> {
        return NSFetchRequest<MissionStep>(entityName: "MissionStep")
    }

    @NSManaged public var id: Int
    @NSManaged public var name: String?
    @NSManaged public var text: String?
    @NSManaged public var hidden: Bool
    @NSManaged public var addedDate: Date?
    
    @NSManaged public var mission: Mission
    @NSManaged public var notes: NSSet?
    
    var shortText: String? {
        return text?.replacingOccurrences(of: "\n\n", with: " ").replacingOccurrences(of: "\n", with: " ")
    }
}

extension MissionStep {

    @objc(addNotesObject:)
    @NSManaged public func addToNotes(_ value: MissionNote)

    @objc(removeNotesObject:)
    @NSManaged public func removeFromNotes(_ value: MissionNote)

    @objc(addNotes:)
    @NSManaged public func addToNotes(_ values: NSSet)

    @objc(removeNotes:)
    @NSManaged public func removeFromNotes(_ values: NSSet)

}
