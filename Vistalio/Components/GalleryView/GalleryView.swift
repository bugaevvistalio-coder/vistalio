//
//  GalleryView.swift
//  Vistalio
//
//  Created by Julia Konkova on 28.04.2026.
//

import UIKit
import FittedSheets

class GalleryView: UIView {
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var menuButton: UIButton!
    
    private var view: UIView!
    private let buffer = 1
    
    var onDismiss: (() -> ())?
    
    var media: [MediaData] = [] {
        didSet {
            collectionView.reloadData()
            for m in media {
                m.onLoaded = { [weak self] in
                    self?.collectionView.reloadData()
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        view = xibSetup()
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        view = xibSetup()
        setup()
    }
    
    func setup() {
        backgroundColor = .clear
        
        let nib = UINib(nibName: "GalleryCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "GalleryCell")
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    @IBAction func menuTapped(_ sender: Any) {
        let menuUnderlayControl =  parentViewController!.addMenuUnderlayControl(color: .clear)
        
        let menuView = MenuView()
        menuView.items = [MenuItemData(text: "Экспорт", image: .export, type: .normal, action: { [unowned self] in
            menuUnderlayControl.removeFromSuperview()
            share()
        })]
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(menuView)
        
        let constraints = [
            menuView.topAnchor.constraint(equalTo: menuButton.bottomAnchor, constant: 7),
            menuView.leftAnchor.constraint(equalTo: menuUnderlayControl.leftAnchor, constant: 16),
        ]
        NSLayoutConstraint.activate(constraints)
        
        menuView.setShadow(offset: CGSize(width: 0, height: 0), radius: 20, cornerRadius: 30, shadowOpacity: 0.22)
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        removeFromSuperview()
        onDismiss?()
    }
    
    private func share() {
        let width = collectionView.frame.width
        let currentIndex = Int((collectionView.contentOffset.x + width / 2) / width)
        let media = media[currentIndex % media.count]
        media.share(from: parentViewController!)
    }
}

extension GalleryView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return media.count == 1 ? media.count : (media.count + buffer)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCell", for: indexPath) as! GalleryCell
        cell.media = media[indexPath.row % media.count]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if media.count > 1 {
            let itemWidth = scrollView.frame.width
            
            if scrollView.contentOffset.x > itemWidth * CGFloat(media.count){
                collectionView.contentOffset.x -= itemWidth * CGFloat(media.count)
            }
            if scrollView.contentOffset.x < 0  {
                collectionView.contentOffset.x += itemWidth * CGFloat(media.count)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let galleryCell = cell as? GalleryCell {
            galleryCell.stopPlayback()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let galleryCell = cell as? GalleryCell {
            menuButton.isHidden = galleryCell.media?.image == nil && galleryCell.media?.path == nil
        }
    }
}
