//
//  AppsFlyerHelper.swift
//  Vistalio
//
//  Created by Julia Konkova on 28.04.2026.
//

import UIKit
import AppsFlyerLib

class AppsFlyerHelper {
    
    func generateLink(templateId: Int, viewController: UIViewController?, onFinished: @escaping () -> ()) {
        AppsFlyerShareInviteHelper.generateInviteUrl(
            linkGenerator: { generator in
                generator.addParameterValue("recommended", forKey: "deep_link_value")
                generator.addParameterValue(String(templateId), forKey: "deep_link_sub1")
                generator.addParameterValue("af_dp", forKey: "vistalio://")
                return generator
            }, completionHandler: { url in
                DispatchQueue.main.async {
                    if let baseUrl = url, let url = URL(string: baseUrl.absoluteString + "?af_force_deeplink=true") {
 
                        let objectsToShare = [url] as [Any]
                        
                        DispatchQueue.global().async {
                            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                            DispatchQueue.main.async {
                                viewController?.present(activityVC, animated: true) {
                                    onFinished()
                                }
                            }
                        }
                    } else {
                        onFinished()
                    }
                }
            }
        )
    }
}
