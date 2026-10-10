//
//  FreshInstallCleaner.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 10/10/26.
//

import Foundation

/*
 FreshInstallCleaner: same as Latest's FreshInstallCleaner.

 Why:
 - Keychain items SURVIVE app uninstall (iOS keeps them).
 - UserDefaults is DELETED on uninstall.
 So: "flag missing in UserDefaults" == first launch or reinstall
     -> wipe the old tokens so the user starts logged out.

 enum with only static members: a namespace, nobody creates an instance.
 nonisolated: plain logic, not UI (project default is MainActor).
 */
nonisolated enum FreshInstallCleaner {

    // Reverse-DNS style key so it can't clash with other keys
    private static let hasLaunchedBeforeKey = "com.coordinatorpattern.hasLaunchedBefore"

    /*
     Call ONCE at app start, BEFORE AuthService reads the Keychain.
     - defaults / keychain parameters: defaults = real ones, tests can pass fakes.
     */
    static func purgeKeychainIfFreshInstall(
        defaults: UserDefaults = .standard,
        keychain: KeychainStore = KeychainStore()
    ) {
        // 1. Flag already set -> app ran before on this install -> keep tokens
        guard !defaults.bool(forKey: hasLaunchedBeforeKey) else { return }

        print("🧹 fresh install -> clearing old Keychain items")

        /*
         2. Delete everything under our service (access + refresh token).
            removeAll() returns false only on a real error.
            If it fails, DON'T set the flag, so it tries again next launch
            (same rule as Latest: "only consume the sentinel once the purge succeeds").
         */
        guard keychain.removeAll() else {
            print("🧹 Keychain purge failed, will retry next launch")
            return
        }

        // 3. Mark this install as launched
        defaults.set(true, forKey: hasLaunchedBeforeKey)
    }
}
