//
//  MissionNote.swift
//  Vistalio
//
//  Created by Julia Konkova on 27.04.2026.
//

import Foundation
import CoreData

@objc(MissionNote)
public class MissionNote: NSManagedObject {
    
}

extension MissionNote {

    @nonobjc public class func noteFetchRequest() -> NSFetchRequest<MissionNote> {
        return NSFetchRequest<MissionNote>(entityName: "MissionNote")
    }

    @NSManaged public var id: Int
    @NSManaged public var name: String?
    @NSManaged public var text: String?
    @NSManaged public var audio: String?
    @NSManaged public var date: String?
    
    @NSManaged public var step: MissionStep
    @NSManaged public var images: NSSet?
}

extension MissionNote {

    @objc(addImagesObject:)
    @NSManaged public func addToImages(_ value: MissionNoteImage)

    @objc(removeImagesObject:)
    @NSManaged public func removeFromImages(_ value: MissionNoteImage)

    @objc(addImages:)
    @NSManaged public func addToImages(_ values: NSSet)

    @objc(removeImages:)
    @NSManaged public func removeFromImages(_ values: NSSet)

}

@objc(MissionNoteImage)
public class MissionNoteImage: NSManagedObject {
    
}

extension MissionNoteImage {

    @nonobjc public class func noteImageFetchRequest() -> NSFetchRequest<MissionNoteImage> {
        return NSFetchRequest<MissionNoteImage>(entityName: "MissionNoteImage")
    }

    @NSManaged public var id: Int
    @NSManaged public var path: String?
    @NSManaged public var note: MissionNote
}
