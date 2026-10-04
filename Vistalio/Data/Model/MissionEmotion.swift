//
//  MissionEmotion.swift
//  
//
//  Created by Julia Konkova on 04.07.2026.
//

import UIKit
import CoreData

enum EmotionGroup: String, CaseIterable {
    case joy
    case sadness
    case fear
    case anger
    
    var emotions: [MissionEmotion] {
        switch self {
        case .joy:
            return [.joy, .calmness, .hope, .recognition, .passion, .peace, .admiration, .love]
        case .sadness:
            return [.sadness, .thoughtfulness, .nostalgia, .disappointment, .yearning, .melancholy, .boredom, .disgust, .grief]
        case .fear:
            return [.fear, .apprehension, .anxiety, .panic, .worry, .despair, .neutral, .shock]
        case .anger:
            return [.anger, .irritation, .discontent, .insolence, .triumph, .resentment, .interest, .annoyance, .fury]
        }
    }
}

enum MissionEmotion: String, CaseIterable {
    case joy
    case calmness
    case hope
    case recognition
    case passion
    case peace
    case admiration
    case love
    
    case sadness
    case thoughtfulness
    case nostalgia
    case disappointment
    case yearning
    case melancholy
    case boredom
    case disgust
    case grief
    
    case fear
    case apprehension
    case anxiety
    case panic
    case worry
    case despair
    case neutral
    case shock
    
    case anger
    case irritation
    case discontent
    case insolence
    case triumph
    case resentment
    case interest
    case annoyance
    case fury
    
    var nameAndImage: (String, UIImage) {
        switch self {
        case .joy:
            return ("Радость", .joy)
        case .calmness:
            return ("Спокойствие", .calmness)
        case .hope:
            return ("Надежда", .hope)
        case .recognition:
            return ("Благодарность", .recognition)
        case .passion:
            return ("Азарт", .passion)
        case .peace:
            return ("Умиротворение", .peace)
        case .admiration:
            return ("Восхищение", .admiration)
        case .love:
            return ("Любовь", .love)
            
        case .sadness:
            return ("Грусть", .sadness)
        case .thoughtfulness:
            return ("Задумчивость", .thoughtfulness)
        case .nostalgia:
            return ("Ностальгия", .nostalgia)
        case .disappointment:
            return ("Разочарование", .disappointment)
        case .yearning:
            return("Тоска", .yearning)
        case .melancholy:
            return ("Меланхолия", .melancholy)
        case .boredom:
            return ("Скука", .boredom)
        case .disgust:
            return ("Брезгливость", .disgust)
        case .grief:
            return ("Горе", .grief)
            
        case .fear:
            return ("Страх", .fear)
        case .apprehension:
            return ("Опасение", .apprehension)
        case .anxiety:
            return ("Беспокойство", .anxiety)
        case .panic:
            return ("Паника", .panic)
        case .worry:
            return ("Волнение", .worry)
        case .despair:
            return ("Отчаяние", .despair)
        case .neutral:
            return ("Нейтрально", .neutral)
        case .shock:
            return("Шок", .shock)
            
        case .anger:
            return ("Злость", .anger)
        case .irritation:
            return ("Раздражение", .irritation)
        case .discontent:
            return ("Недовольство", .discontent)
        case .insolence:
            return ("Дерзость", .insolence)
        case .triumph:
            return ("Триумф", .triumph)
        case .resentment:
            return ("Обида", .resentment)
        case .interest:
            return ("Интерес", .interest)
        case .annoyance:
            return ("Досада", .annoyance)
        case .fury:
            return ("Гнев", .fury)
        }
    }
    
    var group: EmotionGroup {
        if EmotionGroup.joy.emotions.contains(self) {
            return .joy
        }
        if EmotionGroup.sadness.emotions.contains(self) {
            return .sadness
        }
        if EmotionGroup.fear.emotions.contains(self) {
            return .fear
        }
        return .anger
    }
    
    var colors: ([UIColor], [UIColor], UIColor) {
        switch group {
        case .joy:
            return ([UIColor(hex: "#FCF9F3"), UIColor(hex: "#FCF8EE"), UIColor(hex: "#FCF8EE")],
                    [UIColor(hex: "#FFFCF5"), UIColor(hex: "#FCF8EE"), UIColor(hex: "#FFFCF7"), UIColor(hex: "#FCF8EE")],
                    UIColor(hex: "#E5DDCB"))
        case .sadness:
            return ([UIColor(hex: "#F3F3FC"), UIColor(hex: "#EEEFFC"), UIColor(hex: "#EEEFFC")],
                    [UIColor(hex: "#F5F6FF"), UIColor(hex: "#EEEFFC"), UIColor(hex: "#F7F7FF"), UIColor(hex: "#EEEFFC")],
                    UIColor(hex: "#CBCDE5"))
        case .fear:
            return ([UIColor(hex: "#F3FCF7"), UIColor(hex: "#EEFCF5"), UIColor(hex: "#EEFCF5")],
                    [UIColor(hex: "#F5FFFA"), UIColor(hex: "#EEFCF5"), UIColor(hex: "#F7FFFB"), UIColor(hex: "#EEFCF5")],
                    UIColor(hex: "#CBE5D8"))
        case .anger:
            return ([UIColor(hex: "#FCF4F3"), UIColor(hex: "#FCF0EE"), UIColor(hex: "#FCF0EE")],
                    [UIColor(hex: "#FFF6F5"), UIColor(hex: "#FCF0EE"), UIColor(hex: "#FFF8F7"), UIColor(hex: "#FCF0EE")],
                    UIColor(hex: "#E5CFCB"))
        }
    }
}

@objc(SelectedEmotion)
public class SelectedEmotion: NSManagedObject {
    
}

extension SelectedEmotion {
    
    @nonobjc public class func selectedEmotionFetchRequest() -> NSFetchRequest<SelectedEmotion> {
        return NSFetchRequest<SelectedEmotion>(entityName: "SelectedEmotion")
    }
    
    @NSManaged public var emotion: String
    @NSManaged public var group: String
    @NSManaged public var date: Date
    @NSManaged public var auto: Bool
    
    @discardableResult
    class func create(context: NSManagedObjectContext, emotion: MissionEmotion, auto: Bool) -> SelectedEmotion? {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "SelectedEmotion", in: context) else { return nil }
        
        let e =  SelectedEmotion(entity: entityDescription, insertInto: context)
        e.emotion = emotion.rawValue
        e.group = emotion.group.rawValue
        e.date = Date()
        e.auto = auto
        return e
    }
}
