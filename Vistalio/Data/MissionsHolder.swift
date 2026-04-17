//
//  MissionsHolder.swift
//  Vistalio
//
//  Created by Julia Konkova on 05.04.2026.
//

import UIKit

class MissionsHolder {
    
    static let shared = MissionsHolder()
    
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
        missionsRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        do {
            return try CoreDataStack.shared.mainContext.fetch(missionsRequest)
        } catch {
            print("Failed to retrive missions and folders")
        }
        return [Mission]()
    }
}
