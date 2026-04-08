//
//  CreateMissionViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 21.03.2026.
//

import UIKit

class CreateMissionViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var refreshButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var nameTextView: GrowingTextView!
    @IBOutlet weak var descriptionTextView: GrowingTextView!
    
    @IBOutlet weak var continueButton: UIButton!
    
    private var coverImage: UIImage?
    private var category: MissionCategory? = .location
    
    var onMissionCreated: ((Mission) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        refreshButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 4, cornerRadius: 10, shadowOpacity: 0.1)
        
        nameTextView.delegate = self
        descriptionTextView.delegate = self
        
        continueButton.isEnabled = false
        setupBottomConstraint(continueButton)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutHeader()
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        continueButton.isHidden = true
    }
    
    @objc func keyboardDidHide(notification: Notification) {
        continueButton.isHidden = false
    }
    
    @IBAction func closeTapped() {
        if (nameTextView.text ?? "") != "" || (descriptionTextView.text ?? "") != "" {
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
            vc.popupTitle = "Изменения не сохранены"
            vc.buttons = [
                ActionButton(type: .red, title: "Выйти без сохранения", action: { [unowned self] in
                    self.dismiss(animated: true)
                }), ActionButton(type: .secondary, title: "Вернуться к редактированию", action: { })
            ]
            presentBottomSheet(vc, height: 200)
        } else {
            dismiss(animated: true)
        }
    }
    
    @IBAction func coverTapped() {
        view.endEditing(true)
        
        let vc = storyboard!.instantiateViewController(identifier: "CoverVC") as! CoverViewController
        vc.onImageSelected = { [unowned self] image in
            self.coverImage = image
            self.coverImageView.image = image
        }
        vc.onCategorySelected = { [unowned self] category in
            self.category = category
            self.coverImageView.image = UIImage(named: category.coverName)
        }
        
        let window = UIApplication.shared.windows.first
        let top = (window?.safeAreaInsets.top ?? 20)
        presentBottomSheet(vc, height: UIScreen.main.bounds.height - top - 72)
    }
    
    @IBAction func continueTapped() {
        let name = nameTextView.text.trim()
        let about = descriptionTextView.text.trim()
        MissionsHolder.shared.createMission(name: name, about: about, coverPath: coverImage?.saveToDocuments(), category: category) { [weak self] mission in
            
            self?.dismiss(animated: true) {
                self?.onMissionCreated?(mission)
            }
        }
    }
}

extension CreateMissionViewController: GrowingTextViewDelegate {
    func textViewDidChangeHeight(_ textView: GrowingTextView, height: CGFloat) {
        tableView.layoutHeader()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        continueButton.isEnabled = nameTextView.text.trim().count > 0
    }
}
