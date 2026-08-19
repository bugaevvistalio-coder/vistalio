//
//  Mission+CoreDataProperties.swift
//  
//
//  Created by Julia Konkova on 03.04.2026.
//
//

import Foundation
import CoreData

enum MissionCategory: String, CaseIterable {
    case bigEyes
    case heart
    case money
    case sport
    case science
    case health
    case clothes
    case family
    case house
    case travel
    case speak
    case location
    case notes
    
    var coverName: String {
        switch self {
        case .bigEyes:
            return "cover1"
        case .heart:
            return "cover2"
        case .money:
            return "cover3"
        case .sport:
            return "cover4"
        case .science:
            return "cover5"
        case .health:
            return "cover6"
        case .clothes:
            return "cover7"
        case .family:
            return "cover8"
        case .house:
            return "cover9"
        case .travel:
            return "cover10"
        case .speak:
            return "cover11"
        case .location:
            return "cover12"
        case .notes:
            return "coverNotes"
        }
    }
}

@objc(Mission)
public class Mission: NSManagedObject {
    
    var selectedSteps: [MissionStep]?
    
    @discardableResult
    class func create(context: NSManagedObjectContext, name: String?, coverPath: String?, about: String? = nil, category: String? = nil) -> Mission? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Mission", in: context) else { return nil }
        
        let mission =  Mission(entity: entityDescription, insertInto: context)
        mission.name = name
        mission.photoPath = coverPath
        mission.about = about
        mission.category = category
        mission.creationDate = Date()
        mission.updateDate = mission.creationDate
        
        return mission
    }
    
    @discardableResult
    class func create(context: NSManagedObjectContext, template: MissionTemplate, blocks: [TemplateBlock]) -> Mission? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Mission", in: context) else { return nil }
        
        let mission =  Mission(entity: entityDescription, insertInto: context)
        mission.name = template.name
        mission.photoPath = template.cover
        mission.about = template.fullDescription
        mission.creationDate = Date()
        mission.updateDate = mission.creationDate
        mission.templateId = template.id
        
        var stepIndex = 0
        var noteIndex = 0
        
        for (i, b) in blocks.enumerated() {
            if let blockEntity = NSEntityDescription.entity(forEntityName: "StepsBlock", in: context) {
                let block = StepsBlock(entity: blockEntity, insertInto: context)
                block.id = i+1
                block.mission = mission
                
                for s in b.steps {
                    if let stepEntity = NSEntityDescription.entity(forEntityName: "MissionStep", in: context) {
                        stepIndex += 1
                        
                        let step = MissionStep(entity: stepEntity, insertInto: context)
                        step.id = stepIndex
                        step.name = s.name
                        step.text = s.description
                        step.block = block
                        
                        if let notes = s.notes {
                            for n in notes {
                                if let noteEntity = NSEntityDescription.entity(forEntityName: "MissionNote", in: context) {
                                    noteIndex += 1
                                    
                                    let note = MissionNote(entity: noteEntity, insertInto: context)
                                    note.date = Date()
                                    note.name = n.name
                                    note.text = n.description
                                    note.audio = n.audio
                                    note.step = step
                                    
                                    if let images = n.images {
                                        for ni in images {
                                            if let imageEntity = NSEntityDescription.entity(forEntityName: "MissionNoteImage", in: context) {
                                                let image = MissionNoteImage(entity: imageEntity, insertInto: context)
                                                image.date = Date()
                                                image.path = ni
                                                image.note = note
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return mission
    }
    
    public override func prepareForDeletion() {
        if let photoPath = photoPath {
            FilesHelper().deleteFile(path: photoPath)
            print("Mission cover file deleted")
        }
    }
    
    var addedSteps: [MissionStep] {
        let blocks = blocks?.allObjects.map { $0 as! StepsBlock } ?? []
        let steps = blocks.flatMap { ($0.steps?.allObjects as? [MissionStep]) ?? [] }
        return steps.filter { $0.addedDate != nil }
    }
    
    var maxSortOrder: Int32 {
        return (addedSteps.max(by: { $0.sortOrder < $1.sortOrder })?.sortOrder ?? 0)
    }
    
    @discardableResult func getNotesStep() -> MissionStep? {
        var step = addedSteps.first { $0.id == -1 }
        if step == nil {
            CoreDataStack.shared.performAndWait { context in
                step = MissionStep.create(context: context, mission: self, name: "Шаг для общих заметок", text: "Заметки, не привязанные к конкретному шагу(-ам).", frequency: .once, startDate: Date(), endDate: nil)
                step?.id = -1
                step?.sortOrder = -1
            }
        }
        return step
    }
}

extension Mission {

    @nonobjc public class func missionFetchRequest() -> NSFetchRequest<Mission> {
        return NSFetchRequest<Mission>(entityName: "Mission")
    }

    @NSManaged public var name: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var updateDate: Date?
    @NSManaged public var photoPath: String?
    @NSManaged public var about: String?
    @NSManaged public var category: String?
    @NSManaged public var templateId: Int
    @NSManaged public var archived: Bool
    @NSManaged public var finishedAt: Date?
    
    @NSManaged public var blocks: NSSet?
}

extension Mission {

    @objc(addBlocksObject:)
    @NSManaged public func addToBlocks(_ value: StepsBlock)

    @objc(removeBlocksObject:)
    @NSManaged public func removeFromBlocks(_ value: StepsBlock)

    @objc(addBlocks:)
    @NSManaged public func addToBlocks(_ values: NSSet)

    @objc(removeBlocks:)
    @NSManaged public func removeFromBlocks(_ values: NSSet)
}
