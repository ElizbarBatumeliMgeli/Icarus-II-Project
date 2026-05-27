//
//  LocalProfileStore.swift
//  Icarus II Project
//
//  Created by Gianluca Pascarella on 26/05/2026.
//

import Foundation
import os

/// A quick local cache for the user's profile. We use this to keep the UI feeling snappy while we wait for the real data to sync with Firebase.
@MainActor
final class LocalProfileStore {
    static let shared = LocalProfileStore()
    
    private let databaseKey = "saved_apple_profile_dict"
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "IcarusII", category: "ProfileStore")
    
    func saveProfile (_ profile: AppleUserProfile) {
        var allProfiles = fetchAllProfiles()
        allProfiles[profile.userID] = profile
        do {
            let encoded = try JSONEncoder().encode(allProfiles)
            UserDefaults.standard.set(encoded, forKey: databaseKey)
            logger.info("Profile Saved") } catch {
                logger.error("Failed to save Profile")
            }
    }
    
    func fetchProfile(for userID: String) -> AppleUserProfile? {
        return fetchAllProfiles()[userID]
    }
    private func fetchAllProfiles() -> [String: AppleUserProfile] {
        guard let data = UserDefaults.standard.data(forKey: databaseKey) else { return [:] }
        do {
            return try JSONDecoder().decode([String: AppleUserProfile].self, from: data)
        } catch {
            logger.error("Failed to decode profiles")
            return [:]
        }
    }
}

