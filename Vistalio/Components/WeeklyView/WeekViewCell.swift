//
//  WeekViewCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 14.08.2026.
//

import UIKit

class WeekViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var roundedView: UIView!
    @IBOutlet private weak var weekdayLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    
    @IBOutlet private weak var emotionOuterView: UIView!
    @IBOutlet private weak var emotionHeight: NSLayoutConstraint!
    @IBOutlet private weak var emotionImageView: UIImageView!
    @IBOutlet weak var emotionBorderView: UIView!
    @IBOutlet weak var emotionBgView: UIView!
    @IBOutlet weak var emotionsCounterLabel: UILabel!
    
    var onDateSelected: ((Date) -> ())?
    var onEmotionTapped: ((Date, MissionEmotion?) -> ())?
    
    private let formatter = DateFormatter()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        roundedView.setShadow(offset: CGSize(width: 0, height: 0), radius: 3, cornerRadius: 21, shadowOpacity: 0.09, bounds: CGRect(x: 0, y: 0, width: 42, height: 52))
        roundedView.layer.borderColor = UIColor.textGrey30.cgColor
        
        formatter.locale = Locale(identifier: "ru_RU")
        
        emotionHeight.constant = 52
        emotionBorderView.setShadow(offset: CGSize(width: 0, height: 1.24), radius: 1.24, cornerRadius: 14, shadowOpacity: 0)
    }
    
    var day: Date! {
        didSet {
            formatter.dateFormat = "d"
            dateLabel.text = formatter.string(from: day)

            formatter.dateFormat = "EEE"
            weekdayLabel.text = formatter.string(from: day)
            
            roundedView.layer.borderWidth = day.isSameDay(Date()) ? 2 : 0
        }
    }
    
    var isSelectedDate: Bool = false {
        didSet {
            roundedView.backgroundColor = isSelectedDate ? .highlightBlue : .white
            weekdayLabel.textColor = isSelectedDate ? .white.withAlphaComponent(0.75) : .textGrey60
            dateLabel.textColor = isSelectedDate ? .white : .black
        }
    }
    
    var emotions: [MissionNoteEmotion]? {
        didSet {
            emotionHeight.constant = 84
            mainEmotion = getEmotion()
            
            if let emotion = mainEmotion {
                emotionImageView.image = emotion.nameAndImage.1
                
                let colors = emotion.colors
                emotionBgView.setGradientLayer(colors: colors.0, startPoint: CGPoint(x: 0.5, y: 0.0), endPoint: CGPoint(x: 0.5, y: 1.0), cornerRadius: 15, bounds: CGRect(x: 0, y: 0, width: 30, height: 78))
                emotionBorderView.setGradientLayer(colors: colors.1, startPoint: CGPoint(x: 0.5, y: 0.0), endPoint: CGPoint(x: 0.5, y: 1.0), cornerRadius: 16, bounds: CGRect(x: 0, y: 0, width: 32, height: 80))
                emotionBorderView.layer.shadowOpacity = 0.12
                
                emotionOuterView.layer.borderColor = colors.2.cgColor
                emotionOuterView.layer.borderWidth = 2
                
                emotionsCounterLabel.superview?.isHidden = (emotions!.count <= 1)
                emotionsCounterLabel.text = "\(emotions!.count)"
            } else {
                emotionImageView.image = day <= Date().startOfDay ? .noEmotion : nil
                
                emotionBgView.removeGradientLayer()
                emotionBorderView.removeGradientLayer()
                emotionBorderView.layer.shadowOpacity = 0
                emotionOuterView.layer.borderWidth = 0
                
                emotionsCounterLabel.superview?.isHidden = true
            }
        }
    }
    
    private var mainEmotion: MissionEmotion?
    
    private func getEmotion() -> MissionEmotion? {
        guard let emotions = emotions, !emotions.isEmpty else {
            return nil
        }
        
        var grouped = Dictionary(grouping: emotions, by: { $0.emotion })
        guard let maxCount = grouped.values.map({ $0.count }).max() else {
            return nil
        }
        
        let leadEmotions = grouped.filter { $0.value.count == maxCount }
        if leadEmotions.count == 1 {
            let rawEmotion = leadEmotions.first!.value.first!.emotion
            return MissionEmotion(rawValue: rawEmotion)
        }
        
        grouped = Dictionary(grouping: emotions, by: { MissionEmotion(rawValue: $0.emotion)!.group.rawValue } )
        guard let maxCount = grouped.values.map({ $0.count }).max() else {
            return nil
        }
        let leadGroups = grouped.filter { $0.value.count == maxCount }
        let leadGroupsEmotions = leadGroups.flatMap { $0.value }.sorted { $0.date > $1.date }
        
        if let e = leadGroupsEmotions.first {
            return MissionEmotion(rawValue: e.emotion)
        }
        return nil
    }
    
    @IBAction func tapped(_ sender: Any) {
        onDateSelected?(day)
    }
    
    @IBAction func emotionTapped(_ sender: Any) {
        if day <= Date().startOfDay {
            onEmotionTapped?(day, mainEmotion)
        }
    }
}
