//
//  CoordinatorPatternApp.swift
//  CoordinatorPattern
//
//  Created by Sudheshna on 3/10/2026.
//

import SwiftUI
/*
  read mode only, I'm creating the navigation pattern exact flow using in this app into another app
 /Users/sudheshnatholikonda/Downloads/CoordinatorPattern/CoordinatorPattern.xcodeproj for understanding this project. guide me one by one, dnt pour all. give me what file to open, what folder and code also
 give me the code with explaination in comment as it follow in CoordinatorPattern
 */

@main
struct CoordinatorPatternApp: App {
    /*
         NEW: @UIApplicationDelegateAdaptor connects AppDelegate to SwiftUI.
         - SwiftUI creates ONE AppDelegate and calls its methods
           (didFinishLaunching, push callbacks, ...) at the right times.
         - You never call AppDelegate yourself.
         */
        @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    /*
         The App creates the ONE Presenter for the whole app.

         - @StateObject: SwiftUI creates it once and keeps it alive for the app's lifetime.
           (If you used @ObservedObject here, it could be recreated and you'd lose the stack.)
         - private: only the App owns it; others get it through the environment (below).
         */
        @StateObject private var presenter = Presenter()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            /*
                        .environmentObject: puts the Presenter into the SwiftUI environment.
                        Every view BELOW this one can now grab it with:
                            @EnvironmentObject private var presenter: Presenter
                        No need to pass it through every initializer by hand.
                        */
                           .environmentObject(presenter)
        }
    }
}
