//
//  MissionsViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 21.03.2026.
//

import UIKit

class MissionsViewController: UIViewController {
    
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var myMissionsButton: UIButton!
    @IBOutlet weak var addMissionButton: UIButton!
    @IBOutlet weak var myMissionsCollectionView: UICollectionView!
    @IBOutlet weak var myMissionsSpacing: NSLayoutConstraint!
    
    private var myMissions = [Mission]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBar.layer.cornerRadius = 30
        navBar.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        navBar.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 30, shadowOpacity: 0.1)
        
        myMissionsButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        addMissionButton.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18)
        
        updateMyMissions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutHeader()
        addMissionButton.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18)
    }
    
    private func updateMyMissions() {
        myMissions = MissionsHolder.shared.getMissions()
        myMissionsCollectionView.reloadData()
        myMissionsCollectionView.isHidden = myMissions.isEmpty
        myMissionsSpacing.constant = myMissions.isEmpty ? 24 : 16
    }
    
    @IBAction func addMissionTapped(_ sender: Any) {
        let nc = storyboard!.instantiateViewController(identifier: "CreateMissionNC") as! UINavigationController
        let vc = nc.viewControllers.first as! CreateMissionViewController
        vc.onMissionCreated = { [unowned self] mission in
            self.updateMyMissions()
            
            let vc = storyboard!.instantiateViewController(withIdentifier: "MissionVC") as! MissionViewController
            vc.mission = mission
            vc.isNew = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
        let window = UIApplication.shared.windows.first
        let top = (window?.safeAreaInsets.top ?? 20)
        presentBottomSheet(nc, height: UIScreen.main.bounds.height - top)
    }
}

extension MissionsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}

extension MissionsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myMissions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyMissionCell", for: indexPath) as! MyMissionCell
        cell.mission = myMissions[indexPath.row]
        return cell
    }
}

extension MissionsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        
        let vc = storyboard!.instantiateViewController(withIdentifier: "MissionVC") as! MissionViewController
        vc.mission = myMissions[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}
