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
    let showCompleted: Bool?
    let canCreateSteps: Bool?
    let skipRecommend: Bool?
}

class BlocksList: Codable {
    let blocks: [TemplateBlock]
}

enum NextBlockAppearRule: String, Codable {
    case onDoneWithPreview
}

enum BlockDoneCriteria: String, Codable {
    case photo
    case video
    case geo
    case searchText
}

class TemplateBlock: Codable {
    let steps: [TemplateStep]
    let nextAppears: NextBlockAppearRule?
    let doneCriteria: [BlockDoneCriteria]?
    let photoMin: Int?
    let searchText: String?
}

class TemplateStep: Codable {
    let name: String
    let description: String?
    let preview: Bool?
    var expanded: Bool?
    let editable: Bool?
    let notes: [TemplateNote]?
    
    var shortDescription: String? {
        return description?.replacingOccurrences(of: "\n\n", with: " ").replacingOccurrences(of: "\n", with: " ")
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
