//
//  ContentView.swift
//  CoordinatorPattern
//
//  Created by Sudheshna on 3/10/2026.
//

import SwiftUI

struct ContentView: View {
    /*
        @EnvironmentObject: grabs the ONE Presenter that the App put in the environment
        (CoordinatorPatternApp: .environmentObject(presenter)).
        - No initializer argument needed.
        - If you forget .environmentObject(...) higher up, the app CRASHES here.
        */
    @EnvironmentObject private var presenter: Presenter
    
   
    var body: some View {
        /*
                ZStack: back to front.
                - FIRST item = furthest back  -> the map (always there)
                - then the full screens on top -> Splash / Welcome cover the map
                - the sheet isn't in here: .sheet(item:) below draws it above everything
                */
        ZStack {
            /*
                         NEW: BASE LAYER
                         MapView: always on screen, at the very back.
                         - It is NOT in fullScreenStack, so present / dismiss /
                           replaceAll / dismissAll never remove it.
                         - While Splash or Welcome are showing, they cover it completely
                           (both have a full-screen background colour).
                         - When the stack is empty (dismissAll), nothing covers it,
                           so the map is what the user sees and can touch.
                         - Created at launch, so it's already loaded when revealed (no blank flash).
                         */
                        MapView()
            /*
             ForEach over the stack: draws one view per Destination.
             - Works because Destination is Identifiable (the `id` from Step 2).
             - destination.view: the enum turns the case into the real screen
               (.splash -> SplashView, .welcome -> WelcomeView).
             - .transition(.move(edge: .trailing)): a screen slides in from the right
               when it's added and slides out to the right when it's removed.
             */
            ForEach(presenter.fullScreenStack) { destination in
                destination.view
                    .transition(.move(edge: .trailing))
            } // ForEach
        } // ZStack

        /*
         .animation(_, value:): animates whenever fullScreenStack changes.
         - Needs Destination to be Equatable (the extension in Step 2)
           so SwiftUI can compare the old and new stack.
         - Without this line, .transition above does nothing (screens just pop in).
         */
        .animation(.default, value: presenter.fullScreenStack)
        
        /*
                NEW: BOTTOM SHEET
                .sheet(item:): SwiftUI's built-in bottom sheet. It slides UP from the bottom.
                - item: presenter.sheetBinding (the Binding from Step 2).
                    • sheet becomes .signup -> the sheet slides up showing SignupView
                    • sheet becomes nil     -> the sheet slides down
                    • user SWIPES it down   -> SwiftUI calls set(nil), so
                      presenter.sheet stays in sync automatically
                - Needs Destination to be Identifiable (it is).
                - No .transition needed: SwiftUI animates sheets by itself.
                - environmentObject is passed again so the sheet's view can read the
                  Presenter, e.g. to call presenter.dismiss().
                */
        
        .sheet(item: presenter.sheetBinding) { destination in
                   destination.view
                       .environmentObject(presenter)
               }

        /*
         .onAppear: runs when ContentView first shows.
         - The stack starts EMPTY (Presenter: = []), so we push the first screen here.
         - isEmpty check: prevents pushing .splash again if onAppear fires a second time.
         */
        .onAppear {
            if presenter.fullScreenStack.isEmpty {
                presenter.present(.splash)
            }
        }
    }
}
#Preview {
    ContentView()
        .environmentObject(Presenter())
}

