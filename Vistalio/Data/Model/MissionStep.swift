//
//  MissionStep.swift
//  Vistalio
//
//  Created by Julia Konkova on 27.04.2026.
//

import UIKit
import CoreData

enum StepFrequency: Int16, CaseIterable {
    case untilDone = 0
    case once = 1
    case everyDay = 2
    case everyOtherDay = 3
    case everyWeek = 4
    case everyTwoWeeks = 5
    case everyMonth = 6
    case everyYear = 7
    
    var displayName: String {
        switch self {
        case .untilDone:
            return "Пока не выполнен"
        case .once:
            return "Один раз"
        case .everyDay:
            return "Каждый день"
        case .everyOtherDay:
            return "Через день"
        case .everyWeek:
            return "Каждую неделю"
        case .everyTwoWeeks:
            return "Каждые 2 недели"
        case .everyMonth:
            return "Каждый месяц"
        case .everyYear:
            return "Каждый год"
        }
    }
}

@objc(StepsBlock)
public class StepsBlock: NSManagedObject {
    
}

extension StepsBlock {
    
    @nonobjc public class func blockFetchRequest() -> NSFetchRequest<StepsBlock> {
        return NSFetchRequest<StepsBlock>(entityName: "StepsBlock")
    }
    
    @NSManaged public var id: Int
    
    @NSManaged public var nextAppears: String?
    @NSManaged public var doneCriteria: String?
    @NSManaged public var photoMin: Int16
    @NSManaged public var searchText: String?
    @NSManaged public var recommendedAt: Date?
    @NSManaged public var locked: Bool
    @NSManaged public var textPlaceholder: String?
    @NSManaged public var answerHint: String?
    @NSManaged public var periodDays: Int16
    @NSManaged public var checkPeriod: Bool
    @NSManaged public var notificationId: String?
    @NSManaged public var emotionGroup: String?
    @NSManaged public var emotionsCountToOpenBlock: Int16
    
    @NSManaged public var nextBlockNotificationTitle: String?
    @NSManaged public var nextBlockNotificationBody: String?
    
    @NSManaged public var mission: Mission
    @NSManaged public var steps: NSSet?
    @NSManaged public var movedSteps: NSSet?
    
