//
//  CoreDataHelper.swift
//  Vistalio
//
//  Created by Julia Konkova on 06.06.2022.
//

import Foundation
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    private init() {}
    
    private let lockQueue = DispatchQueue(label: "com.ab.vistalio.coreDataQueue")
    
    private var innerBackgroundContext: NSManagedObjectContext!
    
    var persistentContainer: NSPersistentContainer!
    
    func setup() {
        persistentContainer = NSPersistentContainer(name: "Vistalio")
        
        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        })
        persistentContainer.viewContext.mergePolicy = NSOverwriteMergePolicy
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        
        innerBackgroundContext = persistentContainer.newBackgroundContext()
        innerBackgroundContext.mergePolicy = NSOverwriteMergePolicy
        innerBackgroundContext.automaticallyMergesChangesFromParent = true
        
    }
    
    var mainContext: NSManagedObjectContext {
        get {
            if persistentContainer == nil {
                setup()
            }
            return persistentContainer.viewContext
        }
    }
    
    var backgroundContext: NSManagedObjectContext {
        get {
            if persistentContainer == nil {
                setup()
            }
            return innerBackgroundContext
        }
    }
    
    private var context: NSManagedObjectContext {
        get {
            if Thread.isMainThread {
                return mainContext
            }
            return backgroundContext
        }
    }
    
    @discardableResult
    func saveContext () -> Bool {
        return saveContext(context)
    }
    
    @discardableResult
    func saveContext (_ context: NSManagedObjectContext) -> Bool {
        var result = false
        if context.hasChanges {
            do {
                try context.save()
                result = true
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
        return result
    }
    
    @discardableResult
    func performAndWait(action: (NSManagedObjectContext) -> ()) -> Bool {
        var result = false
        if Thread.isMainThread {
            mainContext.performAndWait {
                action(self.mainContext)
                result = saveContext(self.mainContext)
            }
        } else {
            lockQueue.sync {
                backgroundContext.performAndWait {
                    action(self.backgroundContext)
                    result = saveContext(self.backgroundContext)
                }
            }
        }
        return result
    }
    
    func performAsync(action: @escaping (NSManagedObjectContext) -> ()) {
        if Thread.isMainThread {
            mainContext.perform {
                action(self.mainContext)
                self.saveContext(self.mainContext)
            }
        } else {
            backgroundContext.perform {
                action(self.backgroundContext)
                self.saveContext(self.backgroundContext)
            }
        }
    }
}
