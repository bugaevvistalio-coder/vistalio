//
//  SelectDateViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 03.07.2026.
//

import UIKit

class SelectDateViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var popupTitle: String!
    var onDateSelected: ((Date) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = popupTitle
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        setupBottomConstraint(saveButton)
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        onDateSelected?(datePicker.date)
        dismiss(animated: true)
    }
    
    @IBAction func closeTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
