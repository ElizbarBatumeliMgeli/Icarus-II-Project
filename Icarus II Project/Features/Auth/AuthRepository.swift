//
//  AuthRepository.swift
//  Icarus II Project
//
//  Created by Gianluca Pascarella on 29/05/2026.
//

import Foundation
import os

protocol AuthRepository {
    func saveSession(profile: AppleUserProfile)
    func fetchCurrentSessionProfile() -> AppleUserProfile?
    func fetchProfile(for userID: String) -> AppleUserProfile?
    func clearSession()
}

/// The unified repository for managing the user's authentication session locally.
/// It abstracts away the secure Keychain (for the ID) and UserDefaults (for the cached profile).
struct DefaultAuthRepository: AuthRepository {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "IcarusII", category: "AuthRepository")
    
    func saveSession(profile: AppleUserProfile) {
        // Securely store the sensitive User ID
        KeychainHelper.save(userID: profile.userID)
        
        // Cache the non-sensitive profile info for quick UI access
        LocalProfileStore.saveProfile(profile)
        logger.info("Session saved securely.")
    }
    
    func fetchCurrentSessionProfile() -> AppleUserProfile? {
        guard let savedUserID = KeychainHelper.loadUserID() else {
            return nil
        }
        return LocalProfileStore.fetchProfile(for: savedUserID)
    }
    
    func fetchProfile(for userID: String) -> AppleUserProfile? {
        return LocalProfileStore.fetchProfile(for: userID)
    }
    
    func clearSession() {
        if let savedUserID = KeychainHelper.loadUserID() {
            LocalProfileStore.deleteProfile(for: savedUserID)
        }
        KeychainHelper.deleteUserID()
        logger.info("Session cleared from local storage.")
    }
}
