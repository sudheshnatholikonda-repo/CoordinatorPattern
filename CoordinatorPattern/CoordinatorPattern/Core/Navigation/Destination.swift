//
//  Destination.swift
//  CoordinatorPattern
//
//  Created by Sudheshna on 3/10/2026.
//

import SwiftUI
/*
 Destination is the enum
 Identifiable says every destination must have an id
 */
enum Destination: Identifiable {
    case splash
    case welcome
    case signup
    case entry
    case drill
    case urgent
    case login
    
    var id: String {
        switch self {
        case .splash: "splash"
        case .welcome: "welcome"
        case .signup: "signup"
        case .entry: "entry"
        case .drill: "drill"
        case .urgent: "urgent"
        case .login: "login"
        }
    }
    
    @ViewBuilder @MainActor
    var view: some View {
        switch self {
        case .splash: SplashView()
        case .welcome: WelcomeView()
        case .signup: SignupView()
        case .entry: EntryView()
        case .drill: DrillView()
        case .urgent: UrgentView()
        case .login: LoginView()
        }
    }
   
    /*
     var id: String:  gives an identity for the enum case.
    
     var view: some View:  returns the actual SwiftUI screen for that case.
     */
    
    var isFullScreen: Bool {
            switch self {
                //Since both cases do the same thing, Swift lets you combine them:
            case .splash, .welcome, .login: true
            case .signup, .entry, .drill, .urgent : false
            }
        }
    
    /*
        NEW
        isDragToDismissEnabled: can the user close this SHEET by dragging it down?
        - true  -> drag down OR Close button
        - false -> Close button ONLY
        Same idea as Latest's DestinationSheetConfiguration.isDragToDismissEnabled.
        Only matters for sheets (isFullScreen == false); full screens can't be dragged anyway.
        */
       var isDragToDismissEnabled: Bool {
           switch self {
           case .entry, .drill, .urgent, .login:       false   // Close button only
           case .splash, .welcome, .signup:    true
           }
       }
}

extension Destination: Equatable, Hashable {
    static func == (lhs: Destination, rhs: Destination) -> Bool { lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
