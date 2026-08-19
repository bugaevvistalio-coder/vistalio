//
//  NotePhotoCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 15.07.2026.
//

import UIKit
import Kingfisher

class NotePhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var roundedView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var progressView: RingProgressView?
    
    var onRemove: ((MediaData) -> ())?
    var onTapped: ((NotePhotoCell) -> ())?
    
    var plusImage = UIImage.plus1
    
    override func awakeFromNib() {
        super.awakeFromNib()
        progressView?.ringBackgroundColor = .clear
        progressView?.ringColor = .white
    }
    
    var media: MediaData? {
        didSet {
            if let media = media {
                imageView.contentMode = .scaleAspectFill
                if let image = media.image {
                    imageView.image = image
                } else if let path = media.path {
                    if path.starts(with: "http") {
                        if let url = URL(string: path) {
                            imageView.kf.setImage(with: url)
                        } else {
                            imageView.image = nil
                        }
                    } else {
                        let url = FilesHelper().buildFileUrl(path: path)
                        print("File exists at \(url.path): \(FileManager.default.fileExists(atPath: url.path))")
                        if media.type == "video" {
                            DispatchQueue.global().async { [unowned self] in
                                let image = createVideoSnapshot(from: url)
                                DispatchQueue.main.async { [unowned self] in
                                    if path == self.media?.path {
                                        imageView.image = image
                                    }
                                }
                            }
                        } else {
                            imageView.loadFromUrl(url) { [unowned self] in
                                if let path = self.media?.path {
                                    let url = FilesHelper().buildFileUrl(path: path)
                                    return url.absoluteString
                                }
                                return nil
                            }
                        }
                    }
                } else {
                    imageView.image = nil
                }
            } else {
                imageView.contentMode = .center
                imageView.image = plusImage
            }
            updateProgress()
        }
    }
    
    func updateProgress() {
        if let progress = media?.progress, media?.image == nil && media?.path == nil {
            progressView?.isHidden = false
            progressView?.setProgress(Float(progress.fractionCompleted), animated: false)
            imageView.backgroundColor = .black
        } else {
            progressView?.isHidden = true
            imageView.backgroundColor = .clear
        }
    }
    
    var rotationDegrees: CGFloat = 0 {
        didSet {
            roundedView.transform = CGAffineTransform(rotationAngle: rotationDegrees * .pi / 180)
        }
    }
    
    var canRemove: Bool = true {
        didSet {
            removeButton.isHidden = !canRemove
        }
    }
    
    @IBAction func tapped(_ sender: Any) {
        onTapped?(self)
    }
    
    @IBAction func removeTapped(_ sender: Any) {
        if let media = media {
            if media.saved {
                onRemove?(media)
                return
            }
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
            vc.popupTitle = "Удалить \(media.type == "video" ? "видео" : "фотографию")?"
            vc.popupText = "Это действие нельзя отменить."
            vc.buttons = [
                ActionButton(type: .red, title: "Удалить", action: { [unowned self] _ in
                    onRemove?(media)
                }),
                ActionButton(type: .secondary, title: "Отменить", action: { _ in })
            ]
            parentViewController?.presentBottomSheet(vc, height: 200)
        }
    }
}
