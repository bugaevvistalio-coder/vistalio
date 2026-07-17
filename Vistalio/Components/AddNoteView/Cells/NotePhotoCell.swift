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
    
    var onRemove: ((MediaData) -> ())?
    var onTapped: (() -> ())?
    
    var media: MediaData? {
        didSet {
            if let media = media {
                imageView.contentMode = .scaleAspectFill
                if let image = media.image {
                    imageView.image = image
                } else if let path = media.path {
                    let url = FilesHelper().buildFileUrl(path: path)
                    if media.type == "video" {
                        imageView.image = createVideoSnapshot(from: url)
                    } else {
                        imageView.loadFromUrl(url) {
                            return url.absoluteString
                        }
                    }
                }
            } else {
                imageView.contentMode = .center
                imageView.image = .plus1
            }
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
        if media == nil {
            onTapped?()
        }
    }
    
    @IBAction func removeTapped(_ sender: Any) {
        if let media = media {
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
            vc.popupTitle = "Удалить \(media.type == "video" ? "видео" : "фотографию")?"
            vc.popupText = "Это действие нельзя отменить."
            vc.buttons = [
                ActionButton(type: .red, title: "Удалить", action: { [unowned self] in
                    onRemove?(media)
                }),
                ActionButton(type: .secondary, title: "Отменить", action: { })
            ]
            parentViewController?.presentBottomSheet(vc, height: 200)
        }
    }
}
