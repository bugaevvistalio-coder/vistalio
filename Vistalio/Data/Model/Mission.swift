//
//  Mission+CoreDataProperties.swift
//  
//
//  Created by Julia Konkova on 03.04.2026.
//
//

import UIKit
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
        mission.canCreateSteps = true
        
        return mission
    }
    
    @discardableResult
    class func create(context: NSManagedObjectContext, template: MissionTemplate, blocks: [TemplateBlock], reminders: [TemplateReminder]?) -> Mission? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Mission", in: context) else { return nil }
        
        let mission =  Mission(entity: entityDescription, insertInto: context)
        mission.name = template.name
        mission.photoPath = template.cover
        mission.about = template.fullDescription
        mission.creationDate = Date()
        mission.updateDate = mission.creationDate
        mission.templateId = template.id
        mission.showCompleted = template.showCompleted ?? false
        mission.canCreateSteps = template.canCreateSteps ?? true
        mission.skipRecommend = template.skipRecommend ?? false
        mission.reminderNotificationRequestId = UUID().uuidString
        
        var stepIndex = 0
        var noteIndex = 0
        
        for (i, b) in blocks.enumerated() {
            if let blockEntity = NSEntityDescription.entity(forEntityName: "StepsBlock", in: context) {
                let block = StepsBlock(entity: blockEntity, insertInto: context)
                block.id = i+1
                block.mission = mission
                block.nextAppears = b.nextAppears?.rawValue
                block.doneCriteria = b.doneCriteria?.map { $0.rawValue }.joined(separator: ",")
                block.photoMin = Int16(b.photoMin ?? 1)
                block.searchText = b.searchText
                block.textPlaceholder = b.textPlaceholder
                block.answerHint = b.answerHint
                block.periodDays = Int16(b.periodDays ?? 0)
                block.nextBlockNotificationTitle = b.nextBlockNotificationTitle
                block.nextBlockNotificationBody = b.nextBlockNotificationBody
                block.emotionGroup = b.emotionGroup
                block.emotionsCountToOpenBlock = Int16(b.emotionsCountToOpenBlock ?? 0)
                block.isSpecialBlock = b.isSpecialBlock ?? false
                
                if i == 0 {
                    block.unlock()
                }
                
                for s in b.steps {
                    if let stepEntity = NSEntityDescription.entity(forEntityName: "MissionStep", in: context) {
                        stepIndex += 1
                        
                        let step = MissionStep(entity: stepEntity, insertInto: context)
                        step.id = stepIndex
                        step.name = s.name
                        step.text = s.description
                        step.editable = s.editable ?? true
                        step.noteTitle = s.noteTitle
                        step.frequency = s.frequency?.rawValue ?? 0
                        step.block = block
                        
                        if (mission.skipRecommend || template.autoAddFirstBlock == true) && i == 0 {
                            step.addedDate = Date()
                            step.startDate = step.addedDate!.toDateString
                            step.sortOrder = Int32(stepIndex)
                        }
                        
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
        
        for r in (reminders ?? []) {
            Reminder.create(context: context, templateReminder: r, mission: mission)
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
    
    var addedStepsSorted: [MissionStep] {
        return addedSteps.sorted {
            if $0.sortOrder == 0 && $1.sortOrder == 0 {
                return $0.id > $1.id
            }
            return $0.sortOrder > $1.sortOrder
        }
    }
    
    var maxSortOrder: Int32 {
        return (addedSteps.max(by: { $0.sortOrder < $1.sortOrder })?.sortOrder ?? 0)
    }
    
    var openedBlocks: [StepsBlock] {
        return (blocks?.allObjects as? [StepsBlock])?.filter { $0.id >= 0 && $0.recommendedAt != nil }.sorted(by: { $0.recommendedAt! < $1.recommendedAt! }) ?? []
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
    
    func backFromArchived(context: NSManagedObjectContext, viewController: UIViewController) {
        archivedAt = nil
        if let lastOpenedBlock = openedBlocks.last {
            if lastOpenedBlock.nextAppears == NextBlockAppearRule.onNoteRespectPeriod.rawValue || lastOpenedBlock.nextAppears == NextBlockAppearRule.onNote.rawValue {
                let notes = lastOpenedBlock.notes
                if !notes.isEmpty {
                    lastOpenedBlock.checkPeriod = false
                    DispatchQueue.main.async {
                        notes.last!.step?.onNoteAdded(from: viewController, hasEmotion: false)
                    }
                }
            } else if lastOpenedBlock.nextAppears == NextBlockAppearRule.onEmotionRespectPeriod.rawValue || lastOpenedBlock.nextAppears == NextBlockAppearRule.onEmotion.rawValue {
                let notes = lastOpenedBlock.notes
                let emotions = notes.flatMap { $0.emotions?.allObjects ?? [] }
                if !emotions.isEmpty {
                    lastOpenedBlock.checkPeriod = false
                    DispatchQueue.main.async {
                        notes.last!.step?.onNoteAdded(from: viewController, hasEmotion: true)
                    }
                }
            } else if lastOpenedBlock.nextAppears == NextBlockAppearRule.respectPeriod.rawValue {
                let daysBetween = Calendar.current.dateComponents([.minute], from: lastOpenedBlock.recommendedAt!, to: Date()).minute!
                if daysBetween >= Int(lastOpenedBlock.periodDays) {
                    lastOpenedBlock.unlockNextBlock()
                }
            }
        }
        NotificationCenter.default.post(name: .notificationsUpdated, object: nil)
        
        MissionsHolder.shared.scheduleReminderNotificationOnStepImplemented(mission: self)
    }
    
    func readNotifications() {
        var hasRead = false
        CoreDataStack.shared.performAndWait { context in
            notifications?.allObjects.forEach {
                let n = $0 as! AppNotification
                if !n.isRead {
                    n.isRead = true
                    hasRead = true
                }
            }
        }
        if hasRead {
            NotificationCenter.default.post(name: .notificationsUpdated, object: nil)
        }
    }
    
    var remindersSorted: [Reminder]? {
        return reminders?.allObjects.map { $0 as! Reminder }.sorted {
            return $0.id < $1.id
        }
    }
    
    var allBlocks: [StepsBlock] {
        return blocks?.allObjects.map({ $0 as! StepsBlock }) ?? []
    }
    
    var mainBlocks: [StepsBlock] {
        return blocks?.allObjects.map({ $0 as! StepsBlock }).filter { $0.emotionGroup == nil }.sorted(by: { $0.id < $1.id }) ?? []
    }
    
    var emotionBlocks: [StepsBlock] {
        return blocks?.allObjects.map({ $0 as! StepsBlock }).filter { $0.emotionGroup != nil } ?? []
    }
    
    func checkEmotionsToOpenSpecialSteps() {
        let blocks = emotionBlocks.filter { $0.isSpecialBlock }
        if blocks.isEmpty {
            return
        }
        let notes = self.blocks?.allObjects.flatMap({ ($0 as! StepsBlock).notes }) ?? []
        let emotions = notes.flatMap({ $0.emotions?.allObjects.map { $0 as! MissionNoteEmotion } ?? [] }).map { MissionEmotion(rawValue:  $0.emotion)! }
        var blocksOpen = false
        
        for b in blocks {
            if b.recommendedAt == nil, let group = b.emotionGroup {
                let count = emotions.count { $0.group.rawValue == group }
                if count >= b.emotionsCountToOpenBlock {
                    blocksOpen = true
                    CoreDataStack.shared.performAndWait { _ in
                        b.recommendedAt = Date()
                    }
                }
            }
        }
        if blocksOpen {
            NotificationCenter.default.post(name: .recommendedStepsUpdated, object: nil)
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
    @NSManaged public var archivedAt: Date?
    @NSManaged public var finishedAt: Date?
    @NSManaged public var sortOrder: Int32
    @NSManaged public var showCompleted: Bool
    @NSManaged public var canCreateSteps: Bool
    @NSManaged public var skipRecommend: Bool
    @NSManaged public var lastReminderAt: Date?
    
    @NSManaged public var reminderNotificationId: Int16
    @NSManaged public var reminderNotificationRequestId: String?
    
    @NSManaged public var blocks: NSSet?
    @NSManaged public var notifications: NSSet?
    @NSManaged public var reminders: NSSet?
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
