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
    class func create(context: NSManagedObjectContext, name: String?, coverPath: String?, about: String? = nil, category: String? = nil, templateId: Int? = nil) -> Mission? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Mission", in: context) else { return nil }
        
        let mission =  Mission(entity: entityDescription, insertInto: context)
        mission.name = name
        mission.photoPath = coverPath
        mission.about = about
        mission.category = category
        mission.creationDate = Date()
        mission.updateDate = mission.creationDate
        mission.templateId = templateId ?? 0
        
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
}
