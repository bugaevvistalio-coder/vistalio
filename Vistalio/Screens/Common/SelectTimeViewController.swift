//
//  SelectTimeViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 05.10.2026.
//

import UIKit

class SelectTimeViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var time: String?
    var onTimeSelected: ((String) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let time = time {
            let parts = time.components(separatedBy: ":")
            
            let calendar = Calendar.current
            var components = DateComponents()
            components.hour = Int(parts[0])!
            components.minute = Int(parts[1])!

            if let targetDate = calendar.date(from: components) {
                datePicker.setDate(targetDate, animated: false)
            }
        }
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        setupBottomConstraint(saveButton)
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "HH:mm"
        onTimeSelected?(df.string(from: datePicker.date))
        dismiss(animated: true)
    }
    
    @IBAction func closeTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
