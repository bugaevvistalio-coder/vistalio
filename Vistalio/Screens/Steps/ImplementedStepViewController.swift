//
//  ImplementedStepViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 28.08.2026.
//

import UIKit

class ImplementedStepViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var nextStepLabel: UILabel?
    @IBOutlet weak var roundedView: UIView?
    
    @IBOutlet weak var addNoteControl: UIControl?
    @IBOutlet weak var addNoteInnerView: UIView?
    @IBOutlet weak var noteLabel: UILabel?
    
    var step: MissionStep?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        roundedView?.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.09)
        
        addNoteControl?.setShadow(offset: CGSize(width: 0, height: 0), radius: 4, cornerRadius: 16, shadowOpacity: 0.05)
        
        if let noteLabel = noteLabel {
            let width = "Заметка".width(withHeight: 26, font: noteLabel.font) + 32
            addNoteInnerView?.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 13, fixedBounds: CGRect(x: 0, y: 0, width: width, height: 26))
        }
        
        nextStepLabel?.text = step?.name
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        let step = step!
        dismiss(animated: false) {
            if let nc = UIApplication.topViewController()?.navigationController {
                let sb = UIStoryboard(name: "Missions", bundle: nil)
                var controllers = [UIViewController]()
                controllers.append(nc.viewControllers.first!)
                
                let missionVC = sb.instantiateViewController(withIdentifier: "MissionVC") as! MissionViewController
                missionVC.mission = step.block.mission
                controllers.append(missionVC)
                
                let stepVC = sb.instantiateViewController(withIdentifier: "StepVC") as! StepViewController
                stepVC.step = step
                stepVC.date = Date()
                controllers.append(stepVC)
                
                nc.setViewControllers(controllers, animated: true)
            }
        }
    }
}
