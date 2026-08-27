//
//  NoMissionsCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 22.08.2026.
//

import UIKit

class NoMissionsCell: UITableViewCell {
    
    @IBOutlet weak var missionImageView1: UIImageView!
    @IBOutlet weak var missionTitleLabel1: UILabel!
    @IBOutlet weak var missionTextLabel1: UILabel!
    
    @IBOutlet weak var missionImageView2: UIImageView!
    @IBOutlet weak var missionTitleLabel2: UILabel!
    @IBOutlet weak var missionTextLabel2: UILabel!
    
    @IBOutlet weak var addMissionInnerView: UIView!
    
    private var updated = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let screenW = UIScreen.main.bounds.width
        addMissionInnerView.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18, fixedBounds: CGRect(x: 0, y: 0, width: (screenW  - 24)/2 - 24, height: 196))
    }
    
    func update() {
        
        if updated {
            return
        }
        
        let templates = MissionsHolder.shared.templates
        guard let t1 = templates.first(where: { $0.id == 9 }), let t2 = templates.first(where: { $0.id == 12 }) else {
            return
        }
        
        if let url = URL(string: t1.cover) {
            missionImageView1.loadFromUrl(url) { return t1.cover }
        }
        missionTitleLabel1.text = t1.name
        missionTextLabel1.text = t1.shortDescription
        
        if let url = URL(string: t2.cover) {
            missionImageView2.loadFromUrl(url) { return t2.cover }
        }
        missionTitleLabel2.text = t2.name
        missionTextLabel2.text = t2.shortDescription
        
        updated = true
    }
}
