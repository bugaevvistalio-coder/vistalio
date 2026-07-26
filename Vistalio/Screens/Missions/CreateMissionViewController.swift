//
//  CreateMissionViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 21.03.2026.
//

import UIKit
import IQKeyboardManagerSwift

class CreateMissionViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var refreshButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var nameTextView: GrowingTextView!
    @IBOutlet weak var descriptionTextView: GrowingTextView!
    
    @IBOutlet weak var continueButton: UIButton!
    
    private var coverPath: String?
    private var category: MissionCategory?
    private var defaultCategory = MissionCategory.allCases[0]
    
    private var templates = [MissionTemplate]()
    private var hiddenTemplates = [MissionTemplate]()
    private var hiddenTemplatesExpanded = false
    
    var mission: Mission?
    var onMissionCreated: ((Mission) -> ())?
    var onMissionUpdated: ((Mission) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        refreshButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 4, cornerRadius: 10, shadowOpacity: 0.1)
        
        nameTextView.delegate = self
        descriptionTextView.delegate = self
        
        continueButton.isEnabled = false
        setupBottomConstraint(continueButton)
        
        tableView.estimatedRowHeight = 380.0
        tableView.rowHeight = UITableView.automaticDimension
        
        if mission == nil {
            if let categoryName = UserDefaults.standard.string(forKey: "DefaultMissionCategory"), let cat = MissionCategory(rawValue: categoryName), let index = MissionCategory.allCases.firstIndex(of: cat) {
                if index >= MissionCategory.allCases.count - 1 {
                    defaultCategory = MissionCategory.allCases[0]
                } else {
                    defaultCategory = MissionCategory.allCases[index + 1]
                }
            }
            category = defaultCategory
            coverImageView.image = UIImage(named: defaultCategory.coverName)
            UserDefaults.standard.set(defaultCategory.rawValue, forKey: "DefaultMissionCategory")
        }
        displayMission()
        
        templates = MissionsHolder.shared.templates.filter { $0.hiddenAt == nil }
        hiddenTemplates = MissionsHolder.shared.templates.filter { $0.hiddenAt != nil }.sorted(by: { $0.hiddenAt! > $1.hiddenAt! })
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onTemplatesUpdated(notification:)), name: .templatesUpdated, object: nil)
    }
    
    deinit {
        print("Create mission deinit")
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .templatesUpdated, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        IQKeyboardManager.shared.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared.isEnabled = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutHeader()
        tableView.tableHeaderView?.setGradientLayer(colors: [.white, .bgGrey], startPoint: CGPoint(x: 0.5, y: 0.0), endPoint: CGPoint(x: 0.5, y: 1.0), cornerRadius: 0)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.height - continueButton.frame.minY + 20, right: 0)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        continueButton.isHidden = true
    }
    
    @objc func keyboardDidHide(notification: Notification) {
        continueButton.isHidden = false
    }
    
    @objc func onTemplatesUpdated(notification: Notification) {
        templates = MissionsHolder.shared.templates.filter { $0.hiddenAt == nil }
        hiddenTemplates = MissionsHolder.shared.templates.filter { $0.hiddenAt != nil }.sorted(by: { $0.hiddenAt! > $1.hiddenAt! })
        tableView.reloadData()
    }
    
    private func displayMission() {
        guard let mission = mission else {
            return
        }
        titleLabel.text = "Изменить миссию"
        continueButton.setTitle("Сохранить", for: .normal)
        continueButton.isEnabled = true
        
        coverImageView.displayMissionCover(mission: mission)
        nameTextView.text = mission.name
        descriptionTextView.text = mission.about
    }
    
    @IBAction func closeTapped() {
        var hasChanges = false
        let name = nameTextView.text ?? ""
        let about = descriptionTextView.text ?? ""
        
        if let mission = mission {
            hasChanges = name != mission.name || about != mission.about || category != nil || coverPath != nil
        } else {
            hasChanges = !name.isEmpty || !about.isEmpty || category != defaultCategory || coverPath != nil
        }
        
        if hasChanges {
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
            vc.popupTitle = "Изменения не сохранены"
            vc.buttons = [
                ActionButton(type: .red, title: "Выйти без сохранения", action: { [unowned self] _ in
                    self.dismiss(animated: true)
                }), ActionButton(type: .secondary, title: "Вернуться к редактированию", action: { _ in })
            ]
            presentBottomSheet(vc, height: 200)
        } else {
            navigationController?.dismiss(animated: true)
        }
    }
    
    @IBAction func coverTapped() {
        view.endEditing(true)
        
        let vc = storyboard!.instantiateViewController(identifier: "CoverVC") as! CoverViewController
        if let coverPath = coverPath {
            vc.coverPath = coverPath
        } else if let category = category {
            vc.category = category
        } else if let categoryName = mission?.category, let category = MissionCategory(rawValue: categoryName) {
            vc.category = category
        }
        vc.onImageSelected = { [unowned self] path in
            self.category = nil
            self.coverPath = path
            self.coverImageView.loadFromPath(path) {
                return path
            }
        }
        vc.onCategorySelected = { [unowned self] category in
            self.coverPath = nil
            self.category = category
            self.coverImageView.image = UIImage(named: category.coverName)
        }
        vc.onImageDeleted = { [unowned self] path in
            if self.coverPath == path {
                self.coverPath = nil
                self.category = .location
                self.coverImageView.image = UIImage(named: self.category!.coverName)
            }
        }
        
        let window = UIApplication.shared.windows.first
        let top = (window?.safeAreaInsets.top ?? 20)
        presentBottomSheet(vc, height: UIScreen.main.bounds.height - top - 72)
    }
    
    @IBAction func continueTapped() {
        let name = nameTextView.text.trim()
        let about = descriptionTextView.text.trim()
        
        var missionCoverPath: String? = nil
        if let coverPath = coverPath {
            missionCoverPath = FilesHelper().copyFile(at: coverPath, to: "missions")
        }
        
        if let mission = mission {
            var updateCoverPath = mission.photoPath
            var updateCategory = MissionCategory(rawValue: mission.category ?? "")
            if missionCoverPath != nil {
                updateCoverPath = missionCoverPath
                updateCategory = nil
            } else if category != nil {
                updateCoverPath = nil
                updateCategory = category
            }
            MissionsHolder.shared.updateMission(mission: mission, name: name, about: about, coverPath: updateCoverPath, category: updateCategory) { [weak self] mission in
                NotificationCenter.default.post(name: .missionUpdated, object: nil)
                self?.dismiss(animated: true) {
                    self?.onMissionUpdated?(mission)
                    (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Миссия изменена")
                }
            }
        } else {
            MissionsHolder.shared.createMission(name: name, about: about, coverPath: missionCoverPath, category: category) { [weak self] mission in
                NotificationCenter.default.post(name: .missionUpdated, object: nil)
                self?.dismiss(animated: true) {
                    self?.onMissionCreated?(mission)
                    (UIApplication.shared.delegate as! AppDelegate).addNotification(text: "Миссия добавлена")
                }
            }
        }
    }
}