    @discardableResult
    class func create(context: NSManagedObjectContext, mission: Mission) -> StepsBlock? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "StepsBlock", in: context) else { return nil }
        
        let block =  StepsBlock(entity: entityDescription, insertInto: context)
        block.id = -1
        block.mission = mission
        
        return block
    }
    
    var isNoteMandatory: Bool {
        let array = doneCriteriaArray
        return array.contains(BlockDoneCriteria.geo) || array.contains(BlockDoneCriteria.photo) || array.contains(BlockDoneCriteria.video) || array.contains(BlockDoneCriteria.searchText)
    }
    
    var fitsDoneCriteria: Bool {
        let array = doneCriteriaArray
        let notes = notes
        
//        if array.contains(BlockDoneCriteria.geo) {
//            return false
//        }
        let media = notes.flatMap { $0.images?.allObjects.map { $0 as! MissionNoteImage } ?? [] }
        if array.contains(BlockDoneCriteria.photo), media.filter({ $0.type == "image" }).count < photoMin {
            return false
        }
        if array.contains(BlockDoneCriteria.video), media.filter({ $0.type == "video" }).count == 0 {
            return false
        }
        if array.contains(BlockDoneCriteria.photoOrVideo), media.count == 0 {
            return false
        }
        if array.contains(BlockDoneCriteria.searchText), let searchText = searchText?.lowercased(), !notes.contains(where: { ($0.text?.lowercased().contains(searchText) ?? false) || ($0.name?.lowercased().contains(searchText) ?? false) }) {
            return false
        }
        return true
    }
    
    var notes: [MissionNote] {
        return steps?.allObjects.map { $0 as! MissionStep }.flatMap { $0.notes?.allObjects.map { $0 as! MissionNote } ?? [] }.filter { $0.byUser && $0.step!.id >= 0 } ?? []
    }
    
    var doneCriteriaArray: [BlockDoneCriteria] {
        let array = doneCriteria?.components(separatedBy: ",") ?? []
        return array.map { BlockDoneCriteria(rawValue: $0)! }
    }
    
    @discardableResult
    func unlockNextBlock(date: Date? = nil) -> Bool {
        guard let nextBlock = nextBlock, nextBlock.recommendedAt == nil else {
            print("Skip next block unlock")
            return false
        }
        print("Next block unlocked")
        CoreDataStack.shared.performAndWait { context in
            nextBlock.unlock(date: date)
            checkPeriod = false
            
            AppNotification.create(context: context, title: nextBlockNotificationTitle ?? mission.name ?? "", text: nextBlockNotificationBody ?? "Открылись новые шаги", isRead: false, mission: mission, type: .newSteps)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .recommendedStepsUpdated, object: nil)
            NotificationCenter.default.post(name: .notificationsUpdated, object: nil)
        }
        return true
    }
    
    func unlock(date: Date? = nil) {
        recommendedAt = date ?? Date()
        if nextAppears == NextBlockAppearRule.respectPeriod.rawValue {
            let nextBlockDate = Calendar.current.date(byAdding: .minute, value: Int(periodDays), to: recommendedAt!)!
            if nextBlockDate <= Date() {
                DispatchQueue.global().async {
                    self.unlockNextBlock(date: nextBlockDate)
                }
                addNotification(title: nextBlockNotificationTitle ?? mission.name ?? "", body: nextBlockNotificationBody ?? "Открылись новые шаги", notificationId: UUID().uuidString)
            } else {
                checkPeriod = true
                DispatchQueue.global().async { [weak self] in
                    self?.scheduleAppearNotification()
                }
            }
        }
    }
    
    var nextBlock: StepsBlock? {
        return mission.mainBlocks.first(where: { $0.id > id })
    }
    
    func autoImplement() -> MissionStep? {

        let nextBlock = nextBlock
        var nextStep: MissionStep?
        
        CoreDataStack.shared.performAndWait { context in
            locked = true
            steps?.allObjects.forEach {
                let step = $0 as! MissionStep
                ImplementedStep.create(context: context, step: step, date: Date())
            }
            
            if let nextBlock = nextBlock, nextBlock.recommendedAt == nil {
                nextBlock.unlock()
                checkPeriod = false
                nextBlock.steps?.allObjects.forEach {
                    let step = $0 as! MissionStep
                    step.addedDate = Date()
                    step.startDate = step.addedDate!.toDateString
                    step.sortOrder = mission.maxSortOrder + 1
                    nextStep = step
                }
            }
        }
        
        NotificationCenter.default.post(name: .stepUpdated, object: nil)
        return nextStep
    }
    
    func checkAutoImplementAfterNoteCreated() -> MissionStep? {
        if recommendedAt != nil && nextAppears == NextBlockAppearRule.onDoneWithPreview.rawValue && (doneCriteriaArray.contains(.note) || fitsDoneCriteria) {
            return autoImplement()
        }
        return nil
    }
    
    func checkDoneCriteria(title: String?, text: String?, photoCount: Int, hasVideo: Bool) -> NSAttributedString? {
        var attrString: NSMutableAttributedString?
        if recommendedAt != nil && nextAppears == NextBlockAppearRule.onDoneWithPreview.rawValue {
            let array = doneCriteriaArray
            let notes = notes
            
            if array.contains(BlockDoneCriteria.searchText), let searchText = searchText?.lowercased() {
                let titleContains = title?.lowercased().contains(searchText) ?? false
                let textContains = text?.lowercased().contains(searchText) ?? false
                let notesContain = notes.contains(where: { ($0.text?.lowercased().contains(searchText) ?? false) || ($0.name?.lowercased().contains(searchText) ?? false) })
                if !titleContains && !textContains && !notesContain {
                    let firstAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 24, weight: .semibold)]
                    attrString = NSMutableAttributedString(string: "Для открытия следующего шага напишите ", attributes: firstAttributes)
                    
                    let secondAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.brightBlue, .font: UIFont.systemFont(ofSize: 24, weight: .semibold)]
                    let secondPart = NSAttributedString(string: answerHint ?? searchText, attributes: secondAttributes)
                    attrString!.append(secondPart)
                }
            }
            
            var criteria = [String]()
            let media = notes.flatMap { $0.images?.allObjects.map { $0 as! MissionNoteImage } ?? [] }
            if array.contains(BlockDoneCriteria.photo) {
                let count = media.filter({ $0.type == "image" }).count + photoCount
                if count < photoMin {
                    var text = "фото"
                    if photoMin > 1 {
                        text += " ещё \(Int(photoMin) - count) шт."
                    }
                    criteria.append(text)
                }
            }
            if array.contains(BlockDoneCriteria.video) && !hasVideo && media.filter({ $0.type == "video" }).count == 0 {
                criteria.append("видео")
            }
            if array.contains(BlockDoneCriteria.photoOrVideo) && !hasVideo && photoCount == 0 && media.isEmpty {
                criteria.append("фото или видео")
            }
            
            if !criteria.isEmpty {
                let firstAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 24, weight: .semibold)]
                if attrString == nil {
                    attrString = NSMutableAttributedString(string: "Для открытия следующего шага добавьте: ", attributes: firstAttributes)
                } else {
                    attrString = NSMutableAttributedString(string: " и добавьте ", attributes: firstAttributes)
                }
                
                let secondAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.brightBlue, .font: UIFont.systemFont(ofSize: 24, weight: .semibold)]
                let secondPart = NSAttributedString(string: criteria.joined(separator: ", "), attributes: secondAttributes)
                attrString!.append(secondPart)
            }
        }
        return attrString
    }
    
    
    func scheduleAppearNotification() {
        guard let recommendedAt = recommendedAt else {
            return
        }
        if mission.archivedAt != nil {
            return
        }
        let notificationId = UUID().uuidString
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .minute, value: Int(periodDays), to: recommendedAt)!
        let userInfo: [AnyHashable: Any] = ["fireDate": date]

        let components = calendar.dateComponents([.day, .month, .year, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        addNotification(title: nextBlockNotificationTitle ?? mission.name ?? "", body: nextBlockNotificationBody ?? "Открылись новые шаги", notificationId: notificationId, userInfo: userInfo, trigger: trigger)
        
        CoreDataStack.shared.performAndWait { context in
            self.notificationId = notificationId
        }
    }
}

