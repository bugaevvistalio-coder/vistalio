//
//  EditTimeViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 05.10.2026.
//

import UIKit

class EditTimeViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var timeControl: UIControl!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var saveButton: UIButton!
    
    var step: MissionStep!
    var onStepSaved: (() -> ())?
    
    private var time: String? {
        didSet {
            timeLabel.text = time
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        setupBottomConstraint(saveButton)
        
        time = step.formattedTime
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        timeControl.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.height - saveButton.frame.minY + 20, right: 0)
    }
    
    @IBAction func closeTapped() {
        dismiss(animated: true)
    }
    
    @IBAction func timeTapped(_ sender: AnyObject) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectTimeVC") as! SelectTimeViewController
        vc.time = time
        vc.onTimeSelected = { [unowned self] time in
            self.time = time
        }
        let bottom = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        presentBottomSheet(vc, height: 400 + bottom)
    }
    
    @IBAction func saveTapped(_ sender: AnyObject) {
        if let time = time, step.time != time {
            CoreDataStack.shared.performAndWait { [unowned self] context in
                self.step.time = time
            }
            NotificationCenter.default.post(name: .stepUpdated, object: nil)
            onStepSaved?()
            
            step.scheduleDailyNotifications(time: time, rescheduleExisting: true)
            step.block.mission.addedSteps.forEach {
                if let t = $0.time, t.hasSuffix("/\(step.id)"), let formattedTime = $0.formattedTime {
                    $0.scheduleDailyNotifications(time: formattedTime, rescheduleExisting: true)
                }
            }
        }
        dismiss(animated: true)
    }
}
