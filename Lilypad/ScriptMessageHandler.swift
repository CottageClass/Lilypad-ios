//
//  ScriptMessageHandler.swift
//  LilyPad-ios
//
//  Created by Ari Kardasis on 9/12/19.
//  Copyright © 2019 LilyPad. All rights reserved.
//

import Foundation
import WebKit

class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // add logic here to intercept messages emitted from js code via iosAdapter.js
        
        if (message.name == "lilyPad") {
            let title = (message.body as! NSDictionary)["title"] as! String
            switch  (title) {
                case "signInComplete":
                    print("signInComplete message received")
                    let pushManager = PushNotificationManager()
                    pushManager.registerForRemoteNotifications(for: UIApplication.shared)
            default:
                print("unrecognized message title : \(title)")
            }
        }
    }
}
