//
//  JWT.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 08/10/26.
//

import Foundation

/*
 JWTPayload: the fields ("claims") inside the token's middle part.
 Must match what server.js puts in createJwt():
   { sub, email, iat, exp }
 - Decodable: JSONDecoder can build it from the decoded JSON.
 - exp / iat are Unix time = seconds since 1 Jan 1970.
 - Optional fields (?) = the app still works if the server omits them.
 */
nonisolated struct JWTPayload: Decodable, Sendable {
    let sub: String?          // subject = user id
    let email: String?
    let iat: TimeInterval?    // issued at
    let exp: TimeInterval     // expires at (REQUIRED, it's the whole point)

    // Convenience: exp as a Swift Date
    var expiresAt: Date { Date(timeIntervalSince1970: exp) }
}
/*
 JWT: helper functions to READ a token. Same job as Latest's JwtUtil.
 - enum with no cases = a namespace (can't be created by accident).
 - nonisolated: pure logic, no UI. TokenManager (Step 5) calls it off the main thread.
 */
nonisolated enum JWT {

    enum DecodeError: Error {
        case wrongFormat          // not 3 parts separated by "."
        case invalidBase64
        case invalidJSON
    }

    /*
     decode: token string -> JWTPayload.
     1. Split on "." -> [header, payload, signature]
     2. Take the payload (index 1)
     3. Base64URL -> Data
     4. JSON -> JWTPayload
     */
    static func decode(_ token: String) throws -> JWTPayload {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { throw DecodeError.wrongFormat }

        guard let data = base64URLDecode(String(parts[1])) else {
            throw DecodeError.invalidBase64
        }

        do {
            return try JSONDecoder().decode(JWTPayload.self, from: data)
        } catch {
            throw DecodeError.invalidJSON
        }
    }
    /*
         isExpired: should we stop using this token?
         - leeway 60 s (same as Latest): treat it as expired a minute EARLY,
           so it can't expire in the middle of a network request.
         - Expired when: exp <= now + 60
             61 s left -> false (still fine)
             60 s left -> true  (refresh now)
         - Can't decode it? Treat as expired -> forces a refresh (safe default).
         - `now` is a parameter so tests can pass a fixed time.
         */
        static func isExpired(_ token: String,
                              leeway: TimeInterval = 60,
                              now: Date = Date()) -> Bool {
            guard let payload = try? decode(token) else { return true }
            return payload.exp <= now.timeIntervalSince1970 + leeway
        }

        /*
         base64URLDecode: JWTs use "Base64URL", a URL-safe variant of Base64:
         - uses "-" and "_" instead of "+" and "/"
         - drops the "=" padding at the end
         Swift's Data(base64Encoded:) only understands normal Base64,
         so we convert back first.
         */
        private static func base64URLDecode(_ string: String) -> Data? {
            var base64 = string
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")

            // Base64 length must be a multiple of 4: add "=" padding back
            let remainder = base64.count % 4
            if remainder > 0 {
                base64 += String(repeating: "=", count: 4 - remainder)
            }
            return Data(base64Encoded: base64)
        }
    }
