//
//  CropImageViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 19.04.2026.
//

import UIKit
import ImageScrollView

class CropImageViewController: UIViewController {
    
    @IBOutlet weak var imageScrollView: ImageScrollView!
    @IBOutlet weak var scrollTop: NSLayoutConstraint!
    @IBOutlet weak var cropCircleView: UIView!
    
    var image: UIImage!
    var onDismiss: (() -> ())?
    var onCropped: ((UIImage) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        imageScrollView.setup()
        imageScrollView.display(image: image)

        scrollTop.constant = (UIScreen.main.bounds.height - UIScreen.main.bounds.width)/2
        
        cropCircleView.makeTransparentHole(at: CGPoint(x: screenWidth/2, y: screenHeight/2), radius: screenWidth/2)
        
        DispatchQueue.main.async {
            let imageHeight = self.image.size.height * screenWidth / self.image.size.width
            if imageHeight > screenWidth {
                self.imageScrollView.setContentOffset(CGPoint(x: 0, y: (imageHeight - screenWidth)/2), animated: false)
            } else {
                self.imageScrollView.zoomScale = screenWidth / self.image.size.height
                self.imageScrollView.minimumZoomScale = self.imageScrollView.zoomScale
            }
        }
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        let onDismiss = onDismiss
        dismiss(animated: true) {
            onDismiss?()
        }
    }
    
    @IBAction func okTapped(_ sender: Any) {
        let locationOnScreen = imageScrollView.zoomView!.superview!.convert(imageScrollView.zoomView!.frame.origin, to: nil)
        let location = CGPoint(x: -locationOnScreen.x, y: imageScrollView.frame.minY - locationOnScreen.y)
        let ratio = (image.size.height > image.size.width ? image.size.width / imageScrollView.zoomView!.frame.width : image.size.height / imageScrollView.zoomView!.frame.height)
        let width = UIScreen.main.bounds.width * ratio
        let rect = CGRect(x: location.x * ratio, y: location.y * ratio, width: width, height: width)
        print("image size \(image.size), view size \(imageScrollView.zoomView!.frame.size), location \(location), rect \(rect)")
        let cropped = image.cropped(to: rect)
        
        let onCropped = onCropped
        dismiss(animated: true) {
            if let cropped = cropped {
                onCropped?(cropped)
            }
        }
    }
}
