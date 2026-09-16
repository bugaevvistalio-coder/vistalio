//
//  MissionsHolder.swift
//  Vistalio
//
//  Created by Julia Konkova on 05.04.2026.
//

import UIKit
import CoreData

class MissionsHolder {
    
    static let shared = MissionsHolder()
    
    private(set) var templates = [MissionTemplate]()
    var openTemplateId: Int?
    
    func createMission(name: String, about: String?, coverPath: String?, category: MissionCategory?, onCreated: (Mission) -> ()) {
        var mission: Mission? = nil
        CoreDataStack.shared.performAndWait { context in
            mission = Mission.create(context: context, name: name, coverPath: coverPath, about: about, category: category?.rawValue)
        }
        if let mission = mission {
            onCreated(mission)
        }
    }
    
    func updateMission(mission: Mission, name: String, about: String?, coverPath: String?, category: MissionCategory?, onUpdated: (Mission) -> ()) {
        CoreDataStack.shared.performAndWait { context in
            mission.name = name
            mission.about = about
            if let coverPath = coverPath {
                mission.category = nil
                mission.photoPath = coverPath
            } else if let category = category {
                mission.photoPath = nil
                mission.category = category.rawValue
            }
        }
        onUpdated(mission)
    }
    
    func getMyMissions() -> [Mission] {
        let missionsRequest = Mission.missionFetchRequest()
        missionsRequest.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: false), NSSortDescriptor(key: "creationDate", ascending: false)]
        do {
            return try CoreDataStack.shared.mainContext.fetch(missionsRequest)
        } catch {
            print("Failed to retrive missions and folders")
        }
        return [Mission]()
    }
    
    func getCovers() -> [Cover] {
        let coversRequest = Cover.coverFetchRequest()
        coversRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        do {
            return try CoreDataStack.shared.mainContext.fetch(coversRequest)
        } catch {
            print("Failed to retrive missions and folders")
        }
        return [Cover]()
    }
    
    func saveCover(path: String) -> Cover? {
        var cover: Cover? = nil
        CoreDataStack.shared.performAndWait { context in
            cover = Cover.create(context: context, path: path)
        }
        return cover
    }
    
    func loadTemplates() {
        if templates.isEmpty, let path = Bundle.main.path(forResource: "missions_list", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                let templatesData = try decoder.decode(MissionTemplatesList.self, from: data)
                self.templates = templatesData.missions
                
                let request = HiddenMissionTemplate.hiddenMissionTemplateFetchRequest()
                let hiddenTemplates = try CoreDataStack.shared.backgroundContext.fetch(request)
                self.templates.forEach { t in
                    if let hidden = hiddenTemplates.first(where: { $0.templateId == t.id }) {
                        t.hiddenAt = hidden.date
                    }
                }
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .templatesUpdated, object: nil)
                    if let templateId = self.openTemplateId {
                        self.openTemplateId = nil
                        (UIApplication.shared.delegate as! AppDelegate).openTemplate(id: templateId)
                    }
                }
                
            } catch let error as NSError {
                print(error)
            }
        }
    }

    func openNextBlocks() {
        var blocks = [StepsBlock]()
        CoreDataStack.shared.performAndWait { context in
            let blocksRequest = StepsBlock.blockFetchRequest()
            blocksRequest.predicate = NSPredicate(format: "checkPeriod == YES AND mission.archivedAt == nil")
            do {
                blocks = try context.fetch(blocksRequest)
            } catch {
                print("Failed to retrive missions and folders")
            }
        }
        
        let now = Date()
        let calendar = Calendar.current
        blocks.forEach {
            print("Check block period")
            if let recommendedAt = $0.recommendedAt {
                let nextBlockDate = calendar.date(byAdding: .minute, value: Int($0.periodDays), to: recommendedAt)!
                if nextBlockDate <= Date() {
                    $0.unlockNextBlock(date: nextBlockDate)
                }
            }
        }
    }
    
    func getNotificationBlock(notificationId: String) -> StepsBlock? {
        let blocksRequest = StepsBlock.blockFetchRequest()
        blocksRequest.predicate = NSPredicate(format: "notificationId == %@", notificationId)
        return (try? CoreDataStack.shared.context.fetch(blocksRequest))?.first
    }
    
    func getNotificationMission(notificationId: String) -> Mission? {
        let request = Mission.missionFetchRequest()
        request.predicate = NSPredicate(format: "reminderNotificationRequestId == %@", notificationId)
        return (try? CoreDataStack.shared.context.fetch(request))?.first
    }
    
    @discardableResult func getNotesMission(context: NSManagedObjectContext) -> Mission? {
        var mission = fetchNotesMission(context: context)
        if mission == nil {
            mission = Mission.create(context: context, name: "Общие заметки", coverPath: nil, about: "ⓘ Сюда попадают заметки, не привязанные к миссии", category: MissionCategory.notes.rawValue)
            mission?.creationDate = Date(timeIntervalSince1970: 0)
        }
        return mission
    }
    
    private func fetchNotesMission(context: NSManagedObjectContext) -> Mission? {
        let missionsRequest = Mission.missionFetchRequest()
        missionsRequest.predicate = NSPredicate(format: "category == %@", MissionCategory.notes.rawValue)
        do {
            return try context.fetch(missionsRequest).first
        } catch {
            print("Failed to retrive missions and folders")
        }
        return nil
    }
    
    func getNotifications() -> [AppNotification] {
        let request = AppNotification.appNotificationFetchRequest()
        request.predicate = NSPredicate(format: "mission.archivedAt == nil")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        do {
            return try CoreDataStack.shared.mainContext.fetch(request)
        } catch {
            print("Failed to retrive missions and folders")
        }
        return [AppNotification]()
    }
    
    func scheduleReminderNotificationOnStepImplemented(mission: Mission, date: Date = Date()) {
        print("Reminder \(mission.reminderNotificationRequestId), \(mission.reminders?.count ?? 0)")
        guard let reminders = mission.remindersSorted, reminders.count > 0, let requestId = mission.reminderNotificationRequestId else {
            return
        }
        let lastNotificationId = mission.reminderNotificationId
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            
            var reminder: Reminder?
            
            if let _ = requests.first(where: { $0.identifier == requestId }) {
                reminder = reminders.first { $0.id == lastNotificationId }
            } else {
                reminder = reminders.first { $0.id > lastNotificationId } ?? reminders.first
            }
            
            if let reminder = reminder {
                let calendar = Calendar.current
                var triggerDate = calendar.date(byAdding: .hour, value: 2, to: date)!
                if triggerDate < Date() {
                    triggerDate = Date()
                    addNotification(title: reminder.title ?? "", body: reminder.body ?? "", notificationId: requestId, userInfo: ["isReminder": true])
                } else {
                    print("Scheduled at trigger date \(triggerDate)")
                    let components = calendar.dateComponents([.day, .month, .year, .hour, .minute, .second], from: triggerDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    addNotification(title: reminder.title ?? "", body: reminder.body ?? "", notificationId: requestId, userInfo: ["isReminder": true], trigger: trigger)
                }
                
                CoreDataStack.shared.performAndWait { context in
                    let m = context.object(with: mission.objectID) as! Mission
                    m.reminderNotificationId = reminder.id
                    m.lastReminderAt = triggerDate
                }
            }
        }
    }
    
    func scheduleReminders() {
        
        let missionsRequest = Mission.missionFetchRequest()
        missionsRequest.predicate = NSPredicate(format: "lastReminderAt != nil AND archivedAt == nil")
        let missions = (try? CoreDataStack.shared.mainContext.fetch(missionsRequest)) ?? []

        print("Scheduled? Missions count \(missions.count)")
        let now = Date()
        
        missions.forEach {
            if $0.lastReminderAt! < now {
                scheduleReminderNotificationOnStepImplemented(mission: $0, date: $0.lastReminderAt!)
            }
        }
    }
}
