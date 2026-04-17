//
//  CoverViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 29.03.2026.
//

import UIKit

class CoverViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var menuControl: UIControl!
    @IBOutlet weak var menuTop: NSLayoutConstraint!
    @IBOutlet weak var menuView: UIView!
    
    private var createButton: UIButton?
    private var selectionIndex = 0
    private var categories = MissionCategory.allCases
    
    var category: MissionCategory?
    var onCategorySelected: ((MissionCategory) -> ())?
    var onImageSelected: ((UIImage) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        menuView.setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 30, shadowOpacity: 0.2)
        setupBottomConstraint(saveButton)
        menuControl.isHidden = true
        
        let window = UIApplication.shared.windows.first
        var bottom = window?.safeAreaInsets.bottom ?? 0
        if bottom == 0 {
            bottom = 20
        }
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70 + bottom, right: 0)
        
        if let category = category {
            selectionIndex = categories.firstIndex(of: category) ?? 0
        }
        let indexPath = IndexPath(row: selectionIndex, section: 1)
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
        DispatchQueue.main.async { [weak self] in
            self?.collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        createButton?.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18)
    }
    
    @IBAction func closeTapped() {
        dismiss(animated: true)
    }
    
    @IBAction func createCoverTapped() {
        menuControl.isHidden = false
        menuTop.constant = 162 - collectionView.contentOffset.y
    }
    
    @IBAction func saveTapped() {
        onCategorySelected?(categories[selectionIndex])
        dismiss(animated: true)
    }
    
    @IBAction func menuTappedOutside() {
        menuControl.isHidden = true
    }
    
    @IBAction func galleryTapped() {
        
    }
    
    @IBAction func cameraTapped() {
        openCamera()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeaderCell", for: indexPath)
            createButton = cell.viewWithTag(1) as? UIButton
            createButton?.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18)
            return cell
        }
        let category = categories[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CoverCell", for: indexPath) as! CoverCell
        cell.image = UIImage(named: category.coverName)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectionIndex = indexPath.row
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width
        if indexPath.section == 0 {
            return CGSize(width: width - 20, height: 72)
        }
        let size = (width - 24) / 2
        return CGSize(width: size, height: size)
    }
}
