//
//  NoteViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 16.08.2026.
//

import UIKit

class NoteViewController: UIViewController {
    
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    
    @IBOutlet weak var navigationMissionButton: UIButton!
    @IBOutlet weak var navigationStepButton: UIButton!
    @IBOutlet weak var navigationGradientLeft: UIView!
    @IBOutlet weak var navigationGradientRight: UIView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var emotionsFlowView: EmotionsFlowView!
    
    @IBOutlet private weak var dateLabel: UILabel!
    
    @IBOutlet private weak var titleTextView: GrowingTextView!
    @IBOutlet private weak var bodyTextView: GrowingTextView!
    
    @IBOutlet private weak var mediaCollectionView: UICollectionView!
    
    var note: MissionNote!
    private var media = [MediaData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        navBar.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 30, shadowOpacity: 0.9)
        
        updateNavigation()
        
        navigationGradientLeft.setGradientLayer(colors: [.white, .white.withAlphaComponent(0.01)], startPoint: CGPoint(x: 0.0, y: 0.5), endPoint: CGPoint(x: 1.0, y: 0.5), cornerRadius: 0)
        navigationGradientRight.setGradientLayer(colors: [.white, .white.withAlphaComponent(0.01)], startPoint: CGPoint(x: 1.0, y: 0.5), endPoint: CGPoint(x: 0.0, y: 0.5), cornerRadius: 0)
        
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        
        emotionsFlowView.maxWidth = UIScreen.main.bounds.width - 44
        
        titleTextView.textContainer.lineFragmentPadding = 0
        titleTextView.textContainerInset = .zero
        
        bodyTextView.textContainer.lineFragmentPadding = 0
        bodyTextView.textContainerInset = .zero
        
        let nib = UINib(nibName: "NoteBiggerPhotoCell", bundle: nil)
        mediaCollectionView.register(nib, forCellWithReuseIdentifier: "NoteBiggerPhotoCell")
        
