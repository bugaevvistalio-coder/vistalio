//
//  MissionStep.swift
//  Vistalio
//
//  Created by Julia Konkova on 27.04.2026.
//

import Foundation
import CoreData

enum StepFrequency: Int16, CaseIterable {
    case untilDone = 0
    case once = 1
    case everyDay = 2
    case everyOtherDay = 3
    case everyWeek = 4
    case everyTwoWeeks = 5
    case everyMonth = 6
    case everyYear = 7
    
    var displayName: String {
        switch self {
        case .untilDone:
            return "Пока не выполнен"
        case .once:
            return "Один раз"
        case .everyDay:
            return "Каждый день"
        case .everyOtherDay:
            return "Через день"
        case .everyWeek:
            return "Каждую неделю"
        case .everyTwoWeeks:
            return "Каждые 2 недели"
        case .everyMonth:
            return "Каждый месяц"
        case .everyYear:
            return "Каждый год"
        }
    }
}

@objc(StepsBlock)
public class StepsBlock: NSManagedObject {
    
}

extension StepsBlock {
    
    @nonobjc public class func blockFetchRequest() -> NSFetchRequest<StepsBlock> {
        return NSFetchRequest<StepsBlock>(entityName: "StepsBlock")
    }
    
    @NSManaged public var id: Int
    @NSManaged public var mission: Mission
    @NSManaged public var steps: NSSet?
    
    @discardableResult
    class func create(context: NSManagedObjectContext, mission: Mission) -> StepsBlock? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "StepsBlock", in: context) else { return nil }
        
        let block =  StepsBlock(entity: entityDescription, insertInto: context)
        block.id = -1
        block.mission = mission
        
        return block
    }
}

extension StepsBlock {
    
    @objc(addStepsObject:)
    @NSManaged public func addToSteps(_ value: MissionStep)

    @objc(removeStepsObject:)
    @NSManaged public func removeFromSteps(_ value: MissionStep)

    @objc(addSteps:)
    @NSManaged public func addToSteps(_ values: NSSet)

    @objc(removeSteps:)
    @NSManaged public func removeFromSteps(_ values: NSSet)
    
}

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
    @NSManaged public var sortOrder: Int32
    
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var frequency: Int16
    
    @NSManaged public var block: StepsBlock
    @NSManaged public var notes: NSSet?
    
    @NSManaged public var originalName: String?
    @NSManaged public var originalText: String?
    
    var shortText: String? {
        return text?.replacingOccurrences(of: "\n\n", with: " ").replacingOccurrences(of: "\n", with: " ")
    }
    
    @discardableResult
    class func create(context: NSManagedObjectContext, mission: Mission, name: String, text: String?, frequency: StepFrequency, startDate: Date, endDate: Date?) -> MissionStep? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "MissionStep", in: context) else { return nil }
        
        let blocks = mission.blocks?.allObjects.map { $0 as! StepsBlock } ?? []
        guard let block = blocks.first(where: { $0.id == -1 }) ?? StepsBlock.create(context: context, mission: mission) else {
            return nil
        }
        
        let step =  MissionStep(entity: entityDescription, insertInto: context)
        step.block = block
        step.addedDate = Date()
        step.name = name
        step.text = text
        step.frequency = frequency.rawValue
        step.startDate = startDate
        step.endDate = endDate
        return step
    }
    
    var isOriginal: Bool {
        if originalName == nil {
            return true
        }
        return originalName == name && originalText == text && frequency == 0
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
