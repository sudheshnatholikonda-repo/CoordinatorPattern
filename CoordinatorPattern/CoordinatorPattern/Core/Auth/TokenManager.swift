//
//  TokenManager.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 09/10/26.
//

import Foundation
/*
 TokenManager: hands out a VALID access token, refreshing when needed.
 Same job as Latest's TokenManagerImpl.

 actor:
 - Its properties can only be touched by one caller at a time, so `refreshTask`
   can't be corrupted by two threads (Latest uses a Mutex for this).
 - Runs OFF the main thread, so network + Keychain work never freezes the UI.
 - Callers must `await` its methods.
 */
actor TokenManager {

    private let store: TokenStore    // Step 3: Keychain pair
    private let api: AuthAPI         // Step 4: server calls

    /*
     refreshTask: the refresh currently in progress (nil = none).
     While it's set, every other caller WAITS for it instead of starting
     its own. This prevents the "two refreshes with the same token" bug.
     */
    private var refreshTask: Task<AuthTokens, Error>?

    /*
     Defaults = the real pieces. Tests can pass a fake AuthAPI.
     */
    init(store: TokenStore = TokenStore(),
         api: AuthAPI = URLSessionAuthAPI()) {
        self.store = store
        self.api = api
    }

    /*
     validAccessToken: THE function every API call uses.
     - forceRefresh: true when the server rejected a token we thought was valid
       (e.g. it got a 401), the same flag Latest has.
     - Throws AuthError.sessionExpired when the user must log in again.
     */
    func validAccessToken(forceRefresh: Bool = false) async throws -> String {

        // 1. Someone is already refreshing -> wait for their result
        if let refreshTask {
            print("⏳ waiting for refresh already in progress")
            return try await refreshTask.value.accessToken
        }

        // 2. Nothing saved -> not logged in
        guard let tokens = store.load() else {
            throw AuthError.sessionExpired
        }

        // 3. Still valid -> use it (no network call)
        if !forceRefresh && !JWT.isExpired(tokens.accessToken) {
            print("✅ using cached access token")
            return tokens.accessToken
        }

        // 4. Expired -> refresh (only this caller starts it)
        return try await refresh(using: tokens.refreshToken).accessToken
    }
    /*
         refresh: starts ONE refresh Task and stores it in refreshTask,
         so callers arriving during the network wait join it (step 1 above).

         - [api, store]: copy them into the Task (both are Sendable).
         - defer { refreshTask = nil }: runs AFTER `await task.value` finishes,
           success OR failure, so the next expiry can refresh again.
         */
        private func refresh(using refreshToken: String) async throws -> AuthTokens {
            print("⏰ access token expired -> refreshing")

            let task = Task { [api, store] in
                do {
                    let newTokens = try await api.refresh(refreshToken: refreshToken)
                    store.save(newTokens)            // rotation: save BOTH new tokens
                    print("🔐 saved new token pair")
                    return newTokens
                } catch AuthError.sessionExpired {
                    // Refresh token is dead -> wipe everything (Latest: setSessionExpired)
                    store.clear()
                    print("🚪 session expired -> tokens cleared")
                    throw AuthError.sessionExpired
                }
            }

            refreshTask = task
            defer { refreshTask = nil }
            return try await task.value
        }
    }
