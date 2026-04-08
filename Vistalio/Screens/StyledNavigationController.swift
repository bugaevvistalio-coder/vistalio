//
//  CreateMissionNavigationController.swift
//  Vistalio
//
//  Created by Julia Konkova on 28.03.2026.
//

import UIKit

class StyledNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let sheet = self.sheetPresentationController {
            sheet.preferredCornerRadius = 36
        }
    }
}
