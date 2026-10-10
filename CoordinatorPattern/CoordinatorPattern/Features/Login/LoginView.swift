//
//  LoginView.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 09/10/26.
//

import SwiftUI

/*
 LoginView: email field + "Log in" button.
 - Talks ONLY to AuthService (never to the API / Keychain directly).
 - Does NOT navigate after success. AuthService.state becomes .authenticated
   and RootView (Step 7b) moves to the map. Same as Latest:
   the screen updates state, RootViewModel does the routing.
 */
struct LoginView: View {
    @EnvironmentObject private var presenter: Presenter
    @EnvironmentObject private var authService: AuthService

    /*
     @State: local screen state, owned by this view.
     - email:        what the user typed
     - isLoading:    true while the request is running (disables the button)
     - errorMessage: text shown under the button when login fails
     */
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()   // full screen: cover the map behind

            VStack(spacing: 20) {
                Text("Log in")
                    .font(.largeTitle.bold())

                /*
                 TextField bound to $email: typing updates `email`.
                 The modifiers give an email keyboard with no auto-capital
                 or autocorrect, so "me@test.com" isn't changed to "Me@test.com".
                 */
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.gray.opacity(0.15), in: .rect(cornerRadius: 10))

                Button {
                    Task { await login() }    // Button actions aren't async -> start a Task
                } label: {
                    if isLoading {
                        ProgressView()        // spinner while waiting for the server
                    } else {
                        Text("Log in").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isEmailValid || isLoading)   // no empty / double submits

                // Error text: AuthError.errorDescription (from Step 4)
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                // Back -> pops Login, Welcome shows again
//                Button("Back") {
//                    presenter.dismiss()
//                }
//                .buttonStyle(.bordered)

                Spacer()
            }
            
            .padding(24)
            .padding(.top, 40)
        }
        .backButton()
    }

    /*
     Very simple check: something@something. The server is the real judge.
     trimmingCharacters removes accidental spaces from autofill/paste.
     */
    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isEmailValid: Bool {
        trimmedEmail.contains("@") && trimmedEmail.contains(".")
    }

    /*
     login: call AuthService, show any error.
     - defer: isLoading goes back to false whether it succeeds or throws.
     - Success: nothing to do here. state -> .authenticated, and RootView reacts (7b).
     */
    private func login() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authService.login(email: trimmedEmail)
        } catch {
            // e.g. fail@test.com -> "Invalid email or password." (AuthError.invalidCredentials)
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(Presenter())
        .environmentObject(AuthService())
}
