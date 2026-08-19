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
        
        emotions.forEach {
            MissionNoteEmotion.create(context: context, note: note, e: $0)
        }
        
        media.reversed().forEach {
            MissionNoteImage.create(context: context, note: note, media: $0)
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
    
    var saveImageOnDelete = false
    
    @discardableResult
    class func create(context: NSManagedObjectContext, note: MissionNote, media: MediaData) -> MissionNoteImage? {
        if let imageEntity = NSEntityDescription.entity(forEntityName: "MissionNoteImage", in: context) {
            let image = MissionNoteImage(entity: imageEntity, insertInto: context)
            image.date = Date()
            image.path = media.path ?? media.image?.saveToDocuments(directory: note.step!.block.mission.name)
            image.note = note
            print("Media saved \(image.path ?? "")")
            return image
        }
        return nil
    }
}

extension MissionNoteImage {

    @nonobjc public class func noteImageFetchRequest() -> NSFetchRequest<MissionNoteImage> {
        return NSFetchRequest<MissionNoteImage>(entityName: "MissionNoteImage")
    }

    @NSManaged public var date: Date
    @NSManaged public var path: String?
    @NSManaged public var note: MissionNote
    
    public override func prepareForDeletion() {
        if saveImageOnDelete {
            return
        }
        if let path = path, !path.starts(with: "http") {
            FilesHelper().deleteFile(path: path)
            print("Media removed \(path)")
        }
    }
    
    var mediaData: MediaData {
        let path = path ?? ""
        let type = (path.lowercased().hasSuffix(".mp4") || path.lowercased().hasSuffix(".mov")) ? "video" : "image"
        let m = MediaData(type: type, image: nil, path: path)
        if type == "video" {
            DispatchQueue.global().async { 
                let url = FilesHelper().buildFileUrl(path: path)
                m.image = createVideoSnapshot(from: url)
            }
        }
        return m
    }
}

@objc(MissionNoteEmotion)
public class MissionNoteEmotion: NSManagedObject {
    
    @discardableResult
    class func create(context: NSManagedObjectContext, note: MissionNote, e: MissionEmotion) -> MissionNoteEmotion? {
        if let emotionEntity = NSEntityDescription.entity(forEntityName: "MissionNoteEmotion", in: context) {
            let emotion = MissionNoteEmotion(entity: emotionEntity, insertInto: context)
            emotion.date = Date()
            emotion.emotion = e.rawValue
            emotion.note = note
            return emotion
        }
        return nil
    }
}

extension MissionNoteEmotion {

    @nonobjc public class func noteImageFetchRequest() -> NSFetchRequest<MissionNoteEmotion> {
        return NSFetchRequest<MissionNoteEmotion>(entityName: "MissionNoteEmotion")
    }

    @NSManaged public var date: Date
    @NSManaged public var emotion: String
    @NSManaged public var note: MissionNote
}
