//
//  GalleryView.swift
//  Vistalio
//
//  Created by Julia Konkova on 28.04.2026.
//

import UIKit

class GalleryView: UIView {
    
    @IBOutlet private weak var collectionView: UICollectionView!
    
    private var view: UIView!
    private let buffer = 1
    
    var onDismiss: (() -> ())?
    
    var paths: [String] = [] {
        didSet {
            collectionView.reloadData()
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
    
    @IBAction func closeTapped(_ sender: Any) {
        removeFromSuperview()
        onDismiss?()
    }
}

extension GalleryView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return paths.count == 1 ? paths.count : (paths.count + buffer)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCell", for: indexPath) as! GalleryCell
        cell.path = paths[indexPath.row % paths.count]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if paths.count > 1 {
            let itemWidth = scrollView.frame.width
            
            if scrollView.contentOffset.x > itemWidth * CGFloat(paths.count){
                collectionView.contentOffset.x -= itemWidth * CGFloat(paths.count)
            }
            if scrollView.contentOffset.x < 0  {
                collectionView.contentOffset.x += itemWidth * CGFloat(paths.count)
            }
        }
    }
}
