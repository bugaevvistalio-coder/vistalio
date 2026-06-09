//
//  ViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 20.03.2026.
//

import UIKit

class MainViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var tabBar: UIView!
    
    @IBOutlet weak var myDayTab: CustomTabItem!
    @IBOutlet weak var missionsTab: CustomTabItem!
    @IBOutlet weak var mapTab: CustomTabItem!
    @IBOutlet weak var meTab: CustomTabItem!
    
    @IBOutlet weak var tabBarBottom: NSLayoutConstraint!
    
    @IBOutlet weak var notificationsStackView: UIStackView!
    
    var tabs = [CustomTabItem]()
    var controllers = [UIViewController]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.layer.cornerRadius = 30
        tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        tabBar.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 30, shadowOpacity: 0.1)
        
        let bottom = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        if bottom == 0 {
            tabBarBottom.constant = 12
        }
        
        myDayTab.isTabSelected = true
        tabs = [myDayTab, missionsTab, mapTab, meTab]
        
        buildControllers()
    }
    
    private func buildControllers() {
        let storyboards = ["MyDay", "Missions", "Map", "Me"]
        let ids = ["MyDayTabVC", "MissionsTabNC", "MapTabVC", "MeTabVC"]
        for i in 0..<4 {
            let sb = UIStoryboard(name: storyboards[i], bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: ids[i])
            controllers.append(vc)
        }
    }

    @IBAction func tabTapped(_ sender: Any) {
        for (i, tab) in tabs.enumerated() {
            let control = (sender as! UIControl)
            let wasSelected = tab.isTabSelected
            tab.isTabSelected = (i == control.tag)
            if i == control.tag && !wasSelected {
                if let currentChild = children.first {
                    currentChild.view.removeFromSuperview()
                    currentChild.willMove(toParent: nil)
                    currentChild.removeFromParent()
                }
                
                let childVC = controllers[i]
                addChild(childVC)

                containerView.addSubview(childVC.view)
                childVC.view.frame = containerView.bounds
                childVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

                childVC.didMove(toParent: self)
            }
        }
    }
    
    func addNotification(text: String, secondaryText: String? = nil, onTapped: (() -> ())? = nil) {
        notificationsStackView.addNotification(text: text, secondaryText: secondaryText, onTapped: onTapped)
    }
}

