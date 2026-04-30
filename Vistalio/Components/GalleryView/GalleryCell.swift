//
//  GalleryCel.swift
//  Vistalio
//
//  Created by Julia Konkova on 28.04.2026.
//

import UIKit
import Kingfisher

class GalleryCell: UICollectionViewCell, ImageScrollViewDelegate {
    
    @IBOutlet private weak var imageScrollView: ImageScrollView!
    @IBOutlet private weak var loadIndicator: UIActivityIndicatorView!
    
    private var originalZoom: CGFloat = 1
    private var autoZooming = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageScrollView.imageContentMode = .aspectFit
        imageScrollView.setup()
        imageScrollView.imageScrollViewDelegate = self
    }
    
    var path: String! {
        didSet {
            // Иначе будет неправильно центрирование по вертикали, потому что высота не сразу определяется правильно
            imageScrollView.frame.size.height = UIScreen.main.bounds.height
            
            var url: URL?
            if path.starts(with: "http") {
                url = URL(string: path)
            } else {
                url = FilesHelper().buildFileUrl(path: path)
            }
            
            guard let url = url, let imageScrollView = imageScrollView else { return }
            let path = self.path
            
            if path!.starts(with: "http"), !ImageCache.default.isCached(forKey: path!) {
                loadIndicator.isHidden = false
                loadIndicator.startAnimating()
            }
            
            KingfisherManager.shared.retrieveImage(with: url) { result in
                DispatchQueue.main.async { [weak self] in
                    if self?.path == path {
                        switch result {
                        case .success(let value):
                            imageScrollView.display(image: value.image, enableDoubleTap: false)
                            self?.updateBorder()
                        case .failure( _):
                            imageScrollView.zoomView?.image = nil
                        }
                        self?.loadIndicator.isHidden = true
                        self?.loadIndicator.stopAnimating()
                    }
                }
            }
        }
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        if !autoZooming {
            originalZoom = imageScrollView.zoomScale
        }
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if !autoZooming {
            imageScrollView.setZoomScale(originalZoom, animated: true)
        }
        autoZooming = !autoZooming
        updateBorder()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateBorder()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateBorder()
    }
    
    func imageScrollViewDidChangeOrientation(imageScrollView: ImageScrollView) { }
    
    private func updateBorder() {
        imageScrollView.zoomView?.layer.cornerRadius = 12 / imageScrollView.zoomScale
        imageScrollView.zoomView?.layer.borderWidth = 6 / imageScrollView.zoomScale
        imageScrollView.zoomView?.layer.borderColor = UIColor.white.cgColor
        imageScrollView.zoomView?.layer.masksToBounds = true
    }
}
