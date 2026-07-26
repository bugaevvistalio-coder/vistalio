//
//  CoverViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 29.03.2026.
//

import UIKit
import PhotosUI
import Kingfisher

class CoverViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var saveButton: UIButton!
    
    private var createButton: UIButton?
    
    private var selectionIndex = 0
    private var categories = MissionCategory.allCases.filter { $0 != .notes }
    private var covers = [Cover]()
    
    private let generator = UIImpactFeedbackGenerator(style: .medium)
    
    var category: MissionCategory?
    var coverPath: String?
    var onCategorySelected: ((MissionCategory) -> ())?
    var onImageSelected: ((String) -> ())?
    var onImageDeleted: ((String) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1)
        setupBottomConstraint(saveButton)
        
        let window = UIApplication.shared.windows.first
        var bottom = window?.safeAreaInsets.bottom ?? 0
        if bottom == 0 {
            bottom = 20
        }
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70 + bottom, right: 0)
        
        covers = MissionsHolder.shared.getCovers()
        
        if let category = category {
            selectionIndex = (categories.firstIndex(of: category) ?? 0) + covers.count
        } else if let coverPath = coverPath {
            selectionIndex = covers.firstIndex { $0.photoPath == coverPath } ?? 0
        }
        let indexPath = IndexPath(row: selectionIndex, section: 1)
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
//        DispatchQueue.main.async { [weak self] in
//            self?.collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
//        }
        
        generator.prepare()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        createButton?.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18)
    }
    
    @IBAction func closeTapped() {
        dismiss(animated: true)
    }
    
    @IBAction func createCoverTapped() {
        let menuUnderlayControl = sheetViewController!.addMenuUnderlayControl(color: .clear)
        
        let menuView = MenuView()
        menuView.items = [
            MenuItemData(text: "Галерея", image: .gallery, type: .normal, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                self.openGallery()
            }),
            MenuItemData(text: "Камера", image: .camera, type: .normal, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                self.openCamera()
            })
        ]
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(menuView)
        
        let location = createButton!.superview!.convert(createButton!.frame.origin, to: nil)
        let constraints = [
            menuView.rightAnchor.constraint(equalTo: menuUnderlayControl.rightAnchor, constant: -22),
            menuView.topAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: location.y + createButton!.frame.height + 12),
        ]
        NSLayoutConstraint.activate(constraints)
        
        menuView.setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 30, shadowOpacity: 0.22)
    }
    
    @IBAction func saveTapped() {
        if selectionIndex < covers.count {
            if let path = covers[selectionIndex].photoPath {
                onImageSelected?(path)
            }
        } else {
            onCategorySelected?(categories[selectionIndex - covers.count])
        }
        dismiss(animated: true)
    }
    
    private func showMenu(cover: Cover, anchorRect: CGRect, image: UIImage) {
        let menuUnderlayControl = sheetViewController!.addMenuUnderlayControl(color: .black.withAlphaComponent(0.25))
        
        let menuView = MenuView()
        menuView.items = [
            MenuItemData(text: "Экспорт", image: .export, type: .normal, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                
                guard let path = cover.photoPath else { return }
                
                let url = FilesHelper().buildFileUrl(path: path)
                KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
                    DispatchQueue.main.async { [weak self] in
                        switch result {
                        case .success(let value):
                            let activityVC = UIActivityViewController(activityItems: [value.image], applicationActivities: nil)
                            self?.present(activityVC, animated: true)
                        case .failure( _):
                            break
                        }
                    }
                }
            }),
            MenuItemData(text: "Удалить", image: .trash, type: .red, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                
                let sb = UIStoryboard(name: "Main", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
                vc.popupTitle = "Удалить обложку?"
                vc.popupText = "Нельзя отменить."
                vc.buttons = [
                    ActionButton(type: .red, title: "Удалить", action: { [unowned self] _ in
                        let path = cover.photoPath
                        CoreDataStack.shared.performAndWait { context in
                            context.delete(cover)
                        }
                        self.covers.removeAll { $0 === cover }
                        self.selectionIndex = 0
                        self.collectionView.reloadData()
                        self.collectionView.selectItem(at: IndexPath(row: 0, section: 1), animated: false, scrollPosition: [])
                        
                        if let path = path {
                            self.onImageDeleted?(path)
                        }
                    }),
                    ActionButton(type: .secondary, title: "Отменить", action: { _ in })
                ]
                presentBottomSheet(vc, height: 200)
            })
        ]
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(menuView)
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let menuHeight = CGFloat(menuView.height)
        let horizontalConstraint = anchorRect.minX < screenWidth/2 ? menuView.leftAnchor.constraint(equalTo: menuUnderlayControl.leftAnchor, constant: anchorRect.minX) : menuView.rightAnchor.constraint(equalTo: menuUnderlayControl.rightAnchor, constant: anchorRect.maxX - screenWidth)
        let verticalConstraint = anchorRect.maxY + 20 + menuHeight > screenHeight ? menuView.bottomAnchor.constraint(equalTo: menuUnderlayControl.bottomAnchor, constant: anchorRect.minY - 7 - screenHeight) : menuView.topAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: anchorRect.maxY + 7)
        NSLayoutConstraint.activate([verticalConstraint, horizontalConstraint])
        
        menuView.layer.cornerRadius = 30
        
        let highlightedItemImageView = UIImageView()
        highlightedItemImageView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(highlightedItemImageView)
        
        let constraints = [
            highlightedItemImageView.topAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: anchorRect.minY),
            highlightedItemImageView.leftAnchor.constraint(equalTo: menuUnderlayControl.leftAnchor, constant: anchorRect.minX),
            highlightedItemImageView.widthAnchor.constraint(equalToConstant: anchorRect.width),
            highlightedItemImageView.heightAnchor.constraint(equalToConstant: anchorRect.height),
        ]
        NSLayoutConstraint.activate(constraints)
        
        highlightedItemImageView.image = image
    }
}

