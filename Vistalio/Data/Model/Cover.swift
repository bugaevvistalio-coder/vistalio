//
//  Cover.swift
//  Vistalio
//
//  Created by Julia Konkova on 19.04.2026.
//

import Foundation
import CoreData

@objc(Cover)
public class Cover: NSManagedObject {
    
    @discardableResult
    class func create(context: NSManagedObjectContext, path: String) -> Cover? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Cover", in: context) else { return nil }
        
        let cover =  Cover(entity: entityDescription, insertInto: context)
        cover.photoPath = path
        cover.creationDate = Date()
        return cover
    }
    
    public override func prepareForDeletion() {
        if let photoPath = photoPath {
            FilesHelper().deleteFile(path: photoPath)
            print("Cover file deleted")
        }
    }
}

extension Cover {

    @nonobjc public class func coverFetchRequest() -> NSFetchRequest<Cover> {
        return NSFetchRequest<Cover>(entityName: "Cover")
    }

    @NSManaged public var photoPath: String?
    @NSManaged public var creationDate: Date?
}
