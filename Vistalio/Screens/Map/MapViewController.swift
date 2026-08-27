//
//  MapViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 25.08.2026.
//

import UIKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var placeholderImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIScreen.main.bounds.height <= 600 {
            let h = NSLayoutConstraint(item: placeholderImageView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 250)
            NSLayoutConstraint.activate([h])
        }
    }
    
    @IBAction func createNoteTapped(_ sender: Any) {
        let sb = UIStoryboard(name: "Missions", bundle: nil)
        let nc = sb.instantiateViewController(withIdentifier: "SelectEmotionNC") as! UINavigationController
        let vc = nc.viewControllers.first as! SelectEmotionViewController
        vc.isNoteCreation = true
        presentFullScreen(nc)
    }
}
