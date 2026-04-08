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
    
    func getMissions() -> [Mission] {
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
