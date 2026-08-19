//
//  MediaHolder.swift
//  Vistalio
//
//  Created by Julia Konkova on 14.08.2026.
//

import UIKit

class MediaHolder {
    
    var media = [MediaData]()
    var onReloadNeeded: (([Int]) -> ())?
    
    private var mediaTimer: Timer?
    
    func startTimer() {
        if mediaTimer != nil {
            return
        }
        mediaTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let `self` = self else { return }
            var toReload = [Int]()
            
            DispatchQueue.main.async {
                for (i, m) in self.media.enumerated() {
                    if m.image == nil && m.path == nil && (m.progress != nil || m.loadedPath != nil || m.loadedImage != nil) {
                        if m.loadedImage != nil || m.loadedPath != nil {
                            self.media[i].image = m.loadedImage
                            self.media[i].path = m.loadedPath
                            self.media[i].onLoaded?()
                        }
                        toReload.append(i)
                    }
                }
                
                if toReload.isEmpty {
                    self.mediaTimer?.invalidate()
                    self.mediaTimer = nil
                    print("Timer stopped")
                } else {
                    UIView.performWithoutAnimation {
                        self.onReloadNeeded?(toReload)
                    }
                }
            }
        }
    }
    
    func remove(_ item: MediaData) {
        item.stopLoading()
        media.removeAll { $0 === item }
        if !item.saved {
            item.removeFile()
        }
    }
    
    func reset() {
        mediaTimer?.invalidate()
        mediaTimer = nil
        
        for m in media {
            m.stopLoading()
            if !m.saved {
                m.removeFile()
            }
        }
        
        media.removeAll()
    }
    
    var hasUnloadedMedia: Bool {
        return media.contains(where: { $0.image == nil && $0.path == nil })
    }
    
    func warnAboutUnloadedMedia(from viewController: UIViewController) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SelectActionVC") as! SelectActionViewController
        vc.popupTitle = "Не все медиа загружены"
        vc.popupText = "Дождитесь окончания загрузки, или удалите их."
        vc.showClose = true
        vc.buttons = [
            ActionButton(type: .primary, title: "Ок", action: { _ in })
        ]
        viewController.presentBottomSheet(vc, height: 200)
    }
}
