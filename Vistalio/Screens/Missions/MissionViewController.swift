//
//  MissionViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 06.04.2026.
//

import UIKit

class MissionViewController: UIViewController {
    
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var headerControl: UIControl!
    @IBOutlet weak var headerShadowView: UIView!
    @IBOutlet weak var headerControlHeight: NSLayoutConstraint!
    
    @IBOutlet weak var segmentedControl: SegmentedControl!
    @IBOutlet weak var addStepButton: UIButton!
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var aboutLabel: UILabel!
    
    @IBOutlet weak var topBgViewHeight: NSLayoutConstraint!
    @IBOutlet weak var missionInfoTop: NSLayoutConstraint!
    @IBOutlet weak var missionInfoCenterY: NSLayoutConstraint!
    
    var mission: Mission!
    
    private var hasNavBarShadow = false
    private var isHeaderExpanded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        addStepButton.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18)
        
        navBar.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        navBar.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 30, shadowOpacity: 0)
        
        headerControl.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        headerShadowView.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 30, shadowOpacity: 0.1)
        
        segmentedControl.tabs = [SegmentedTabData(text: "Шаги", image: .steps), SegmentedTabData(text: "Заметки", image: .notes)]
        
        displayMission()
        
        print("Steps \(mission.steps?.count ?? 0)")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutHeader()
        addStepButton.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18)
        
        if !isHeaderExpanded {
            
            let nameLines = titleLabel.calculateMaxLines()
            
            var aboutLines = 0
            if nameLines == 1 {
                aboutLines = 3
            } else if nameLines == 2 {
                aboutLines = 1
            }
            if aboutLines == 0 || (mission.about?.isEmpty ?? true) {
                aboutLabel.isHidden = true
            } else {
                aboutLabel.numberOfLines = aboutLines
                aboutLabel.isHidden = false
            }
            
            aboutLabel.invalidateIntrinsicContentSize()
            aboutLabel.superview!.layoutIfNeeded()
        }
    }
    
    private func displayMission() {
        coverImageView.displayMissionCover(mission: mission)
        titleLabel.text = mission.name
        aboutLabel.text = mission.about
    }
    
    @IBAction func backTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func headerTapped(_ sender: Any) {
        if isHeaderExpanded {
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.headerControlHeight.constant = 156
                self?.tableView.layoutHeader()
            } completion: { [weak self] _ in
                self?.isHeaderExpanded = false
                self?.view.setNeedsLayout()
                self?.view.layoutIfNeeded()
            }
        } else {
            let width = titleLabel.frame.width
            var labelsHeight = mission.name!.height(withWidth: width, font: titleLabel.font)
            if let about = mission.about, !about.isEmpty {
                labelsHeight += 4
                labelsHeight += about.height(withWidth: width, font: aboutLabel.font)
            }
            
            if labelsHeight > titleLabel.superview!.frame.height + 1 {
                isHeaderExpanded = true
                titleLabel.numberOfLines = 0
                aboutLabel.numberOfLines = 0
                
                missionInfoTop.constant = titleLabel.superview!.frame.minY
                missionInfoCenterY.priority = .defaultLow
                missionInfoTop.priority = .defaultHigh
                
                UIView.animate(withDuration: 0.2) { [weak self] in
                    self?.headerControlHeight.constant = 92 + labelsHeight
                    self?.tableView.layoutHeader()
                }
            }
        }
    }
    
    @IBAction func menuTapped(_ sender: Any) {
        let mainVC = (UIApplication.shared.keyWindow?.rootViewController as! MainViewController)
        let menuUnderlayControl =  mainVC.addMenuUnderlayControl(color: .clear)
        
        let menuView = MenuView()
        var items = [MenuItemData]()
        items.append(MenuItemData(text: "Изменить", image: .edit, type: .normal, action: { [unowned self] in
            menuUnderlayControl.removeFromSuperview()
            openEditMission(mission) { [unowned self] mission in
                menuUnderlayControl.removeFromSuperview()
                self.mission = mission
                self.displayMission()
            }
        }))
        if mission.templateId > 0 {
            items.append(MenuItemData(text: "Поделиться", image: .share, type: .normal, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                openShareMission(mission)
            }))
        }
        items.append(MenuItemData(text: mission.archived ? "Убрать из архива" : "В архив", image: mission.archived ? .unarchive : .archive, type: .normal, action: { [unowned self] in
            menuUnderlayControl.removeFromSuperview()
            openArchiveMission(mission)
        }))
        items.append(MenuItemData(text: "Удалить", image: .trash, type: .red, action: { [unowned self] in
            menuUnderlayControl.removeFromSuperview()
            openDeleteMission(mission)
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

extension MissionViewController: UITableViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView.contentOffset.y < 0 {
            topBgViewHeight.constant = -scrollView.contentOffset.y
        } else {
            topBgViewHeight.constant = 0
        }
        
        if scrollView.contentOffset.y > headerControl.frame.maxY {
            if !hasNavBarShadow {
                hasNavBarShadow = true
                navBar.layer.shadowOpacity = 0.1
            }
        } else {
            if hasNavBarShadow {
                hasNavBarShadow = false
                navBar.layer.shadowOpacity = 0
            }
        }
    }
}
