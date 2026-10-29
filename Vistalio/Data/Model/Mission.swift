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
    class func create(context: NSManagedObjectContext, template: MissionTemplate, contents: MissionContents) -> Mission? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Mission", in: context) else { return nil }
        
        let mission =  Mission(entity: entityDescription, insertInto: context)
        mission.name = template.name
        mission.photoPath = template.cover
        mission.about = template.fullDescription
        mission.creationDate = Date()
        mission.updateDate = mission.creationDate
        mission.templateId = template.id
        mission.showCompleted = contents.showCompleted ?? false
        mission.canCreateSteps = contents.canCreateSteps ?? true
        mission.skipRecommend = contents.skipRecommend ?? false
        mission.sortOrderUpTo = Int32(contents.sortOrderUpTo ?? 0)
        mission.skipSortByImplemented = contents.skipSortByImplemented ?? false
        mission.dailyNotificationText = contents.dailyNotificationText
        mission.emotionsPriority = contents.emotionsPriority
        mission.selectEmotionScope = contents.selectEmotionScope?.rawValue
        mission.selectEmotionAlgorithm = contents.selectEmotionAlgorithm?.rawValue
        mission.selectEmotionPeriod = Int16(contents.selectEmotionPeriod ?? 0)
        
        var stepIndex = 0
        
        for (i, b) in contents.blocks.enumerated() {
            if let blockEntity = NSEntityDescription.entity(forEntityName: "StepsBlock", in: context) {
                let block = StepsBlock(entity: blockEntity, insertInto: context)
                block.id = i+1
                block.mission = mission
                block.nextAppears = b.nextAppears?.rawValue
                block.artefacts = b.artefacts?.map { $0.rawValue }.joined(separator: ",")
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
                block.nextBlockHint = b.nextBlockHint
                block.stepDayStartPoint = b.stepDayStartPoint?.rawValue
                block.nextBlockDependsOnEmotion = b.nextBlockDependsOnEmotion ?? false
                
//                if i == 0 {
//                    block.unlock()
//                }
                
                let now = Date().startOfDay
                let calendar = Calendar.current
                
                for s in b.steps {
                    var steps = [MissionStep]()
                    if let days = s.days {
                        for d in days {
                            let date = calendar.date(byAdding: .day, value: d, to: now)!
                            stepIndex += 1
                            if let step = MissionStep.create(context: context, template: s, id: stepIndex, block: block, mission: mission, startDate: date) {
                                steps.append(step)
                            }
                        }
                    } else {
                        stepIndex += 1
                        if let step = MissionStep.create(context: context, template: s, id: stepIndex, block: block, mission: mission) {
                            steps.append(step)
                        }
                    }
                    
                    if (contents.skipRecommend == true || contents.autoAddFirstBlock == true) && i == 0 {
                        for step in steps {
                            step.addedDate = Date()
                            if step.startDate == nil {
                                step.startDate = step.addedDate!.toDateString
                            }
                            if step.sortOrder == 0 {
                                step.sortOrder = Int32(step.id)
                            }
                            if let time = s.getFormattedTime(mission: contents) {
                                step.scheduleDailyNotifications(time: time)
                            }
                        }
                    }
                }
            }
        }
        
        for g in (contents.reminderGroups ?? []) {
            RemindersGroup.create(context: context, templateGroup: g, mission: mission)
        }
        
        return mission
    }
    
    public override func prepareForDeletion() {
        if let photoPath = photoPath {
            FilesHelper().deleteFile(path: photoPath)
            print("Mission cover file deleted")
        }
        
        var notifications = [String]()
        reminderGroups?.allObjects.map { $0 as! RemindersGroup }.forEach {
            notifications.append($0.notificationRequestId)
        }
        addedSteps.forEach {
            if let id = $0.notificationId {
                notifications.append(id)
            }
        }
        allBlocks.forEach {
            if let id = $0.notificationId {
                notifications.append(id)
            }
        }
        removeScheduledNotifications(notifications)
    }
    
    var addedSteps: [MissionStep] {
        let blocks = blocks?.allObjects.map { $0 as! StepsBlock } ?? []
        let steps = blocks.flatMap { ($0.steps?.allObjects as? [MissionStep]) ?? [] }
        return steps.filter { $0.addedDate != nil }
    }
    
    var addedStepsSorted: [MissionStep] {
        let steps = addedSteps
        if !skipSortByImplemented {
            steps.forEach {
                $0.isImplemented = $0.isImplementedForDate($0.lastDate)
            }
        }
        return steps.sorted {
            if !skipSortByImplemented && $0.isImplemented != $1.isImplemented {
                return $1.isImplemented
            }
            if $0.sortOrder == 0 && $1.sortOrder == 0 {
                return $0.id < $1.id
            }
            return $0.sortOrder < $1.sortOrder
        }
    }
    
    var maxSortOrder: Int32 {
        let maxValue = (sortOrderUpTo > 0 ? Int(sortOrderUpTo) : Int.max)
        return (addedSteps.filter { $0.id >= 0 && $0.sortOrder <= maxValue }.max(by: { $0.sortOrder < $1.sortOrder })?.sortOrder ?? 0)
    }
    
    var minSortOrder: Int32 {
        return min(-1, (addedSteps.min(by: { $0.sortOrder < $1.sortOrder })?.sortOrder ?? -1))
    }
    
    var openedBlocks: [StepsBlock] {
        return (blocks?.allObjects as? [StepsBlock])?.filter { $0.id >= 0 && $0.recommendedAt != nil }.sorted(by: { $0.recommendedAt! < $1.recommendedAt! }) ?? []
    }
    
    func checkAllStepsDone() {
        guard let lastOpenedBlock = lastOpenedBlock else {
            return
        }
        let artefacts = lastOpenedBlock.artefactsArray
        let steps = openedBlocks.flatMap { $0.steps?.allObjects.map { $0 as! MissionStep } ?? [] }.filter { $0.id > 0 }
        for s in steps {
            if (s.implementedSteps?.allObjects.isEmpty ?? true) || !s.hasArtefacts(artefacts) {
                return
            }
        }
        lastOpenedBlock.checkRespectsPeriod()
    }
    
    var hasMandatoryArtefacts: Bool {
        guard let lastOpenedBlock = lastOpenedBlock else {
            return false
        }
        let artefacts = lastOpenedBlock.artefactsArray
        if artefacts.isEmpty {
            return true
        }
        let steps = openedBlocks.flatMap { $0.steps?.allObjects.map { $0 as! MissionStep } ?? [] }.filter { $0.id > 0 }
        for s in steps {
            if !s.hasArtefacts(artefacts) {
                return false
            }
        }
        return true
    }
    
    @discardableResult func getNotesStep() -> MissionStep? {
        var step = addedSteps.first { $0.id == -1 }
        if step == nil {
            CoreDataStack.shared.performAndWait { context in
                step = MissionStep.create(context: context, mission: self, name: "Шаг для общих заметок", text: "Заметки, не привязанные к конкретному шагу(-ам).", frequency: .once, startDate: Date(), endDate: nil)
                step?.id = -1
                step?.sortOrder = Int32.max
            }
        }
        return step
    }
    
    func backFromArchived(context: NSManagedObjectContext, viewController: UIViewController) {
        archivedAt = nil
        if let lastOpenedBlock = openedBlocks.last {
            if lastOpenedBlock.nextAppears == NextBlockAppearRule.onAnyBlockStepArtefacts.rawValue {
                if lastOpenedBlock.hasMandatoryArtefacts {
                    lastOpenedBlock.checkRespectsPeriod()
                }
            }
            else if lastOpenedBlock.nextAppears == NextBlockAppearRule.respectPeriod.rawValue {
                lastOpenedBlock.checkRespectsPeriod()
            } else if lastOpenedBlock.nextAppears == NextBlockAppearRule.onAllBlockStepsArtefacts.rawValue {
                if lastOpenedBlock.allStepsHaveArtefacts {
                    lastOpenedBlock.checkRespectsPeriod()
                }
            } else if lastOpenedBlock.nextAppears == NextBlockAppearRule.onAllMissionStepsArtefacts.rawValue {
                if hasMandatoryArtefacts {
                    lastOpenedBlock.checkRespectsPeriod()
                }
            } else if lastOpenedBlock.nextAppears == NextBlockAppearRule.onAllMissionStepsDone.rawValue {
                checkAllStepsDone()
            }
        }
        NotificationCenter.default.post(name: .notificationsUpdated, object: nil)
        
        let steps = addedSteps
        steps.forEach {
            if let time = $0.formattedTime {
                $0.scheduleDailyNotifications(time: time)
            }
        }
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
    
    var allBlocks: [StepsBlock] {
        return blocks?.allObjects.map({ $0 as! StepsBlock }) ?? []
    }
    
    var mainBlocks: [StepsBlock] {
        return blocks?.allObjects.map({ $0 as! StepsBlock }).filter { $0.emotionGroup == nil }.sorted(by: { $0.id < $1.id }) ?? []
    }
    
    var emotionBlocks: [StepsBlock] {
        return blocks?.allObjects.map({ $0 as! StepsBlock }).filter { $0.emotionGroup != nil && !$0.isSpecialBlock } ?? []
    }
    
    var lastOpenedBlock: StepsBlock? {
        return allBlocks.filter { $0.recommendedAt != nil }.max { $0.recommendedAt! < $1.recommendedAt! }
    }
    
    func checkEmotionsToOpenSpecialSteps() {
        let blocks = emotionBlocks.filter { $0.isSpecialBlock }
        if blocks.isEmpty {
            return
        }
        let notes = self.blocks?.allObjects.flatMap({ ($0 as! StepsBlock).notes }) ?? []
        let emotions = notes.flatMap({ $0.emotions?.allObjects.map { $0 as! MissionNoteEmotion } ?? [] })
        var blocksOpen = false
        
        for b in blocks {
            if b.recommendedAt == nil, let group = b.emotionGroup {
                let groupEmotions = emotions.filter { MissionEmotion(rawValue:  $0.emotion)!.group.rawValue == group }
                if groupEmotions.count >= b.emotionsCountToOpenBlock {
                    if b.periodDays > 0 {
                        let dateSince = Calendar.current.date(byAdding: blocksTimeUnit, value: -Int(b.periodDays), to: Date())!
                        let emotionsSinceDateCount = groupEmotions.count { $0.date >= dateSince }
                        if emotionsSinceDateCount < b.emotionsCountToOpenBlock {
                            continue
                        }
                    }
                    blocksOpen = true
                    CoreDataStack.shared.performAndWait { _ in
                        b.recommendedAt = Date()
                        if skipRecommend {
                            var sortOrder = maxSortOrder + 1
                            b.steps?.allObjects.map { $0 as! MissionStep }.forEach {
                                $0.addedDate = Date()
                                $0.sortOrder = sortOrder
                                sortOrder += 1
                            }
                        }
                    }
                }
            }
        }
        if blocksOpen {
            NotificationCenter.default.post(name: skipRecommend ? .stepUpdated : .recommendedStepsUpdated, object: nil)
        }
    }
    
    var lastEmotionDate: Date? {
        let notes = self.blocks?.allObjects.flatMap({ ($0 as! StepsBlock).notes }) ?? []
        let emotions = notes.flatMap({ $0.emotions?.allObjects.map { $0 as! MissionNoteEmotion } ?? [] })
        return emotions.max { $0.date < $1.date }?.date
    }
    
    func findStep(id: Int) -> MissionStep? {
        let blocks = blocks?.allObjects.map { $0 as! StepsBlock } ?? []
        for b in blocks {
            let steps = b.steps?.allObjects.map { $0 as! MissionStep } ?? []
            for s in steps {
                if s.id == id {
                    return s
                }
            }
        }
        return nil
    }
    
    func removeStepsDailyNotifications() {
        var toRemove = [String]()
        let blocks = blocks?.allObjects.map { $0 as! StepsBlock } ?? []
        for b in blocks {
            let steps = b.steps?.allObjects.map { $0 as! MissionStep } ?? []
            for s in steps {
                if let notificationId = s.notificationId {
                    toRemove.append(notificationId)
                    s.notificationId = nil
                    s.dailyNotificationScheduled = false
                }
            }
        }
        if !toRemove.isEmpty {
            removeScheduledNotifications(toRemove)
        }
    }
    
    
    var nextEmotionBlock: StepsBlock? {
        let algorithm = (selectEmotionAlgorithm != nil ? SelectEmotionAlgorithm(rawValue: selectEmotionAlgorithm!) : .goThroughAll)
        let scope = (selectEmotionScope != nil ? SelectEmotionScope(rawValue: selectEmotionScope!) : .block)
        var blocks = [StepsBlock]()
        if scope == .app {
            blocks = MissionsHolder.shared.getMyMissions().flatMap { $0.openedBlocks }
        } else if scope == .mission {
            blocks = openedBlocks
        } else if let block = lastOpenedBlock {
            blocks.append(block)
        }
        let notes = blocks.flatMap { $0.steps?.allObjects ?? [] }.map { $0 as! MissionStep }.flatMap { $0.notes?.allObjects.map { $0 as! MissionNote } ?? [] }
        var missionEmotions = notes.flatMap { $0.emotions?.allObjects.map({ $0 as! MissionNoteEmotion }) ?? [] }
        
        if selectEmotionPeriod > 0 {
            let date = Calendar.current.date(byAdding: blocksTimeUnit, value: -Int(selectEmotionPeriod), to: Date())!
            missionEmotions = missionEmotions.filter { $0.date >= date }
        }
        
        let emotions = missionEmotions.map { MissionEmotion(rawValue: $0.emotion)! }
        print("Emotions: \(emotions)")
        let priorities: [EmotionGroup] = emotionsPriority?.components(separatedBy: ",").map { EmotionGroup(rawValue: $0)! } ?? [.anger, .joy, .fear, .sadness]
        var sortedGroups: [EmotionGroup]
        
        if emotions.isEmpty {
            sortedGroups = priorities
        } else {
            let groupedBlockEmotions = Dictionary(grouping: emotions, by: { $0.group } )
            let emotionGroups: [EmotionGroup] = Array(groupedBlockEmotions.keys)
            
            sortedGroups = emotionGroups.sorted {
                let count1 = groupedBlockEmotions[$0]!.count
                let count2 = groupedBlockEmotions[$1]!.count
                if count1 == count2 {
                    return priorities.firstIndex(of: $0)! < priorities.firstIndex(of: $1)!
                }
                return count1 > count2
            }
            if sortedGroups.count < priorities.count {
                for p in priorities {
                    if !sortedGroups.contains(p) {
                        sortedGroups.append(p)
                    }
                }
            }
        }
        
        let emotionBlocks = emotionBlocks
        
        if algorithm == .goThroughAll {
            let groupedBlocks: [String: [StepsBlock]]
            var availableEmotionGroups = [EmotionGroup]()
            let openedBlocks = emotionBlocks.filter { $0.recommendedAt != nil }
            groupedBlocks = Dictionary(grouping: openedBlocks.filter { $0.emotionGroup != nil }, by: { $0.emotionGroup! } )
            let maxCount = groupedBlocks.values.map({ $0.count }).max() ?? 0
            let maxCountBlocks = groupedBlocks.filter { $0.value.count == maxCount }
            
            if maxCountBlocks.count == 0 || maxCountBlocks.count == 4 {
                availableEmotionGroups = priorities
            } else {
                let maxEmotionGroups = maxCountBlocks.map { EmotionGroup(rawValue: $0.key)! }
                availableEmotionGroups = priorities.filter { !maxEmotionGroups.contains($0) }
            }
            sortedGroups = sortedGroups.filter { availableEmotionGroups.contains($0) }
        }
        
        let sortedBlocks = emotionBlocks.filter { $0.recommendedAt == nil && sortedGroups.contains(EmotionGroup(rawValue: $0.emotionGroup!)!) }.sorted {
            let index1 = sortedGroups.firstIndex(of: EmotionGroup(rawValue: $0.emotionGroup!)!)!
            let index2 = sortedGroups.firstIndex(of: EmotionGroup(rawValue: $1.emotionGroup!)!)!
            if index1 == index2 {
                return $0.id < $1.id
            }
            return index1 < index2
        }
        return sortedBlocks.first
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
    @NSManaged public var sortOrderUpTo: Int32
    @NSManaged public var skipSortByImplemented: Bool
    @NSManaged public var dailyNotificationText: String?
    @NSManaged public var emotionsPriority: String?
    @NSManaged public var selectEmotionScope: String?
    @NSManaged public var selectEmotionAlgorithm: String?
    @NSManaged public var selectEmotionPeriod: Int16
    
    @NSManaged public var blocks: NSSet?
    @NSManaged public var notifications: NSSet?
    @NSManaged public var reminderGroups: NSSet?
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