        displayNote()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onNoteUpdated(notification:)), name: .noteUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .noteUpdated, object: nil)
    }
    
    private func displayNote() {
        emotionsFlowView.emotions = note.emotions?.allObjects.map { $0 as! MissionNoteEmotion }.sorted { $0.date > $1.date }.map { MissionEmotion(rawValue: ($0.emotion))! } ?? []
        if emotionsFlowView.emotions.isEmpty {
            emotionsFlowView.superview?.isHidden = true
        }
        
        if note.name?.trim().isEmpty ?? true {
            titleTextView.superview?.isHidden = true
        } else {
            titleTextView.text = note.name
        }
        if note.text?.trim().isEmpty ?? true {
            bodyTextView.superview?.isHidden = true
        } else {
            bodyTextView.text = note.text
        }
        dateLabel.text = note.date?.formatted3
        
        media = note.images?.allObjects.map { $0 as! MissionNoteImage }.sorted { $0.date > $1.date }.map { $0.mediaData } ?? []
        mediaCollectionView.isHidden = media.isEmpty
        mediaCollectionView.reloadData()
    }
    
    private func updateNavigation() {
        navigationMissionButton.setTitle(note.step?.block.mission.name?.limitCharacters(20), for: .normal)
        navigationStepButton.setTitle(note.step?.name?.limitCharacters(20), for: .normal)
    }
    
    @IBAction func backTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func navigationMyMissionsTapped(_ sender: Any) {
        if let nc = navigationController {
            var controllers = nc.viewControllers
            for vc in controllers {
                if vc is MyMissionsViewController {
                    nc.popToViewController(vc, animated: true)
                    return
                }
            }
            controllers.removeLast(controllers.count - 1)
            let myMissionsVC = storyboard!.instantiateViewController(withIdentifier: "MyMissionsVC")
            controllers.append(myMissionsVC)
            nc.setViewControllers(controllers, animated: true)
        }
    }
    
    @IBAction func navigationMissionTapped(_ sender: Any) {
        guard let nc = navigationController else { return }
        var controllers = nc.viewControllers
        for vc in controllers {
            if let missionVC = vc as? MissionViewController, missionVC.mission.objectID == note.step?.block.mission.objectID {
                nc.popToViewController(vc, animated: true)
                return
            }
        }
        controllers.removeLast(controllers.count - 1)
        let vc = storyboard?.instantiateViewController(withIdentifier: "MissionVC") as! MissionViewController
        vc.mission = note.step!.block.mission
        controllers.append(vc)
        nc.setViewControllers(controllers, animated: true)
    }
    
    @IBAction func navigationStepTapped(_ sender: Any) {
        guard let nc = navigationController else { return }
        let controllers = nc.viewControllers
        var newControllers = [UIViewController]()
        var readdMission = false

        for vc in controllers {
            if let missionVC = vc as? MissionViewController {
                if let mission = note.step?.block.mission, missionVC.mission.objectID != mission.objectID {
                    readdMission = true
                    continue
                }
            } else if let stepVC = vc as? StepViewController, let step = note.step {
                if stepVC.step.objectID == step.objectID {
                    nc.popToViewController(stepVC, animated: true)
                    return
                }
                break
            }
            if vc is NoteViewController {
                break
            }
            newControllers.append(vc)
        }
        
        let sb = UIStoryboard(name: "Missions", bundle: nil)
        if readdMission {
            let newVC = sb.instantiateViewController(withIdentifier: "MissionVC") as! MissionViewController
            newVC.mission = note.step!.block.mission
            newControllers.append(newVC)
        }
        let newVC = sb.instantiateViewController(withIdentifier: "StepVC") as! StepViewController
        newVC.step = note.step
        newControllers.append(newVC)
        
        nc.setViewControllers(newControllers, animated: true)
    }
    
    @IBAction func menuTapped(_ sender: Any) {
        let mainVC = UIApplication.shared.mainViewController!
        let menuUnderlayControl =  mainVC.addMenuUnderlayControl(color: .clear)
        
        let menuView = MenuView()
        menuView.items = getNoteMenuItems(note: note, menuUnderlayControl: menuUnderlayControl, onDeleted: { [unowned self] stepDeleted, missionDeleted in
            NotificationCenter.default.post(name: .noteUpdated, object: note)
            if (!stepDeleted && !missionDeleted) || !backToStepOrMission(stepDeleted: stepDeleted, missionDeleted: missionDeleted) {
                navigationController?.popViewController(animated: true)
            }
        }, onMoved: { [unowned self] stepDeleted, missionDeleted in
            NotificationCenter.default.post(name: .noteUpdated, object: note)
            updateNavigation()
        })
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(menuView)
        
        let constraints = [
            menuView.topAnchor.constraint(equalTo: menuButton.bottomAnchor, constant: 0),
            menuView.rightAnchor.constraint(equalTo: menuUnderlayControl.rightAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraints)
        
        menuView.setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 30, shadowOpacity: 0.22)
    }
    
    @discardableResult
    private func backToStepOrMission(stepDeleted: Bool, missionDeleted: Bool) -> Bool {
        guard let nc = navigationController else {
            return false
        }
        let controllers = nc.viewControllers
        for (i, vc) in controllers.enumerated() {
            if stepDeleted, let _ = vc as? StepViewController {
                nc.popToViewController(controllers[i - 1], animated: true)
                return true
            }
            if missionDeleted, let _ = vc as? MissionViewController {
                nc.popToViewController(controllers[i - 1], animated: true)
                return true
            }
        }
        return false
    }
    
    @objc func onNoteUpdated(notification: Notification) {
        if let note = notification.object as? MissionNote, note.objectID == self.note.objectID {
            self.note = note
            displayNote()
        }
    }
}

extension NoteViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return media.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoteBiggerPhotoCell", for: indexPath) as! NoteBiggerPhotoCell
        cell.media = media[indexPath.row]
        cell.canRemove = false
        
        if indexPath.row % 3 == 1 {
            cell.rotationDegrees = -5
        } else if indexPath.row % 3 == 2 {
            cell.rotationDegrees = 5
        } else {
            cell.rotationDegrees = 0
        }
        
        cell.onTapped = { [unowned self] cell in
            guard let currentIndexPath = collectionView.indexPath(for: cell) else { return }
            UIApplication.shared.mainViewController?.openGallery(media: media, at: currentIndexPath.row)
        }
        
        return cell
    }
}
