//
//  UITableView+Utils.swift
//  Vistalio
//
//  Created by Julia Konkova on 21.03.2026.
//

import UIKit

extension UITableView {
    func layoutHeader() {
        guard let headerView = self.tableHeaderView else {
            return
        }
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
            self.tableHeaderView = headerView
            self.layoutIfNeeded()
        }
    }
    
    func layoutFooter() {
        guard let footerView = self.tableFooterView else {
            return
        }
        let size = footerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        if footerView.frame.size.height != size.height {
            footerView.frame.size.height = size.height
            self.tableFooterView = footerView
            self.layoutIfNeeded()
        }
    }
}
