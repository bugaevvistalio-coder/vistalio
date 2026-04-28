//
//  TemplateViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 23.04.2026.
//

import UIKit
import FittedSheets

class TemplateViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var exportButton: UIButton!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var topBgViewHeight: NSLayoutConstraint!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var notificationsStackView: UIStackView!
    
    var template: MissionTemplate!
    
    private var blocks = [[TemplateStep]]()
    private var steps = [TemplateStep]()
    private var numberOfSteps = 0
    
    private var notes = [TemplateNote]()
    private var numberOfNotes = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        progressIndicator.isHidden = true
        setupBottomConstraint(startButton)
        
        loadTemplate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.height - startButton.frame.minY + 20, right: 0)
    }
    
    func loadTemplate() {
        DispatchQueue.global().async {
            if let path = Bundle.main.path(forResource: "mission_\(self.template.id)", ofType: "json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                    
                    let decoder = JSONDecoder()
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    decoder.dateDecodingStrategy = .formatted(dateFormatter)
                    
                    let templateData = try decoder.decode(StepsList.self, from: data)
                    
                    self.blocks = templateData.blocks
                    let steps = templateData.blocks.flatMap({ $0 })
                    self.numberOfSteps = steps.count
                    self.steps = steps.filter { $0.preview == true }
                    
                    let notes = steps.compactMap({ $0.notes }).flatMap { $0 }
                    self.numberOfNotes = notes.count
                    self.notes = notes.filter { $0.preview == true }
                    
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                    
                } catch let error as NSError {
                    print(error)
                }
            }
        }
    }
    
    @IBAction func backTapped(_ sender: Any) {
        if sheetViewController != nil {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func exportTapped(_ sender: Any) {
        exportButton.isHidden = true
        progressIndicator.isHidden = false
        progressIndicator.startAnimating()
        AppsFlyerHelper().generateLink(templateId: template.id, viewController: self) { [weak self] in
            self?.exportButton.isHidden = false
            self?.progressIndicator.stopAnimating()
            self?.progressIndicator.isHidden = true
        }
    }
    
    @IBAction func menuTapped(_ sender: Any) {
        let menuUnderlayControl =  sheetViewController!.addMenuUnderlayControl(color: .clear)
        
        let menuView = MenuView()
        menuView.items = [
            MenuItemData(text: template.hiddenAt != nil ? "Показать" : "Скрыть", image: template.hiddenAt != nil ? .eyeOn1 : .eyeOff1, type: .normal, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                if template.hiddenAt != nil {
                    openShowMissionTemplate(template) { [unowned self] in
                        notificationsStackView.addNotification(text: "Миссия убрана из скрытых")
                    }
                } else {
                    openHideMissionTemplate(template) { [unowned self] in
                        dismiss(animated: true) {
                            (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Миссия скрыта")
                        }
                    }
                }
            })
        ]
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(menuView)
        
        let constraints = [
            menuView.topAnchor.constraint(equalTo: menuButton.bottomAnchor, constant: 0),
            menuView.rightAnchor.constraint(equalTo: menuButton.rightAnchor, constant: 0),
        ]
        NSLayoutConstraint.activate(constraints)
        
        menuView.setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 30, shadowOpacity: 0.22)
    }
    
    @IBAction func startTapped(_ sender: Any) {
        
        let request = Mission.missionFetchRequest()
        request.predicate = NSPredicate(format: "templateId == %d AND finishedAt == nil", template.id)
        var unfinished: [Mission]?
        
        CoreDataStack.shared.performAndWait { context in
            do {
                unfinished = try context.fetch(request)
            } catch {
                print("Delete template failed: \(error)")
            }
        }
        
        if let unfinished = unfinished, unfinished.count == 1 {
            let mission = unfinished.first!
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
            vc.popupTitle = mission.archived ? "Вы когда-то начинали эту миссию" : "Вы уже начали эту миссию"
            vc.popupText = mission.archived ? "Прямо сейчас она находится в архиве." : "Прямо сейчас она находится в активных миссиях."
            vc.showClose = true
            vc.buttons = [
                ActionButton(type: .primary, title: mission.archived ? "Убрать из архива" : "Открыть существующую", action: { [unowned self] in
                    if mission.archived {
                        CoreDataStack.shared.performAndWait { context in
                            mission.archived = false
                        }
                        NotificationCenter.default.post(name: .missionUpdated, object: nil)
                        (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Миссия убрана из архива")
                        dismissAndOpenMission(mission)
                    } else {
                        dismissAndOpenMission(mission)
                    }
                }),
                ActionButton(type: .secondary, title: "Начать новую", action: { [unowned self] in
                    self.startMission()
                })
            ]
            presentBottomSheet(vc, height: 200)
        } else {
            startMission()
        }
    }
    
    private func startMission() {
        var mission: Mission?
        CoreDataStack.shared.performAndWait { [unowned self] context in
            mission = Mission.create(context: context, template: template, steps: blocks)
        }
        NotificationCenter.default.post(name: .missionUpdated, object: nil)
        if let mission = mission {
            dismissAndOpenMission(mission)
        }
    }
    
    private func dismissAndOpenMission(_ mission: Mission) {
        dismiss(animated: true) {
            UIApplication.topViewController()?.openMission(mission)
        }
    }
}

extension TemplateViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 6
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 1 {
            return steps.count
        }
        if section == 4 {
            return notes.count
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StepCell", for: indexPath) as! TemplateStepCell
            cell.step = steps[indexPath.row]
            cell.onStepTapped = {
                collectionView.performBatchUpdates({
                    collectionView.collectionViewLayout.invalidateLayout()
                }, completion: nil)
            }
            return cell
        }
        if indexPath.section == 2 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MoreStepsCell", for: indexPath)
            let label = cell.viewWithTag(1) as! UILabel
            let count = numberOfSteps - steps.count
            label.text = "Ещё \("шаг".inclineWord_1(for: count))"
            return cell
        }
        if indexPath.section == 3 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NotesHeaderCell", for: indexPath)
            return cell
        }
        if indexPath.section == 4 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoteCell", for: indexPath) as! TemplateNoteCell
            cell.note = notes[indexPath.row]
            return cell
        }
        if indexPath.section == 5 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MoreStepsCell", for: indexPath)
            let label = cell.viewWithTag(1) as! UILabel
            let count = numberOfNotes - notes.count
            label.text = "Ещё \("замет".inclineWord_2(for: count))"
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeaderCell", for: indexPath) as! TemplateHeaderCell
        cell.template = template
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 1 {
            let width = UIScreen.main.bounds.width - 80
            let step = steps[indexPath.row]
            var height: CGFloat = 52
            height += step.name.height(withWidth: width, font: UIFont.systemFont(ofSize: 16, weight: .semibold))
            if let description = step.description {
                height += 16
                let descriptionHeight = description.height(withWidth: width, font: UIFont.systemFont(ofSize: 12, weight: .medium))
                height += ((step.expanded ?? false) ? descriptionHeight : min(descriptionHeight, 28))
            }
            return CGSize(width: UIScreen.main.bounds.width, height: height)
        } else if indexPath.section == 2 {
            if numberOfSteps - steps.count == 0 {
                return CGSize(width: UIScreen.main.bounds.width, height: 1)
            }
            return CGSize(width: UIScreen.main.bounds.width, height: 56)
        } else if indexPath.section == 3 {
            if notes.count == 0 {
                return CGSize(width: UIScreen.main.bounds.width, height: 1)
            }
            return CGSize(width: UIScreen.main.bounds.width, height: 66)
        } else if indexPath.section == 4 {
            return CGSize(width: (UIScreen.main.bounds.width - 36)/2, height: 215)
        } else if indexPath.section == 5 {
            if numberOfNotes - notes.count == 0 {
                return CGSize(width: UIScreen.main.bounds.width, height: 1)
            }
            return CGSize(width: UIScreen.main.bounds.width, height: 40)
        }
        let width = UIScreen.main.bounds.width - 32
        let titleHeight = template.name.height(withWidth: width, font: UIFont.systemFont(ofSize: 20, weight: .semibold))
        let descriptionHeight = template.fullDescription.height(withWidth: width, font: UIFont.systemFont(ofSize: 16, weight: .medium))
        return CGSize(width: UIScreen.main.bounds.width, height: 460 + titleHeight + descriptionHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 4 {
            return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if section == 4 {
            return 4
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if section == 4 {
            return 4
        }
        return 0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 {
            topBgViewHeight.constant = -scrollView.contentOffset.y + 64
        } else {
            topBgViewHeight.constant = 64
        }
    }
}
