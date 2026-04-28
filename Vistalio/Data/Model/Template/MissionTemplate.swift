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

enum MissionEmotion: String {
    case joy
    case nostalgia
    case recognition
    case passion
    case interest
    case hope
    case triumph
    case insolence
    case fury
    case discontent
    case anger
    case panic
    case annoyance
    case anxiety
    case worry
    case despair
    case apprehension
    case thoughtfulness
    case melancholy
    case boredom
    case peace
    case sadness
    case disgust
    
    var nameAndImage: (String, UIImage) {
        switch self {
        case .joy:
            return ("Радость", .joy)
        case .nostalgia:
            return ("Ностальгия", .nostalgia)
        case .recognition:
            return ("Признание", .recognition)
        case .passion:
            return ("Азарт", .passion)
        case .interest:
            return ("Интерес", .interest)
        case .hope:
            return ("Надежда", .hope)
        case .triumph:
            return ("Триумф", .triumph)
        case .insolence:
            return ("Дерзость", .insolence)
        case .fury:
            return ("Гнев", .fury)
        case .discontent:
            return ("Недовольство", .discontent)
        case .anger:
            return ("Злость", .anger)
        case .panic:
            return ("Паника", .panic)
        case .annoyance:
            return ("Досада", .annoyance)
        case .anxiety:
            return ("Беспокойство", .anxiety)
        case .worry:
            return ("Волнение", .worry)
        case .despair:
            return ("Отчаяние", .despair)
        case .apprehension:
            return ("Опасение", .apprehension)
        case .thoughtfulness:
            return ("Задумчивость", .thoughtfulness)
        case .melancholy:
            return ("Меланхолия", .melancholy)
        case .boredom:
            return ("Скука", .boredom)
        case .peace:
            return ("Умиротворение", .peace)
        case .sadness:
            return ("Грусть", .sadness)
        case .disgust:
            return ("Брезгливость", .disgust)
        }
    }
    
    var colors: ([UIColor], [UIColor], UIColor) {
        switch self {
        case .joy, .hope, .recognition, .passion, .peace:
            return ([UIColor(hex: "#FCF9F3"), UIColor(hex: "#FCF8EE"), UIColor(hex: "#FCF8EE")],
                    [UIColor(hex: "#FFFCF5"), UIColor(hex: "#FCF8EE"), UIColor(hex: "#FFFCF7"), UIColor(hex: "#FCF8EE")],
                    UIColor(hex: "#E5DDCB"))
        case .sadness, .thoughtfulness, .nostalgia, .melancholy, .boredom, .disgust:
            return ([UIColor(hex: "#F3F3FC"), UIColor(hex: "#EEEFFC"), UIColor(hex: "#EEEFFC")],
                    [UIColor(hex: "#F5F6FF"), UIColor(hex: "#EEEFFC"), UIColor(hex: "#F7F7FF"), UIColor(hex: "#EEEFFC")],
                    UIColor(hex: "#CBCDE5"))
        case .apprehension, .anxiety, .panic, .worry, .fury, .despair:
            return ([UIColor(hex: "#F3FCF7"), UIColor(hex: "#EEFCF5"), UIColor(hex: "#EEFCF5")],
                    [UIColor(hex: "#F5FFFA"), UIColor(hex: "#EEFCF5"), UIColor(hex: "#F7FFFB"), UIColor(hex: "#EEFCF5")],
                    UIColor(hex: "#CBE5D8"))
        case .anger, .discontent, .insolence, .triumph, .interest, .annoyance:
            return ([UIColor(hex: "#FCF4F3"), UIColor(hex: "#FCF0EE"), UIColor(hex: "#FCF0EE")],
                    [UIColor(hex: "#FFF6F5"), UIColor(hex: "#FCF0EE"), UIColor(hex: "#FFF8F7"), UIColor(hex: "#FCF0EE")],
                    UIColor(hex: "#E5CFCB"))
        }
    }
}

class StepsList: Codable {
    let blocks: [[TemplateStep]]
}

class TemplateStep: Codable {
    let name: String
    let description: String?
    let preview: Bool?
    var expanded: Bool?
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
