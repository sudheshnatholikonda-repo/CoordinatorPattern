//
//  Signup.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 05/10/26.
//

import SwiftUI
/*
 SignupView: shown as a BOTTOM SHEET (.signup.isFullScreen == false).
 - It can read the Presenter because RootView passes
   .environmentObject(presenter) into the .sheet (Step 4).
 */

struct SignupView: View {
    @EnvironmentObject private var presenter: Presenter

    var body: some View {
        ZStack {
                   Color.white.ignoresSafeArea()

                   VStack(spacing: 20) {
                       Text("Signup")
                           .font(.largeTitle.bold())
                           .foregroundStyle(.black)

                       /*
                        Close -> back to WELCOME
                        dismiss() closes only the TOP item, which is the sheet.
                        - sheet = nil
                        - fullScreenStack stays [welcome] -> Welcome is visible again
                        (Same result as dragging the sheet down.)
                        */
                       Button("Close") {
                           presenter.dismiss()
                       }
                       .buttonStyle(.bordered)

                       /*
                        Go to Map -> ONLY THE MAP
                        dismissAll() (Step C) clears everything:
                        - sheet = nil          -> Signup slides down
                        - fullScreenStack = [] -> Welcome slides out to the right
                        Nothing covers RootView's base layer -> the map shows.
                        */
                       Button("Go to Map") {
                           presenter.dismissAll()
                       }
                       .buttonStyle(.borderedProminent)
                   }
               } // ZStack
    }
}


#Preview {
    SignupView()
        .environmentObject(Presenter())
}
