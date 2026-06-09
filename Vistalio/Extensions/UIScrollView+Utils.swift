//
//  UIScrollView+Utils.swift
//  Vistalio
//
//  Created by Julia Konkova on 09.06.2026.
//

import UIKit

extension UIScrollView {
    func scrollToViewBottom(_ view: UIView) {
        let bottomSafeArea = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.compatibleSafeAreaInsets.bottom ?? 0
        let bottomVisibleY = frame.height - contentInset.bottom + contentOffset.y - bottomSafeArea
        print("Bounds \(view.bounds)")
        let viewRect = view.convert(view.bounds, to: self)
        if bottomVisibleY < viewRect.maxY {
            var offset = contentOffset
            offset.y += (viewRect.maxY - bottomVisibleY)
            print("Offset \(offset.y)")
            setContentOffset(offset, animated: true)
        }
    }
}
