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
    
    var id: String {
        switch self {
        case .splash: "splash"
        case .welcome: "welcome"
        case .signup: "signup"
        }
    }
    
    @ViewBuilder @MainActor
    var view: some View {
        switch self {
        case .splash: SplashView()
        case .welcome: WelcomeView()
        case .signup: SignupView()
        }
    }
   
    /*
     var id: String:  gives an identity for the enum case.
    
     var view: some View:  returns the actual SwiftUI screen for that case.
     */
    
    var isFullScreen: Bool {
            switch self {
                //Since both cases do the same thing, Swift lets you combine them:
            case .splash, .welcome: true
            case .signup : false
            }
        }
}

extension Destination: Equatable, Hashable {
    static func == (lhs: Destination, rhs: Destination) -> Bool { lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
