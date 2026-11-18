//
//  MissionNote.swift
//  Vistalio
//
//  Created by Julia Konkova on 27.04.2026.
//

import Foundation
import CoreData

enum AudioSource: String, Codable {
    case bundle
    case documents
}

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
    @NSManaged public var audioSource: String?
    @NSManaged public var date: Date?
    @NSManaged public var byUser: Bool
    
    @NSManaged public var step: MissionStep?
    
    @NSManaged public var images: NSSet?
    @NSManaged public var emotions: NSSet?
    @NSManaged public var location: GeoTag?
    
    @discardableResult
    class func create(context: NSManagedObjectContext, step: MissionStep, date: Date, name: String?, text: String?, emotions: [MissionEmotion], media: [MediaData]) -> MissionNote? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "MissionNote", in: context) else { return nil }
        
        let note = MissionNote(entity: entityDescription, insertInto: context)
        note.date = date
        note.name = name
        note.text = text
        note.step = step
        note.byUser = true
        
        emotions.forEach {
            MissionNoteEmotion.create(context: context, note: note, e: $0)
        }
        
        media.reversed().forEach {
            MissionNoteImage.create(context: context, note: note, media: $0)
        }
        
        return note
    }
    
    var audioURL: URL? {
        guard let audio = audio, let source = audioSource else {
            return nil
        }
        var url: URL? = nil
        if source == AudioSource.bundle.rawValue {
            let tempUrl = URL(fileURLWithPath: audio)
            let name = tempUrl.deletingPathExtension().lastPathComponent
            let ext = tempUrl.pathExtension
            url = Bundle.main.url(forResource: name, withExtension: ext)
        } else if source == AudioSource.documents.rawValue {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            url = documentsDirectory.appendingPathComponent(audio)
        }
        return url
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
        let type = self.type
        let m = MediaData(type: type, image: nil, path: path)
        if type == "video" {
            DispatchQueue.global().async {
                let url = FilesHelper().buildFileUrl(path: path)
                m.image = createVideoSnapshot(from: url)
                DispatchQueue.main.async {
                    m.onImageCreated?()
                }
            }
        }
        return m
    }
    
    var type: String {
        let path = path ?? ""
        return (path.lowercased().hasSuffix(".mp4") || path.lowercased().hasSuffix(".mov")) ? "video" : "image"
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

    @nonobjc public class func noteEmotionFetchRequest() -> NSFetchRequest<MissionNoteEmotion> {
        return NSFetchRequest<MissionNoteEmotion>(entityName: "MissionNoteEmotion")
    }

    @NSManaged public var date: Date
    @NSManaged public var emotion: String
    @NSManaged public var note: MissionNote
}

@objc(GeoTag)
public class GeoTag: NSManagedObject {
    
    @discardableResult
    class func create(context: NSManagedObjectContext, latitude: Double, longitude: Double, address: String?, note: MissionNote) -> GeoTag? {
        if let geoTagEntity = NSEntityDescription.entity(forEntityName: "GeoTag", in: context) {
            let geoTag = GeoTag(entity: geoTagEntity, insertInto: context)
            geoTag.date = Date()
            geoTag.latitude = latitude
            geoTag.longitude = longitude
            geoTag.address = address
            geoTag.note = note
            return geoTag
        }
        return nil
    }
    
    class func fetchLatestRecord(context: NSManagedObjectContext) -> GeoTag? {
        let request = GeoTag.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Ошибка получения записи: \(error)")
            return nil
        }
    }
}

extension GeoTag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GeoTag> {
        return NSFetchRequest<GeoTag>(entityName: "GeoTag")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var date: Date?
    @NSManaged public var address: String?
    @NSManaged public var note: MissionNote?

}
