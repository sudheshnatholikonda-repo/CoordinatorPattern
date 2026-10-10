//
//  SplashView.swift
//  CoordinatorPattern
//
//  Created by Sudheshna on 3/10/2026.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var presenter: Presenter
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        ZStack {
               Color.black.ignoresSafeArea()
               Text("SPLASH")
                   .font(.largeTitle.bold())
                   .foregroundStyle(.white)
           }//ZStack
        /*
         .task { } runs some work when a SwiftUI view appears. some async work
         onAppear vs .task is designed to work naturally with Swift concurrency
         SwiftUI manages the task's lifetime. If the view disappears, SwiftUI can cancel that task.
         .task can run again if the view is recreated or appears again. It is not automatically “run once for the entire app
         .task is a view modifier. It must be attached to a view.
         */

        
        .task {
            /*
            // TEMP: actor test. Delete after checking.
            let fake = FakeAuthAPI()
            // Separate Keychain service so it doesn't touch your real login tokens
            let store = TokenStore(keychain: KeychainStore(service: "actor-test"))
            // "old" isn't a real JWT -> JWT.isExpired says true -> a refresh is needed
            store.save(AuthTokens(accessToken: "old", refreshToken: "r0"))
            let manager = TokenManager(store: store, api: fake)

            // 10 callers at the SAME time (like 10 API requests firing together)
            let tokens = await withTaskGroup(of: String?.self) { group in
                for _ in 1...10 {
                    group.addTask { try? await manager.validAccessToken() }
                }
                var results: [String?] = []
                for await token in group { results.append(token) }
                return results
            }

            print("🧪 refresh calls:", await fake.refreshCount)            // expect 1
            print("🧪 tokens:", Set(tokens.compactMap { $0 }))              // expect ["new-1"]
            store.clear()
            */
            
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            print(authService.isLoggedIn)
            if authService.isLoggedIn {
                presenter.dismissAll()
            } else {
                presenter.replaceAll(with: .welcome)
            }
        }
        /*
         Task { } creates a new Swift concurrency task manually.
         “Start this async work now.”
         we can use inside view
         */
    }
}
/*
actor FakeAuthAPI: AuthAPI {
    private(set) var refreshCount = 0

    func login(email: String) async throws -> AuthTokens {
        AuthTokens(accessToken: "old", refreshToken: "r0")
    }

    func refresh(refreshToken: String) async throws -> AuthTokens {
        refreshCount += 1
        print("🛰️ fake refresh #\(refreshCount) called")
        try await Task.sleep(for: .milliseconds(500))
        return AuthTokens(accessToken: "new-\(refreshCount)", refreshToken: "r\(refreshCount)")
    }

    func logout(refreshToken: String) async {}
}
*/
#Preview {
    SplashView()
        .environmentObject(Presenter())
        .environmentObject(AuthService())
}