extension StepsBlock {
    
    @objc(addStepsObject:)
    @NSManaged public func addToSteps(_ value: MissionStep)

    @objc(removeStepsObject:)
    @NSManaged public func removeFromSteps(_ value: MissionStep)

    @objc(addSteps:)
    @NSManaged public func addToSteps(_ values: NSSet)

    @objc(removeSteps:)
    @NSManaged public func removeFromSteps(_ values: NSSet)
    
}

@objc(MissionStep)
public class MissionStep: NSManagedObject {
    
    var expanded = false
    
}

extension MissionStep {

    @nonobjc public class func stepFetchRequest() -> NSFetchRequest<MissionStep> {
        return NSFetchRequest<MissionStep>(entityName: "MissionStep")
    }

    @NSManaged public var id: Int
    @NSManaged public var name: String?
    @NSManaged public var text: String?
    @NSManaged public var hidden: Bool
    @NSManaged public var addedDate: Date?
    @NSManaged public var sortOrder: Int32
    @NSManaged public var editable: Bool
    
    @NSManaged public var startDate: String?
    @NSManaged public var endDate: String?
    @NSManaged public var frequency: Int16
    
    @NSManaged public var noteTitle: String?
    
    @NSManaged public var block: StepsBlock
    @NSManaged public var notes: NSSet?
    @NSManaged public var implementedSteps: NSSet?
    @NSManaged public var removedSteps: NSSet?
    
