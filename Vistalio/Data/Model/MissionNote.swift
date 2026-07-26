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

    @NSManaged public var name: String?
    @NSManaged public var text: String?
    @NSManaged public var audio: String?
    @NSManaged public var date: Date?
    
    @NSManaged public var step: MissionStep?
    
    @NSManaged public var images: NSSet?
    @NSManaged public var emotions: NSSet?
    
    @discardableResult
    class func create(context: NSManagedObjectContext, step: MissionStep, date: Date, name: String?, text: String?, emotions: [MissionEmotion], media: [MediaData]) -> MissionNote? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "MissionNote", in: context) else { return nil }
        
        let note = MissionNote(entity: entityDescription, insertInto: context)
        note.date = date
        note.name = name
        note.text = text
        note.step = step
        
        for e in emotions {
            if let emotionEntity = NSEntityDescription.entity(forEntityName: "MissionNoteEmotion", in: context) {
                let emotion = MissionNoteEmotion(entity: emotionEntity, insertInto: context)
                emotion.date = Date()
                emotion.emotion = e.rawValue
                emotion.note = note
            }
        }
        
        for m in media {
            if let imageEntity = NSEntityDescription.entity(forEntityName: "MissionNoteImage", in: context) {
                let image = MissionNoteImage(entity: imageEntity, insertInto: context)
                image.date = Date()
                image.path = m.path ?? m.image?.saveToDocuments(directory: step.block.mission.name)
                image.note = note
            }
        }
        
        return note
    }
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

    @objc(addEmotionsObject:)
    @NSManaged public func addToEmotions(_ value: MissionNoteEmotion)

    @objc(removeEmotionsObject:)
    @NSManaged public func removeFromEmotions(_ value: MissionNoteEmotion)

    @objc(addEmotions:)
    @NSManaged public func addToEmotions(_ values: NSSet)

    @objc(removeEmotions:)
    @NSManaged public func removeFromEmotions(_ values: NSSet)
}

@objc(MissionNoteImage)
public class MissionNoteImage: NSManagedObject {
}

extension MissionNoteImage {

    @nonobjc public class func noteImageFetchRequest() -> NSFetchRequest<MissionNoteImage> {
        return NSFetchRequest<MissionNoteImage>(entityName: "MissionNoteImage")
    }

    @NSManaged public var date: Date
    @NSManaged public var path: String?
    @NSManaged public var note: MissionNote
}

@objc(MissionNoteEmotion)
public class MissionNoteEmotion: NSManagedObject {
}

extension MissionNoteEmotion {

    @nonobjc public class func noteImageFetchRequest() -> NSFetchRequest<MissionNoteEmotion> {
        return NSFetchRequest<MissionNoteEmotion>(entityName: "MissionNoteEmotion")
    }

    @NSManaged public var date: Date
    @NSManaged public var emotion: String
    @NSManaged public var note: MissionNote
}
