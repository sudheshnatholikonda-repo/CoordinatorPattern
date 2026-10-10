//
//  KeychainStore.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 08/10/26.
//

import Foundation
import Security   // Apple's Keychain API (the SecItem... functions)

/*
 KeychainStore: save / read / delete STRINGS in the iOS Keychain.

 How the Keychain identifies an item:
 - kSecClass = kSecClassGenericPassword -> "a generic secret" (tokens, passwords)
 - kSecAttrService = our app's id      -> groups all OUR items together
 - kSecAttrAccount = the key           -> e.g. "access_token", "refresh_token"
 So (service + account) is like a dictionary key.

 nonisolated:
 - Your project makes everything @MainActor by default.
 - Keychain calls don't touch the UI, and TokenManager (Step 5) will call
   this from a background actor, so we opt OUT of the main actor here.
 - Sendable: safe to share between threads (it only holds a String).
 */
nonisolated struct KeychainStore: Sendable {
    /*
         service: groups our items. Latest uses "com.duress.mobile";
         we use the app's bundle id (e.g. "com.yourname.CoordinatorPattern").
         */
        let service: String

        init(service: String = Bundle.main.bundleIdentifier ?? "CoordinatorPattern") {
            self.service = service
        }

        /*
         baseQuery: the fields every Keychain call shares (class + service + account).
         Each method below adds its own extra fields to this.
         */
        private func baseQuery(for key: String) -> [String: Any] {
            [
                kSecClass as String:       kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]
        }
    
    // MARK: - Save

       /*
        set: save (or overwrite) a string for a key.
        - Keychain stores Data, so the String is converted to UTF-8 bytes.
        - Tries UPDATE first; if the item doesn't exist yet, ADDs it
          (Latest's addOrUpdate does the same).
        - Returns true on success.
        */
       @discardableResult
       func set(_ value: String, for key: String) -> Bool {
           //The _ means you don't need to write the parameter name when calling the function.
           let data = Data(value.utf8)

           // 1. Try to update an existing item
        //   This creates a dictionary containing the new value we want to store in Keychain.
           
           let attributes: [String: Any] = [kSecValueData as String: data]
           let updateStatus = SecItemUpdate(baseQuery(for: key) as CFDictionary,
                                            attributes as CFDictionary)
           if updateStatus == errSecSuccess { return true } //Updated successfully

           // 2. Not found -> add a new one
           guard updateStatus == errSecItemNotFound else { return false }

           var addQuery = baseQuery(for: key)
           addQuery[kSecValueData as String] = data
           /*
            kSecAttrAccessibleWhenUnlocked: readable only while the phone is
            unlocked (same setting as Latest). Good default for tokens.
            */
           addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
           return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
       }
    // MARK: - Read

        /*
         string(for:): read the string for a key, or nil if nothing is saved.
         - kSecReturnData: "give me the bytes back".
         - kSecMatchLimitOne: we only expect one item.
         - SecItemCopyMatching fills `result` with the Data.
         */
        func string(for key: String) -> String? {
            var query = baseQuery(for: key)
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            guard status == errSecSuccess, let data = result as? Data else { return nil }
            return String(data: data, encoding: .utf8)
        }

        // MARK: - Delete

        /*
         remove: delete one key (e.g. on logout).
         errSecItemNotFound counts as success (nothing to delete = already gone).
         */
        @discardableResult
        func remove(_ key: String) -> Bool {
            let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
            return status == errSecSuccess || status == errSecItemNotFound
        }

        /*
         removeAll: delete EVERY item for our service (no account = match all).
         Used by FreshInstallCleaner in Step 8 (Latest's clear()).
         */
        @discardableResult
        func removeAll() -> Bool {
            let query: [String: Any] = [
                kSecClass as String:       kSecClassGenericPassword,
                kSecAttrService as String: service
            ]
            let status = SecItemDelete(query as CFDictionary)
            return status == errSecSuccess || status == errSecItemNotFound
        }
}
