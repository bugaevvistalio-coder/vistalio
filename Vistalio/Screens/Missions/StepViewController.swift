//
//  StepViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 09.06.2026.
//

import UIKit

class StepViewController: UIViewController {
    
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    
    var step: MissionStep!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
    }
    
    @IBAction func backTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func menuTapped(_ sender: Any) {
        let mainVC = (UIApplication.shared.keyWindow?.rootViewController as! MainViewController)
        let menuUnderlayControl =  mainVC.addMenuUnderlayControl(color: .clear)
        
        let menuView = MenuView()
        var items = [MenuItemData]()
        items.append(MenuItemData(text: "Изменить", image: .edit, type: .normal, action: { [unowned self] in
            menuUnderlayControl.removeFromSuperview()
            
        }))
        items.append(MenuItemData(text: "Переместить", image: .target, type: .normal, action: { [unowned self] in
            menuUnderlayControl.removeFromSuperview()
        }))
        items.append(MenuItemData(text: "Удалить", image: .trash, type: .red, action: { [unowned self] in
            menuUnderlayControl.removeFromSuperview()
        }))
        menuView.items = items
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(menuView)
        
        let constraints = [
            menuView.topAnchor.constraint(equalTo: menuButton.bottomAnchor, constant: 0),
            menuView.rightAnchor.constraint(equalTo: menuUnderlayControl.rightAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraints)
        
        menuView.setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 30, shadowOpacity: 0.22)
    }
}