    @NSManaged public var originalName: String?
    @NSManaged public var originalText: String?
    @NSManaged public var originalBlock: StepsBlock?
    
    var shortText: String? {
        return text?.replacingOccurrences(of: "\n\n", with: " ").replacingOccurrences(of: "\n", with: " ")
    }
    
    var hasFrequency: Bool {
        return id >= 0 && block.mission.category != MissionCategory.notes.rawValue
    }
    
    @discardableResult
    class func create(context: NSManagedObjectContext, mission: Mission, name: String, text: String?, frequency: StepFrequency, startDate: Date, endDate: Date?) -> MissionStep? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "MissionStep", in: context) else { return nil }
        
        let blocks = mission.blocks?.allObjects.map { $0 as! StepsBlock } ?? []
        guard let block = blocks.first(where: { $0.id == -1 }) ?? StepsBlock.create(context: context, mission: mission) else {
            return nil
        }
        
        let step =  MissionStep(entity: entityDescription, insertInto: context)
        step.block = block
        step.addedDate = Date()
        step.name = name
        step.text = text
        step.frequency = frequency.rawValue
        step.startDate = startDate.toDateString
        step.endDate = endDate?.toDateString
        return step
    }
    
    var isOriginal: Bool {
        if originalName == nil {
            return true
        }
        return originalName == name && originalText == text && frequency == 0
    }
    
    func generateDatesForMonth(_ month: Date) -> [Date] {
        var dates = [Date]()
        guard let startDate = startDate?.toDay else {
            return dates
        }
        
        let endDate = endDate?.toDay ?? Date.distantFuture
        let calendar = Calendar.current
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: month)!
        if endDate < month || startDate >= nextMonth {
            return dates
        }
        
        guard let rangeOfDays = calendar.range(of: .day, in: .month, for: month) else {
            return dates
        }
                
        let monthDays = rangeOfDays.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: month)
        }.filter { $0 <= endDate }
        
        if frequency == StepFrequency.once.rawValue {
            if startDate >= month {
                dates.append(startDate)
            }
        } else if frequency == StepFrequency.untilDone.rawValue || frequency == StepFrequency.everyDay.rawValue {
            dates = monthDays.filter { $0 >= startDate }
            if frequency == StepFrequency.untilDone.rawValue, let implemented = implementedSteps?.allObjects.first as? ImplementedStep {
                dates = dates.filter { $0 <= implemented.date.toDay }
            }
        } else if frequency == StepFrequency.everyOtherDay.rawValue || frequency == StepFrequency.everyWeek.rawValue || frequency == StepFrequency.everyTwoWeeks.rawValue {
            var interval = 2
            if frequency == StepFrequency.everyWeek.rawValue {
                interval = 7
            } else if frequency == StepFrequency.everyTwoWeeks.rawValue {
                interval = 14
            }
            var firstDayOffset = 0
            let daysBetween = calendar.dateComponents([.day], from: startDate, to: month).day!
            if daysBetween > 0 {
                if daysBetween % interval > 0 {
                    firstDayOffset = interval - daysBetween % interval
                }
            } else {
                firstDayOffset = -daysBetween
            }
            dates = stride(from: firstDayOffset, to: monthDays.count, by: interval).map { monthDays[$0] }
        } else if frequency == StepFrequency.everyMonth.rawValue || frequency == StepFrequency.everyYear.rawValue {
            if startDate >= month {
                dates.append(startDate)
            } else if frequency == StepFrequency.everyMonth.rawValue || calendar.component(.month, from: startDate) == calendar.component(.month, from: month) {
                let day = calendar.component(.day, from: startDate)
                var date = calendar.date(byAdding: .day, value: day - 1, to: month)!
                if date >= nextMonth {
                    date = calendar.date(byAdding: .day, value: -1, to: nextMonth)!
                }
                if date <= endDate {
                    dates.append(date)
                }
            }
        }
        
        let removed = removedSteps?.allObjects.map { ($0 as! RemovedStep).date.toDay } ?? []
        return dates.filter { !removed.contains($0) }
    }
    
    var lastDate: Date? {
        let now = Date().startOfDay
        guard let startDate = startDate?.toDay else {
            return now
        }
        
        let removed = removedSteps?.allObjects.map { ($0 as! RemovedStep).date.toDay } ?? []
        
        if frequency == StepFrequency.once.rawValue || now <= startDate {
            var date: Date? = startDate
            while date != nil && removed.contains(date!) {
                date = getNextDateAfter(date!)
            }
            return date
        }
        
        let endDate = endDate?.toDay ?? Date.distantFuture
        let minDate = min(now, endDate)
        var dateCandidate: Date?
        
        if frequency == StepFrequency.untilDone.rawValue {
            if let implemented = implementedSteps?.allObjects.first as? ImplementedStep {
                return implemented.date.toDay
            } else {
                dateCandidate = minDate
            }
        } else if frequency == StepFrequency.everyDay.rawValue {
            dateCandidate = minDate
        } else {
            let calendar = Calendar.current
            
            if frequency == StepFrequency.everyOtherDay.rawValue || frequency == StepFrequency.everyWeek.rawValue || frequency == StepFrequency.everyTwoWeeks.rawValue {
                
                var interval = 2
                if frequency == StepFrequency.everyWeek.rawValue {
                    interval = 7
                } else if frequency == StepFrequency.everyTwoWeeks.rawValue {
                    interval = 14
                }
                let daysBetween = calendar.dateComponents([.day], from: startDate, to: minDate).day!
                dateCandidate = calendar.date(byAdding: .day, value: -(daysBetween % interval), to: minDate)
            }
            
            if frequency == StepFrequency.everyMonth.rawValue {
                let monthsBetween = calendar.dateComponents([.month], from: startDate, to: minDate).month!
                dateCandidate = calendar.date(byAdding: .month, value: monthsBetween, to: startDate)
            }
            
            if frequency == StepFrequency.everyYear.rawValue {
                let yearsBetween = calendar.dateComponents([.year], from: startDate, to: minDate).year!
                dateCandidate = calendar.date(byAdding: .year, value: yearsBetween, to: startDate)
            }
        }
        
        var date: Date? = dateCandidate
        while date != nil && removed.contains(date!) {
            date = getNextDateAfter(date!, reverse: true)
        }
        if date == nil {
            date = dateCandidate
            while date != nil && removed.contains(date!) {
                date = getNextDateAfter(date!)
            }
        }
        return date
    }
    
    func getNextDateAfter(_ date: Date, reverse: Bool = false) -> Date? {
        let calendar = Calendar.current
        
        var nextDate: Date?
        switch frequency {
        case StepFrequency.untilDone.rawValue, StepFrequency.everyDay.rawValue:
            nextDate = calendar.date(byAdding: .day, value: reverse ? -1 : 1, to: date)
        case StepFrequency.once.rawValue:
            return nil
        case StepFrequency.everyOtherDay.rawValue:
            return calendar.date(byAdding: .day, value: reverse ? -2 : 2, to: date)
        case StepFrequency.everyWeek.rawValue:
            return calendar.date(byAdding: .day, value: reverse ? -7 : 7, to: date)
        case StepFrequency.everyTwoWeeks.rawValue:
            return calendar.date(byAdding: .day, value: reverse ? -14 : 14, to: date)
        case StepFrequency.everyMonth.rawValue:
            return calendar.date(byAdding: .month, value: reverse ? -1 : 1, to: date)
        case StepFrequency.everyYear.rawValue:
            return calendar.date(byAdding: .year, value: reverse ? -1 : 1, to: date)
        default:
            return nil
        }
        
        let endDate = endDate?.toDay ?? Date.distantFuture
        if let nextDate = nextDate, reverse ? (nextDate < startDate!.toDay) : (nextDate > endDate){
            return nil
        }
        return nextDate
    }
    
    var hasSingleDate: Bool {
        if frequency == StepFrequency.once.rawValue {
            return true
        }
        if endDate == nil {
            return false
        }
        if frequency == StepFrequency.everyDay.rawValue || frequency == StepFrequency.untilDone.rawValue {
            return startDate == endDate
        }
        if frequency == StepFrequency.everyOtherDay.rawValue || frequency == StepFrequency.everyWeek.rawValue || frequency == StepFrequency.everyTwoWeeks.rawValue {
            var interval = 2
            if frequency == StepFrequency.everyWeek.rawValue {
                interval = 7
            } else if frequency == StepFrequency.everyTwoWeeks.rawValue {
                interval = 14
            }
            let daysBetween = Calendar.current.dateComponents([.day], from: startDate!.toDay, to: endDate!.toDay).day!
            return daysBetween < interval
        }
        if frequency == StepFrequency.everyMonth.rawValue {
            let monthsBetween = Calendar.current.dateComponents([.month], from: startDate!.toDay, to: endDate!.toDay).month!
            return monthsBetween == 0
        }
        
        if frequency == StepFrequency.everyYear.rawValue {
            let yearsBetween = Calendar.current.dateComponents([.year], from: startDate!.toDay, to: endDate!.toDay).year!
            return yearsBetween == 0
        }
        return true
    }
    
    func updateImplementedSteps(context: NSManagedObjectContext) {
        guard let implementedSteps = implementedSteps else {
            return
        }
        var implementedByMonths: [String: [ImplementedStep]] = [:]
        for item in implementedSteps {
            let step = item as! ImplementedStep
            let date = step.date.toDay
            let startOfMonth = date.startOfMonth.toDateString
            var steps = implementedByMonths[startOfMonth] ?? []
            steps.append(step)
            implementedByMonths[startOfMonth] = steps
        }
        
        for (month, steps) in implementedByMonths {
            let dates = generateDatesForMonth(month.toDay).map { $0.toDateString }
            for s in steps {
                if !dates.contains(s.date) {
                    context.delete(s)
                    print("Delete for date \(s.date)")
                }
            }
        }
    }
    
    func isImplementedForDate(_ date: Date?) -> Bool {
        guard let date = date else {
            return false
        }
        return implementedSteps?.allObjects.first { ($0 as! ImplementedStep).date == date.toDateString || frequency == StepFrequency.untilDone.rawValue } != nil
    }
    
    func getImplementedForDate(_ date: Date?) -> ImplementedStep? {
        guard let date = date else {
            return nil
        }
        return implementedSteps?.allObjects.first(where: { ($0 as! ImplementedStep).date == date.toDateString || frequency == StepFrequency.untilDone.rawValue }) as? ImplementedStep
    }
    
    func hasItemForDate(_ date: Date) -> Bool {
        let date = date.startOfDay
        let removed = removedSteps?.allObjects.map { ($0 as! RemovedStep).date.toDay } ?? []
        if removed.contains(date) {
            return false
        }
        
        guard let startDate = startDate?.toDay else {
            return false
        }
        
        if frequency == StepFrequency.once.rawValue {
            return date == startDate
        }
        
        if date < startDate {
            return false
        }
        if let endDate = endDate?.toDay, date > endDate {
            return false
        }
        
        if frequency == StepFrequency.everyDay.rawValue {
            return true
        }
        if frequency == StepFrequency.untilDone.rawValue {
            if let implemented = implementedSteps?.allObjects.first as? ImplementedStep {
                return date <= implemented.date.toDay
            } else {
                return true
            }
        }
        if frequency == StepFrequency.everyOtherDay.rawValue || frequency == StepFrequency.everyWeek.rawValue || frequency == StepFrequency.everyTwoWeeks.rawValue {
            var interval = 2
            if frequency == StepFrequency.everyWeek.rawValue {
                interval = 7
            } else if frequency == StepFrequency.everyTwoWeeks.rawValue {
                interval = 14
            }
            let daysBetween = Calendar.current.dateComponents([.day], from: startDate, to: date).day!
            return daysBetween % interval == 0
        }
        let calendar = Calendar.current
        if frequency == StepFrequency.everyMonth.rawValue {
            let monthsBetween = Calendar.current.dateComponents([.month], from: startDate, to: date).month!
            return calendar.date(byAdding: .month, value: monthsBetween, to: startDate) == date
        }
        
        if frequency == StepFrequency.everyYear.rawValue {
            let yearsBetween = Calendar.current.dateComponents([.year], from: startDate, to: date).year!
            return calendar.date(byAdding: .year, value: yearsBetween, to: startDate) == date
        }
        
        return false
    }
    
    @discardableResult
    func moveNotesToNotesStep(context: NSManagedObjectContext, date: Date?, afterDate: Bool) -> Int {
        var moved = 0
        if let step = block.mission.getNotesStep() {
            notes?.allObjects.forEach {
                let note = ($0 as! MissionNote)
                if let date = date?.startOfDay {
                    if afterDate {
                        if let noteDate = note.date?.startOfDay, noteDate >= date {
                            note.step = step
                            moved += 1
                        }
                    } else if note.date?.startOfDay == date {
                        note.step = step
                        moved += 1
                    }
                } else {
                    note.step = step
                    moved += 1
                }
            }
        }
        return moved
    }
    
    func onNoteAdded(from vc: UIViewController?) {
        if block.nextAppears == NextBlockAppearRule.onDoneWithPreview.rawValue {
            if let nextStep = block.checkAutoImplementAfterNoteCreated() {
                vc?.showStepImplemented(nextStep: nextStep)
            } else if block.locked {
                vc?.archiveAndShowMissionCompleted(mission: block.mission)
            }
        } else if block.nextAppears == NextBlockAppearRule.onNote.rawValue && id >= 0 {
            if block.mission.archivedAt == nil && block.unlockNextBlock() {
                showStepsAdded()
            }
        } else if block.nextAppears == NextBlockAppearRule.onNoteRespectPeriod.rawValue && id >= 0 && block.mission.archivedAt == nil, let recommendedAt = block.recommendedAt {
            let daysBetween = Calendar.current.dateComponents([.minute], from: recommendedAt, to: Date()).minute!
            if daysBetween >= Int(block.periodDays) {
                print("Try to unlock next block")
                if block.unlockNextBlock() {
                    showStepsAdded()
                }
            } else if !block.checkPeriod  {
                print("Setup check period")
                CoreDataStack.shared.performAndWait { [unowned self] context in
                    block.checkPeriod = true
                    block.scheduleAppearNotification()
                }
            }
        }
    }
    
    private func showStepsAdded() {
        let mission = block.mission
        (UIApplication.shared.delegate as! AppDelegate).addNotification(text: block.nextBlockNotificationTitle ?? "Открылись новые шаги в \(block.mission.name ?? "")", secondaryText: block.nextBlockNotificationBody ?? "К рекомендуемым шагам →", mission: mission) {
            if let mainVC = UIApplication.shared.mainViewController {
                mainVC.dismiss(animated: false)
                mainVC.switchTab(tabIndex: 1, toRoot: true)
                (mainVC.controllers[1] as! UINavigationController).topViewController?.openMission(mission, recommendedExpanded: true)
            }
        }
    }
    
    func delete(withNotes: Bool) {
        CoreDataStack.shared.performAndWait { context in
            if !withNotes && (notes?.count ?? 0) > 0 {
                moveNotesToNotesStep(context: context, date: nil, afterDate: false)
            }
            if block.id == -1 {
                context.delete(self)
            } else {
                hidden = true
                sortOrder = 0
                addedDate = nil
                startDate = nil
                endDate = nil
                frequency = 0
                if let name = originalName {
                    self.name = name
                    originalName = nil
                }
                if let text = originalText {
                    self.text = text
                    originalText = nil
                }
                implementedSteps?.forEach {
                    context.delete($0 as! ImplementedStep)
                }
                removedSteps?.forEach {
                    context.delete($0 as! RemovedStep)
                }
                if withNotes {
                    notes?.forEach {
                        context.delete($0 as! MissionNote)
                    }
                }
            }
        }
    }
    
    func moveUp() {
        CoreDataStack.shared.performAndWait { [unowned self] context in
            sortOrder = (block.mission.addedSteps.max(by: { $0.sortOrder < $1.sortOrder })?.sortOrder ?? 0) + 1
        }
    }
    
    public override func prepareForDeletion() {
        print("Step deleted")
    }
}

