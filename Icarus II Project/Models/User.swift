//
//  User.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 25/05/26.
//

import Foundation

/// An app-level user profile. `id` matches the Firebase Auth user's UID.
struct User: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var displayName: String
    var avatarURL: URL? = nil
    var createdAt: Date? = nil
    var updatedAt: Date? = nil
}