extension CoverViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return covers.count + categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeaderCell", for: indexPath)
            createButton = cell.viewWithTag(1) as? UIButton
            createButton?.addDashedBorder(color: UIColor.textGrey30, dashPattern: [2, 2], cornerRadius: 18)
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CoverCell", for: indexPath) as! CoverCell
        if indexPath.row < covers.count {
            let cover = covers[indexPath.row]
            cell.path = cover.photoPath
            cell.onLongGesture = { [unowned self] image, rect in
                self.generator.impactOccurred()
                self.generator.prepare()
                self.showMenu(cover: cover, anchorRect: rect, image: image)
            }
        } else {
            let category = categories[indexPath.row - covers.count]
            cell.image = UIImage(named: category.coverName)
        }
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

extension CoverViewController: PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider else { return }
        let type: NSItemProviderReading.Type = UIImage.self
        
        if provider.canLoadObject(ofClass: type) {
            provider.loadObject(ofClass: type) { (image, error) in
                DispatchQueue.main.async {
                    if let selectedImage = image as? UIImage {
                        self.openCropImage(selectedImage, fromGallery: true)
                    }
                }
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [unowned self] in
            if let image = info[.originalImage] as? UIImage {
                self.openCropImage(image, fromGallery: false)
            }
        }
    }
    
    private func openCropImage(_ image: UIImage, fromGallery: Bool) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "CropImageVC") as! CropImageViewController
        vc.image = image
        vc.onDismiss = { [unowned self] in
            if fromGallery {
                self.openGallery()
            } else {
                self.openCamera()
            }
        }
        vc.onCropped = { [unowned self] image in
            if let path = image.saveToDocuments(directory: "covers"), let cover = MissionsHolder.shared.saveCover(path: path) {
                self.covers.insert(cover, at: 0)
                self.selectionIndex = 0
                self.collectionView.reloadData()
                self.collectionView.selectItem(at: IndexPath(row: 0, section: 1), animated: false, scrollPosition: [])
            }
        }
        present(vc, animated: true)
    }
}
