//
//  AuthAPI.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 09/10/26.
//

import Foundation
/*
 AuthError: everything that can go wrong, in words the app understands.
 Views show `errorDescription`; TokenManager checks `.sessionExpired`.
 - LocalizedError: gives each case a user-facing message.
 - Associated values are Strings / Ints (not `Error`) so it stays Sendable.
 */
nonisolated enum AuthError: LocalizedError, Sendable {
    case invalidCredentials                    // log-in said 401
    case sessionExpired                        // refresh-token said 401 -> must log in again
    case http(status: Int, message: String?)   // any other non-2xx
    case network(String)                       // no connection, server not running...
    case invalidResponse                       // response wasn't the JSON we expected

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:         "Invalid email. Please try again."
        case .sessionExpired:             "Your session has expired. Please log in again."
        case .http(let status, let msg):  msg ?? "Server error (\(status))."
        case .network(let msg):           "Can't reach the server. \(msg)"
        case .invalidResponse:            "Unexpected response from the server."
        }
    }
}

/*
 AuthAPI: the CONTRACT. Anything that can log in and refresh.
 - TokenManager / AuthService depend on THIS, not on URLSession,
   so a fake can be swapped in for tests (dependency inversion).
 - Same two calls as Latest's API:
     POST /api/v1/auth/log-in
     POST /api/v1/auth/refresh-token
 - Sendable: TokenManager (an actor, Step 5) will hold one.
 */
nonisolated protocol AuthAPI: Sendable {
    func login(email: String) async throws -> AuthTokens
    func refresh(refreshToken: String) async throws -> AuthTokens
    func logout(refreshToken: String) async
}

/*
 URLSessionAuthAPI: the real implementation, plain HTTP with URLSession.
 final class + Sendable: immutable `let` properties only, so safe across threads.
 */
nonisolated final class URLSessionAuthAPI: AuthAPI {

    /*
     baseURL: where the server lives.
     - Simulator:   http://localhost:3000   (your node server.js)
     - Real iPhone: http://<Mac's IP>:3000  (ipconfig getifaddr en0)
     Plain http is allowed for localhost / IPs without Info.plist changes.
     */
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = URL(string: "http://localhost:3000")!,
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Request bodies (what we SEND)

    /*
     Encodable structs -> JSON. Field names must match server.js:
       login(body)   reads body.email
       refresh(body) reads body.refreshToken
     (Latest's real log-in also sends password/uuid/deviceName...; our mock only needs email.)
     */
    private struct LoginBody: Encodable { let email: String }
    private struct RefreshBody: Encodable { let refreshToken: String }

    /*
     The server's error JSON: { "error": { "code": "...", "message": "..." } }
     We decode it to show the server's message.
     */
    private struct ServerErrorBody: Decodable {
        struct Detail: Decodable { let code: String; let message: String }
        let error: Detail
    }

    // MARK: - Endpoints

    /*
     login: POST /api/v1/auth/log-in  { email }
     -> AuthTokens (accessToken + refreshToken; extra fields ignored)
     401 -> .invalidCredentials (try "fail@test.com")
     */
    func login(email: String) async throws -> AuthTokens {
        do {
            let data = try await post("/api/v1/auth/log-in", body: LoginBody(email: email))
            print("🌐 log-in OK:", email)
            return try decodeTokens(data)
        } catch AuthError.http(status: 401, _) {
            throw AuthError.invalidCredentials
        }
    }

    /*
     refresh: POST /api/v1/auth/refresh-token  { refreshToken }
     -> a NEW pair (rotation: the old refresh token stops working)
     401 -> .sessionExpired (refresh token used twice, expired, or unknown)
     */
    func refresh(refreshToken: String) async throws -> AuthTokens {
        do {
            let data = try await post("/api/v1/auth/refresh-token",
                                      body: RefreshBody(refreshToken: refreshToken))
            print("🌐 refresh-token OK: new pair")
            return try decodeTokens(data)
        } catch AuthError.http(status: 401, _) {
            print("🌐 refresh-token 401: session expired")
            throw AuthError.sessionExpired
        }
    }

    /*
     logout: POST /api/v1/auth/log-out  { refreshToken }
     Tells the server to revoke the refresh token.
     No `throws`: we log out locally even if the server can't be reached.
     */
    func logout(refreshToken: String) async {
        _ = try? await post("/api/v1/auth/log-out", body: RefreshBody(refreshToken: refreshToken))
        print("🌐 log-out sent")
    }

    // MARK: - Helpers

    /*
     post: shared code for every POST.
     1. Build the request (URL + method + JSON header + JSON body)
     2. Send it (async: suspends here without blocking the UI)
     3. Non-2xx -> throw .http(status, server message)
     4. Return the raw response bytes
     */
    private func post<Body: Encodable>(_ path: String, body: Body) async throws -> Data {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            // e.g. server not running -> "Could not connect to the server."
            throw AuthError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ServerErrorBody.self, from: data))?.error.message
            throw AuthError.http(status: http.statusCode, message: message)
        }
        return data
    }

    // JSON -> AuthTokens, or .invalidResponse if the fields are missing
    private func decodeTokens(_ data: Data) throws -> AuthTokens {
        do {
            return try JSONDecoder().decode(AuthTokens.self, from: data)
        } catch {
            throw AuthError.invalidResponse
        }
    }
}