extension MissionStep {

    @objc(addNotesObject:)
    @NSManaged public func addToNotes(_ value: MissionNote)

    @objc(removeNotesObject:)
    @NSManaged public func removeFromNotes(_ value: MissionNote)

    @objc(addNotes:)
    @NSManaged public func addToNotes(_ values: NSSet)

    @objc(removeNotes:)
    @NSManaged public func removeFromNotes(_ values: NSSet)
    
    
    @objc(addImplementedStepsObject:)
    @NSManaged public func addToImplementedSteps(_ value: ImplementedStep)

    @objc(removeImplementedStepsObject:)
    @NSManaged public func removeFromImplementedSteps(_ value: ImplementedStep)

    @objc(addImplementedSteps:)
    @NSManaged public func addToImplementedSteps(_ values: NSSet)

    @objc(removeImplementedSteps:)
    @NSManaged public func removeFromImplementedSteps(_ values: NSSet)

    
    @objc(addRemovedStepsObject:)
    @NSManaged public func addToRemovedSteps(_ value: RemovedStep)

    @objc(removeRemovedStepsObject:)
    @NSManaged public func removeFromRemovedSteps(_ value: RemovedStep)

    @objc(addRemovedSteps:)
    @NSManaged public func addToRemovedSteps(_ values: NSSet)

