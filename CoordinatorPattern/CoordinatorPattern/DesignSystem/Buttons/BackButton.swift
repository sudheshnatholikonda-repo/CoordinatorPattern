//
//  BackButton.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 09/10/26.
//

import SwiftUI

/*
 BackButton: the reusable "‹" button (UI only).
 - Lives in DesignSystem, next to FeatureButton (Latest: CircularIconButton in Design/).
 - It does NOT navigate by itself. It just calls `action`,
   so it can be reused for "dismiss", "go to step 1", etc.
 */
struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)   // Apple's minimum tap size
        }
        .accessibilityLabel("Back")             // VoiceOver says "Back"
    }
}

/*
 BackButtonModifier: pins BackButton to the top-left of ANY screen
 and connects it to the Presenter.
 - Reads the Presenter from the environment, like every screen does.
 - Default action = presenter.dismiss()  (pop the top screen / close the sheet).
 - Pass a custom action if a screen needs something else.
 */
struct BackButtonModifier: ViewModifier {
    @EnvironmentObject private var presenter: Presenter
    var action: (() -> Void)?

    func body(content: Content) -> some View {
        content
            /*
             .overlay(alignment: .topLeading): drawn ON TOP of the screen,
             top-left corner, inside the safe area (below the notch).
             It doesn't move the screen's own layout.
             */
            .overlay(alignment: .topLeading) {
                BackButton {
                    if let action {
                        action()               // custom behaviour
                    } else {
                        presenter.dismiss()    // the Presenter still does the navigation
                    }
                }
                .padding(.leading, 8)
            }
    }
}

/*
 extension View: so screens write `.backButton()`
 instead of `.modifier(BackButtonModifier())`.
 Same style as SwiftUI's own .padding(), .sheet(), ...
 */
extension View {
    func backButton(action: (() -> Void)? = nil) -> some View {
        modifier(BackButtonModifier(action: action))
    }
}

#Preview {
    Color.white
        .ignoresSafeArea()
        .backButton()
        .environmentObject(Presenter())
}
