//
//  TokenStore.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 09/10/26.
//

import Foundation
/*
 AuthTokens: the PAIR the server returns from log-in and refresh-token.
 Same as Latest's TokenInformation.
 - Decodable: Step 4 decodes it straight from the server's JSON.
   The log-in response has extra fields (id, firstname...) and
   JSONDecoder simply ignores fields we don't list.
 - Equatable: lets us compare pairs (handy in tests / debugging).
 - Sendable: safe to pass between threads (TokenManager is an actor, Step 5).
 */
nonisolated struct AuthTokens: Decodable, Equatable, Sendable {
    let accessToken: String     // JWT, short-lived, sent with every API call
    let refreshToken: String    // long-lived, ONLY used to get a new pair
}
/*
 TokenStore: save / load / clear the token pair in the Keychain.
 - The only place that knows the Keychain KEY NAMES.
 - Wraps KeychainStore (Step 1); doesn't call Apple's API itself.
 */
nonisolated struct TokenStore: Sendable {

    /*
     Key names: the same strings Latest uses
     (AuthenticationRepository.KEY_ACCESS_TOKEN / KEY_REFRESH_TOKEN).
     private enum: a namespace for constants, so there are no typos elsewhere.
     */
    private enum Key {
        static let accessToken  = "access_token"
        static let refreshToken = "refresh_token"
    }

    private let keychain: KeychainStore

    /*
     keychain is a parameter (with a default) so tests can pass
     a KeychainStore with a different service name.
     */
    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    /*
     save: store BOTH tokens.
     Called after log-in AND after every refresh (rotation = both change).
     Same as Latest's storeTokens().
     */
    func save(_ tokens: AuthTokens) {
        keychain.set(tokens.accessToken,  for: Key.accessToken)
        keychain.set(tokens.refreshToken, for: Key.refreshToken)
    }

    /*
     load: the saved pair, or nil if EITHER is missing.
     (Half a pair is useless: treat it as "not logged in".)
     Same as Latest's getTokenInformation().
     */
    func load() -> AuthTokens? {
        guard let access  = keychain.string(for: Key.accessToken),
              let refresh = keychain.string(for: Key.refreshToken) else {
            return nil
        }
        return AuthTokens(accessToken: access, refreshToken: refresh)
    }
    /*
        hasRefreshToken: "is there a session to restore?"
        Splash uses this on launch (Step 7): yes -> map, no -> login.
        Checks the REFRESH token, not the access token: an expired access
        token is fine, because we can refresh it. Same as Latest's hasRefreshToken().
        */
       var hasRefreshToken: Bool {
           keychain.string(for: Key.refreshToken) != nil
       }

       /*
        clear: delete both tokens (logout / session expired).
        Same as Latest's clearAuthentication().
        */
       func clear() {
           keychain.remove(Key.accessToken)
           keychain.remove(Key.refreshToken)
       }
   }
