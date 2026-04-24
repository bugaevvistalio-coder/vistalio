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
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var startButton: UIButton!
    
    var template: MissionTemplate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        setupBottomConstraint(startButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.height - startButton.frame.minY + 20, right: 0)
    }
    
    @IBAction func backTapped(_ sender: Any) {
        if sheetViewController != nil {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func exportTapped(_ sender: Any) {
        
    }
    
    @IBAction func menuTapped(_ sender: Any) {
        
    }
    
    @IBAction func startTapped(_ sender: Any) {
        
    }
}

extension TemplateViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeaderCell", for: indexPath) as! TemplateHeaderCell
        cell.template = template
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width - 32
        let titleHeight = template.name.height(withWidth: width, font: UIFont.systemFont(ofSize: 20, weight: .semibold))
        let descriptionHeight = template.fullDescription.height(withWidth: width, font: UIFont.systemFont(ofSize: 16, weight: .medium))
        return CGSize(width: UIScreen.main.bounds.width, height: 460 + titleHeight + descriptionHeight)
    }
}
