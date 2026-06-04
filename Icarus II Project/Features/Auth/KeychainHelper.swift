//
//  KeychainHelper.swift
//  Icarus II Project
//
//  Created by Gianluca Pascarella on 26/05/2026.
//

import Foundation
import Security
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "IcarusII", category: "Keychain")

/// A simple, secure vault for the Apple User ID. We don't want this floating around in UserDefaults!
enum KeychainHelper {
    private static let service = Bundle.main.bundleIdentifier ?? "com.icarus-ii"
    private static let userIDKey = "apple_user_id"

    static func save(userID: String) {
        // Remove any existing entry before writing.
        deleteUserID()

        guard let data = userID.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String:  service,
            kSecAttrAccount as String:  userIDKey,
            kSecValueData as String:    data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            logger.error("Failed to save userID to Keychain (status \(status)).")
        }
    }

    static func loadUserID() -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String:  service,
            kSecAttrAccount as String:  userIDKey,
            kSecReturnData as String:   true,
            kSecMatchLimit as String:   kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    static func deleteUserID() {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String:  service,
            kSecAttrAccount as String:  userIDKey
        ]

        SecItemDelete(query as CFDictionary)
    }
}
