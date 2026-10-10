//
//  AuthService.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 09/10/26.
//

import Foundation
import Combine

/*
 AuthState: same 3 states as Latest's KMP AuthenticationState.
 - unauthenticated: never logged in / logged out  -> show login
 - authenticated:   we have tokens                -> show map/home
 - sessionExpired:  refresh token died            -> ask to log in again
 */
enum AuthState: Equatable {
    case unauthenticated
    case authenticated
    case sessionExpired
}
/*
 AuthService: the ONLY auth object the UI uses.
 - ObservableObject + @Published state -> SwiftUI redraws when it changes
   (Latest: MutableStateFlow observed by RootViewModel).
 - Runs on the MainActor (project default), so updating `state` is UI-safe.
 - Injected with .environmentObject, exactly like Presenter.
 */
final class AuthService: ObservableObject {
    
    // private(set): screens can READ state, only AuthService can change it
    @Published private(set) var state: AuthState
    
    private let api: AuthAPI
    private let store: TokenStore
    let tokenManager: TokenManager      // other services use this to get a valid token
    
    var isLoggedIn: Bool { state == .authenticated }
    
    init(api: AuthAPI = URLSessionAuthAPI(), store: TokenStore = TokenStore()) {
        self.api = api
        self.store = store
        self.tokenManager = TokenManager(store: store, api: api)
        
        /*
         Starting state from the Keychain (Latest: init { getTokenInformation() }).
         We check the REFRESH token, not the access token: an expired access
         token is fine, TokenManager will refresh it on the first call.
         */
        state = store.hasRefreshToken ? .authenticated : .unauthenticated
        print("👤 auth start state:", state)
    }
    /*
        login: call server -> save both tokens -> flip state.
        Throws AuthError so the Login screen can show error.localizedDescription.
        */
       func login(email: String) async throws {
           let tokens = try await api.login(email: email)
           store.save(tokens)
           state = .authenticated
           print("👤 logged in:", email)
       }

       /*
        logout: tell the server (best effort, Latest also ignores failures here),
        then ALWAYS wipe local tokens so the user is logged out even offline.
        */
       func logout() async {
           if let refreshToken = store.load()?.refreshToken {
               await api.logout(refreshToken: refreshToken)
           }
           store.clear()
           state = .unauthenticated
           print("👤 logged out")
       }

       /*
        accessToken: what future API calls (user-info, etc.) use.
        Wraps TokenManager and catches .sessionExpired to flip the state.
        This is our version of Latest's tokenHandler.setSessionExpired().
        */
       func accessToken(forceRefresh: Bool = false) async throws -> String {
           do {
               return try await tokenManager.validAccessToken(forceRefresh: forceRefresh)
           } catch AuthError.sessionExpired {
               state = .sessionExpired
               print("👤 session expired")
               throw AuthError.sessionExpired
           }
       }
   }
