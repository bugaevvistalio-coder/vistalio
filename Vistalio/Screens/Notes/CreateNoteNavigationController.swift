//
//  CreateNoteNavigationController.swift
//  Vistalio
//
//  Created by Julia Konkova on 30.07.2026.
//

import UIKit

class CreateNoteNavigationController: UINavigationController {
    
    var emotions = [MissionEmotion]()
    var date: Date?
    var noteTitle: String?
    var body: String?
    var mediaHolder = MediaHolder()
    
    var stepDate: Date?
    var selectedMission: Mission?
    var selectedStep: MissionStep?
    
    deinit {
        mediaHolder.reset()
    }
}