    @objc(removeRemovedSteps:)
    @NSManaged public func removeFromRemovedSteps(_ values: NSSet)
}

@objc(ImplementedStep)
public class ImplementedStep: NSManagedObject {
    
}

extension ImplementedStep {
    
    @nonobjc public class func implementedStepFetchRequest() -> NSFetchRequest<ImplementedStep> {
        return NSFetchRequest<ImplementedStep>(entityName: "ImplementedStep")
    }
    
    @NSManaged public var date: String
    @NSManaged public var step: MissionStep
    
    @discardableResult
    class func create(context: NSManagedObjectContext, step: MissionStep, date: Date) -> ImplementedStep? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "ImplementedStep", in: context) else { return nil }
        
        let item =  ImplementedStep(entity: entityDescription, insertInto: context)
        item.date = date.toDateString
        item.step = step
        
        return item
    }
}

@objc(RemovedStep)
public class RemovedStep: NSManagedObject {
    
}

extension RemovedStep {
    
    @nonobjc public class func removedStepFetchRequest() -> NSFetchRequest<RemovedStep> {
        return NSFetchRequest<RemovedStep>(entityName: "RemovedStep")
    }
    
    @NSManaged public var date: String
    @NSManaged public var step: MissionStep
    
    @discardableResult
    class func create(context: NSManagedObjectContext, step: MissionStep, date: Date) -> RemovedStep? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "RemovedStep", in: context) else { return nil }
        
        let item =  RemovedStep(entity: entityDescription, insertInto: context)
        item.date = date.toDateString
        item.step = step
        
        return item
    }
}
