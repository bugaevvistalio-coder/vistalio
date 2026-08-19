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
                generator.addParameterValue("vistalio://", forKey: "af_dp")
//                generator.brandDomain = "vistalio.onelink.me"
                return generator
            }, completionHandler: { url in
                DispatchQueue.main.async {
                    if let baseUrl = url, let url = URL(string: baseUrl.absoluteString + "&af_force_deeplink=true") {
                        
                        print("URL to share: \(url)")

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
        
//        AppsFlyerShareInviteHelper.generateInviteUrl(
//            linkGenerator: { generator in
////                generator.setChannel("share")
////                
//                generator.addParameterValue("recommended", forKey: "deep_link_value")
//                generator.addParameterValue(String(templateId), forKey: "deep_link_sub1")
////                
////                generator.addParameterValue("eU8s", forKey: "onelink_id")
//
//                generator.brandDomain = "vistalio.onelink.me"
//
////                generator.addParameterValue("vistalio://", forKey: "af_dp")
//                return generator
//            }, completionHandler: { url in
//                DispatchQueue.main.async {
//                    if let baseUrl = url, let url = URL(string: baseUrl.absoluteString) {
// 
//                        let objectsToShare = [url] as [Any]
//                        
//                        DispatchQueue.global().async {
//                            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
//                            DispatchQueue.main.async {
//                                viewController?.present(activityVC, animated: true) {
//                                    onFinished()
//                                }
//                            }
//                        }
//                    } else {
//                        onFinished()
//                    }
//                }
//            }
//        )
    }
}