extension CreateMissionViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return templates.count
        } else if section == 2 {
            return hiddenTemplatesExpanded ? hiddenTemplates.count : 0
        }
        return hiddenTemplates.isEmpty ? 0 : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HiddenMissionsCell", for: indexPath)
            cell.selectionStyle = .none
            let arrow = cell.viewWithTag(1) as! UIImageView
            arrow.transform = CGAffineTransform(rotationAngle: hiddenTemplatesExpanded ? .pi/2 : -.pi/2)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "TemplateCell", for: indexPath) as! TemplateCell
        let templates = indexPath.section == 0 ? self.templates : hiddenTemplates
        cell.template = templates[indexPath.row]
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        hiddenTemplatesExpanded = !hiddenTemplatesExpanded
        tableView.reloadSections(IndexSet(arrayLiteral: 1, 2), with: .automatic)
    }
}

extension CreateMissionViewController: GrowingTextViewDelegate {
    func textViewDidChangeHeight(_ textView: GrowingTextView, height: CGFloat) {
        tableView.layoutHeader()
        tableView.tableHeaderView?.setGradientLayer(colors: [.white, .bgGrey], startPoint: CGPoint(x: 0.5, y: 0.0), endPoint: CGPoint(x: 0.5, y: 1.0), cornerRadius: 0)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        continueButton.isEnabled = nameTextView.text.trim().count > 0
    }
}
