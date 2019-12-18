//
//  AppDelegate.swift
//  Lilypad
//
//  Created by Ari Kardasis on 11/7/19.
//  Copyright © 2019 Lilypad. All rights reserved.
//

import WebKit
import Turbolinks
import UserNotifications
//import Contacts

enum Environment: String {
    case development = "Development"
    case production = "Production"
    case staging = "Staging"
    case none = "None"
}

var environment: Environment = .none


@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
//    let contactStore = CNContactStore()
    
    var navigationController = UINavigationController()
    lazy var session: Session = {
        let configuration = WKWebViewConfiguration()
        let scriptMessageHandler = ScriptMessageHandler()
        configuration.applicationNameForUserAgent = "LilyPadIOSNative"
        configuration.userContentController.add(scriptMessageHandler, name: "lilyPad")
        var sess = Session(webViewConfiguration: configuration)
        sess.webView.scrollView.bounces = false

        return sess
    }()
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
      guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let incomingURL = userActivity.webpageURL else {
              return false
      }
      visit(URL: incomingURL)
      return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
         var url: String
//         var contacts = [CNContact]()
//         let keys = [
//               CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
//               CNContactPhoneNumbersKey,
//               CNContactEmailAddressesKey,
//           ] as [Any]
//         let request = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
//
//         do {
//             try self.contactStore.enumerateContacts(with: request) {
//                 (contact, stop) in
//                 // Array containing all unified contacts from everywhere
//                 contacts.append(contact)
//                 print(contact)
//             }
//         }
//         catch {
//             print("unable to fetch contacts")
//         }
         
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasHidden), name: UIResponder.keyboardDidHideNotification, object: nil)

        setEnvironment()
         let notificationOption = launchOptions?[.remoteNotification]

         if let notification = notificationOption as? [String: AnyObject],
             let aps = notification["aps"] as? NSDictionary {
             url = aps.value(forKeyPath: "alert.url") as! String

          } else {
              switch environment {
              case .development:
                  //url = "http://localhost:3000"
                  url = "https://cottageclass.ngrok.io"
                  break
              case .staging:
                  url = "https://kidsclub-staging.herokuapp.com"
                  break
              case .production:
                  url = "https://joinlilypad.com"
                  break
              case .none:
                  url = ""
                  break
              }
         }

         window?.rootViewController = navigationController
        session.delegate = self
         UNUserNotificationCenter.current().delegate = self

     
         visit(URL: URL(string: url)!)
         return true
     }
    
     @objc
     func keyboardWasShown(notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            print(keyboardHeight)
            session.webView.scrollView.contentInset = UIEdgeInsets(top: 0,left: 0,bottom: keyboardHeight,right: 0)
        }
     }
     
     @objc
     func keyboardWasHidden(notification: Notification) {
        session.webView.scrollView.contentInset = UIEdgeInsets(top: 0,left: 0,bottom: 0,right: 0)
         let dataDict:[String: String] = ["name": "keyboardHidden"]
         dispatchMessageToWebkit(dataDict as AnyObject)
     }
    

    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()
        let dataDict:[String: String] = ["name": "deviceTokenReceived",
                                         "token": token]
        (UIApplication.shared.delegate as! AppDelegate).dispatchMessageToWebkit((dataDict as AnyObject))
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.alert, .badge, .sound])
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        let aps = (userInfo["aps"] as! NSDictionary)
        let url = aps.value(forKeyPath: "alert.url")
        visit(URL: URL(string: url as! String)!)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        let dataDict:[String: String] = ["name": "applicationDidEnterForeground"]
        (UIApplication.shared.delegate as! AppDelegate).dispatchMessageToWebkit((dataDict as AnyObject))
    }
    
    func setEnvironment() {
        #if ENVIRONMENT_DEVELOPMENT
        environment = .development
        #elseif ENVIRONMENT_STAGING
        environment = .staging
        #elseif ENVIRONMENT_PRODUCTION
        environment = .production
        #endif
    }
    
    func dispatchMessageToWebkit(_ message: AnyObject) {
        // access this by using (UIApplication.shared.delegate as! AppDelegate).dispatchMessageToWebkit("hi")
        let jsonString = jsonToString(json: message)
        let scriptText: String = "window.dispatchEvent(new CustomEvent('lilyPadIOSNativeEvent', {detail:" + jsonString + "}))"
        session.webView.evaluateJavaScript(scriptText, completionHandler: nil)
    }
    
    func visit(URL:URL) {
        let visitableViewController = LPVisitableViewController(url: URL)
        navigationController.pushViewController(visitableViewController, animated: false)
        session.visit(visitableViewController)
    }
}
extension AppDelegate: SessionDelegate {
    func session(_ session: Session, didProposeVisitToURL URL: URL, withAction action: Action) {
        visit(URL: URL)
    }
    
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError) {
        print(error)
    }
}

func jsonToString(json: Any) -> String {
    do {
      let data = try JSONSerialization.data(withJSONObject: json)
      if let string = String(data: data, encoding: String.Encoding.utf8) {
        return string
      }
    } catch {
      print(error)
    }

    return ""
}
