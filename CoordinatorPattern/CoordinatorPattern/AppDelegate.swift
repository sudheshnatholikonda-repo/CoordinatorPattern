//
//  AppDelegate.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 06/10/26.
//

//
//  AppDelegate.swift
//  CoordinatorPattern
//

import UIKit
import GoogleMaps

/*
 AppDelegate: UIKit's app-lifecycle object.
 SwiftUI apps don't have one by default; we bring it in with
 @UIApplicationDelegateAdaptor in the App file (step 2 below).

 Why have one?
 - Some SDKs need setup at launch (Google Maps, Firebase).
 - Push notifications REQUIRE AppDelegate methods
   (e.g. didRegisterForRemoteNotificationsWithDeviceToken).
   SwiftUI has no replacement for those.

 - NSObject: UIKit delegates are Objective-C protocols, so the class must inherit NSObject.
 - final: nobody subclasses it.
 */
final class AppDelegate: NSObject, UIApplicationDelegate {
    /*
        didFinishLaunchingWithOptions: called ONCE when the app starts,
        BEFORE any SwiftUI view (and so before the map) is created.
        - Return true = launch went fine.
        - Later: Firebase setup and push-notification registration go here too.
        */
       func application(
           _ application: UIApplication,
           didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
       ) -> Bool {

           /*
            Give the API key to Google Maps.
            - Read from Info.plist; "GMSApiKey" must match the key name EXACTLY (capital S).
            - fatalError: crash early with a clear message instead of a blank grey map.
            */
           guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
                 !apiKey.isEmpty else {
               fatalError("GMSApiKey missing from Info.plist")
           }
           GMSServices.provideAPIKey(apiKey)

           // LATER (push notifications): application.registerForRemoteNotifications()

           return true
       }

       // LATER (push notifications): add these two here
       // func application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
       // func application(_:didFailToRegisterForRemoteNotificationsWithError:)
   }
