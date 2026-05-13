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
        }
    }
}

@objc(Mission)
public class Mission: NSManagedObject {
    
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
    class func create(context: NSManagedObjectContext, template: MissionTemplate, steps: [[TemplateStep]]) -> Mission? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Mission", in: context) else { return nil }
        
        let mission =  Mission(entity: entityDescription, insertInto: context)
        mission.name = template.name
        mission.photoPath = template.cover
        mission.about = template.fullDescription
        mission.creationDate = Date()
        mission.updateDate = mission.creationDate
        mission.templateId = template.id
        
        for (i, s) in steps.flatMap({ $0 }).enumerated() {
            if let stepEntity = NSEntityDescription.entity(forEntityName: "MissionStep", in: context) {
                let step = MissionStep(entity: stepEntity, insertInto: context)
                step.id = i+1
                step.name = s.name
                step.text = s.description
                step.mission = mission
                
                if let notes = s.notes {
                    for (i, n) in notes.enumerated() {
                        if let noteEntity = NSEntityDescription.entity(forEntityName: "MissionNote", in: context) {
                            let note = MissionNote(entity: noteEntity, insertInto: context)
                            note.id = i+1
                            note.name = n.name
                            note.text = n.description
                            note.audio = n.audio
                            note.step = step
                            
                            if let images = n.images {
                                for (i, ni) in images.enumerated() {
                                    if let imageEntity = NSEntityDescription.entity(forEntityName: "MissionNoteImage", in: context) {
                                        let image = MissionNoteImage(entity: imageEntity, insertInto: context)
                                        image.id = i+1
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
        
        return mission
    }
    
    public override func prepareForDeletion() {
        if let photoPath = photoPath {
            FilesHelper().deleteFile(path: photoPath)
            print("Mission cover file deleted")
        }
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
    
    @NSManaged public var steps: NSSet?
}

extension Mission {

    @objc(addStepsObject:)
    @NSManaged public func addToSteps(_ value: MissionStep)

    @objc(removeStepsObject:)
    @NSManaged public func removeFromSteps(_ value: MissionStep)

    @objc(addSteps:)
    @NSManaged public func addToSteps(_ values: NSSet)

    @objc(removeSteps:)
    @NSManaged public func removeFromSteps(_ values: NSSet)

}
