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
    
    @IBOutlet weak var missionAddedView: UIView!
    
    @IBOutlet weak var menuUnderlayControl: UIControl!
    var menuView: MenuView?
    
    var mission: Mission!
    var isNew = false
    
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
        
        if isNew {
            missionAddedView.setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 20, shadowOpacity: 0.22)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.missionAddedView.isHidden = true
            }
        } else {
            missionAddedView.isHidden = true
        }
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
        if let path = mission.photoPath {
            coverImageView.loadFromPath(path) { [weak self] in
                return self?.mission.photoPath
            }
        } else if let categoryName = mission.category, let category = MissionCategory(rawValue: categoryName) {
            coverImageView.image = UIImage(named: category.coverName)
        }
        
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
        menuView = MenuView()
        menuView!.items = [
            MenuItemData(text: "Изменить", image: .edit, type: .normal, action: {
                
            }),
            MenuItemData(text: "Поделиться", image: .share, type: .normal, action: {
                
            }),
            MenuItemData(text: "В архив", image: .archive, type: .normal, action: {
                
            }),
            MenuItemData(text: "Удалить", image: .trash, type: .red, action: {
                
            })
        ]
        menuView!.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(menuView!)
        
        let constraints = [
            menuView!.topAnchor.constraint(equalTo: menuButton.bottomAnchor, constant: 0),
            menuView!.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraints)
        
        menuUnderlayControl.isHidden = false
    }
    
    @IBAction func menuUnderlayTapped(_ sender: Any) {
        menuView?.removeFromSuperview()
        menuView = nil
        menuUnderlayControl.isHidden = true
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
