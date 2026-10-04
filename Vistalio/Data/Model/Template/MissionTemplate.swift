//
//  MissionTemplate.swift
//  Vistalio
//
//  Created by Julia Konkova on 21.04.2026.
//

import UIKit
import CoreData

class MissionTemplatesList: Codable {
    let missions: [MissionTemplate]
}

class MissionTemplate: Codable {
    let id: Int
    let name: String
    let shortDescription: String
    let fullDescription: String
    let emotions: [String]
    let cover: String
    let maxHours: Int?
    let minAge: Int?
    var hiddenAt: Date?
}

class MissionContents: Codable {
    let blocks: [TemplateBlock]
    let reminderNotifications: [TemplateReminder]?
    let emotionNotifications: [TemplateReminder]?
    let showCompleted: Bool?
    let canCreateSteps: Bool?
    let skipRecommend: Bool?
    let autoAddFirstBlock: Bool?
    let reminderDays: Int?
    
    func findStep(id: Int) -> TemplateStep? {
        var i = 1
        for b in blocks {
            for s in b.steps {
                if i == id {
                    return s
                }
                i += 1
            }
        }
        return nil
    }
}

enum NextBlockAppearRule: String, Codable {
    case onDone
    case onDoneWithPreview
    case onNote
    case onNoteRespectPeriod
    case respectPeriod
    case onEmotion
    case onEmotionRespectPeriod
    case onAllStepsDone
}

enum StepDayStartPoint: String, Codable {
    case missionCreated
    case blockOpened
}

enum BlockDoneCriteria: String, Codable {
    case note
    case photo
    case video
    case photoOrVideo
    case geo
    case searchText
    case emotion
}

class TemplateBlock: Codable {
    let steps: [TemplateStep]
    let nextAppears: NextBlockAppearRule?
    let doneCriteria: [BlockDoneCriteria]?
    let photoMin: Int?
    let searchText: String?
    let textPlaceholder: String?
    let answerHint: String?
    let periodDays: Int?
    let nextBlockNotificationTitle: String?
    let nextBlockNotificationBody: String?
    let emotionGroup: String?
    let emotionsCountToOpenBlock: Int?
    let isSpecialBlock: Bool?
    let nextBlockHint: String?
    let stepDayStartPoint: StepDayStartPoint?
}

class TemplateStep: Codable {
    let name: String
    let description: String?
    let preview: Bool?
    var expanded: Bool?
    let editable: Bool?
    let noteTitle: String?
    let notes: [TemplateNote]?
    let frequency: StepFrequency?
    let days: [Int]?
    let time: String?
    
    var shortDescription: String? {
        return description?.replacingOccurrences(of: "\n\n", with: " ").replacingOccurrences(of: "\n", with: " ")
    }
    
    func getFullName(mission: MissionContents) -> String {
        if let time = time {
            if time.contains(":") {
                return "\(time) \(name)"
            } else {
                let parts = time.split(separator: "/")
                if parts.count == 2 {
                    let minutes = Int(parts[0])!
                    let stepId = Int(parts[1])!
                    if let s = mission.findStep(id: stepId), let dependencyTime = s.time {
                        let df = DateFormatter()
                        df.locale = Locale(identifier: "en_US_POSIX")
                        df.dateFormat = "HH:mm"
                        let date = df.date(from: dependencyTime)!
                        let resultDate = Calendar.current.date(byAdding: .minute, value: minutes, to: date)!
                        let resultTime = df.string(from: resultDate)
                        return "\(resultTime) \(name ?? "")"
                    }
                }
            }
        }
        return name ?? ""
    }
}

class TemplateNote: Codable {
    let name: String
    let description: String?
    let preview: Bool?
    let images: [String]?
    let audio: String?
    
    var shortDescription: String? {
        return description?.replacingOccurrences(of: "\n\n", with: " ").replacingOccurrences(of: "\n", with: " ")
    }
}

class TemplateReminder: Codable {
    let id: Int
    let title: String
    let body: String
}
