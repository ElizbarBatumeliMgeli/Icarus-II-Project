//
//  LocalProfileStore.swift
//  Icarus II Project
//
//  Created by Gianluca Pascarella on 26/05/2026.
//

import Foundation
import os

/// A quick local cache for the user's profile. We use this to keep the UI feeling snappy while we wait for the real data to sync with Firebase.
struct LocalProfileStore {
    
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "IcarusII", category: "ProfileStore")
    
    /// Generates a unique key for storing the profile in UserDefaults
    private static func key(for userID: String) -> String {
        return "profile_\(userID)"
    }
    
    static func saveProfile(_ profile: AppleUserProfile) {
        do {
            let encoded = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(encoded, forKey: key(for: profile.userID))
            logger.info("Profile Saved locally for user: \(profile.userID)")
        } catch {
            logger.error("Failed to save Profile: \(error.localizedDescription)")
        }
    }
    
    static func fetchProfile(for userID: String) -> AppleUserProfile? {
        guard let data = UserDefaults.standard.data(forKey: key(for: userID)) else { return nil }
        do {
            return try JSONDecoder().decode(AppleUserProfile.self, from: data)
        } catch {
            logger.error("Failed to decode profile: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func deleteProfile(for userID: String) {
        UserDefaults.standard.removeObject(forKey: key(for: userID))
    }
}
