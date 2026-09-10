//
//  NotificationsViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 09.09.2026.
//

import UIKit

class NotificationsViewController: UIViewController {
    
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyNotificationsCircle: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
    private var todayNotifications = [AppNotification]()
    private var earlierNotifications = [AppNotification]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        emptyNotificationsCircle.setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 20, shadowOpacity: 0.22, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        
        navBar.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        navBar.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 30, shadowOpacity: 0.1)
        
        tableView.estimatedRowHeight = 72.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        
        updateNotifications()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onNotificationsUpdated(notification:)), name: .notificationsUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .notificationsUpdated, object: nil)
        
        var notifications = todayNotifications
        notifications.append(contentsOf: earlierNotifications)
        DispatchQueue.global().async {
            CoreDataStack.shared.performAndWait { context in
                notifications.forEach {
                    if !$0.isRead {
                        $0.isRead = true
                    }
                }
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .notificationsUpdated, object: nil)
            }
        }
    }
    
    private func updateNotifications() {
        todayNotifications.removeAll()
        earlierNotifications.removeAll()
        
        let notifications = MissionsHolder.shared.getNotifications()
        let now = Date()
        for (i, n) in notifications.enumerated() {
            if n.date!.isSameDay(now) {
                todayNotifications.append(n)
            } else {
                earlierNotifications.append(contentsOf: notifications.suffix(from: i))
                break
            }
        }
        emptyView.isHidden = !notifications.isEmpty
    }
    
    @IBAction func backTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func onNotificationsUpdated(notification: Notification) {
        DispatchQueue.main.async {
            self.updateNotifications()
            self.tableView.reloadData()
        }
    }
}

extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return todayNotifications.count
        }
        return earlierNotifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as! NotificationCell
        let notifications = (indexPath.section == 0 ? todayNotifications : earlierNotifications)
        cell.notification = notifications[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let notifications = (section == 0 ? todayNotifications : earlierNotifications)
        return notifications.isEmpty ? CGFloat.leastNormalMagnitude : 54
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let notifications = (section == 0 ? todayNotifications : earlierNotifications)
        if notifications.isEmpty {
            return nil
        }
        
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = section == 0 ? "Сегодня" : "Раннее"
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .black
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let notifications = (indexPath.section == 0 ? todayNotifications : earlierNotifications)
        let n = notifications[indexPath.row]
        if let mission = n.mission {
            openMission(mission, recommendedExpanded: true)
        }
    }
}
