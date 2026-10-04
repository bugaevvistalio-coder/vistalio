//
//  NotificationCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 09.09.2026.
//

import UIKit

class NotificationCell: UITableViewCell {
    
    @IBOutlet weak var notificationImageView: UIImageView!
    @IBOutlet weak var notificationTitleLabel: UILabel!
    @IBOutlet weak var notificationTextLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var badgeView: UIView!
    
    var notification: AppNotification! {
        didSet {
            notificationTitleLabel.text = notification.title
            notificationTextLabel.text = notification.text
            badgeView.isHidden = notification.isRead
            
            if let mission = notification.mission {
                if oldValue?.mission?.photoPath != mission.photoPath || oldValue?.mission?.category != mission.category {
                    notificationImageView.displayMissionCover(mission: mission)
                }
            }
            
            let df = DateFormatter()
            if notification.date!.isSameDay(Date()) {
                df.dateFormat = "H:mm"
                timeLabel.text = df.string(from: notification.date!)
            } else if notification.date!.isSameDay(Date().addingTimeInterval(-24 * 60 * 60)) {
                df.dateFormat = "d MMM"
                timeLabel.text = "Вчера\n\(df.string(from: notification.date!))"
            } else {
                df.dateFormat = "d MMM\nyyyy"
                timeLabel.text = df.string(from: notification.date!)
            }
        }
    }
}
