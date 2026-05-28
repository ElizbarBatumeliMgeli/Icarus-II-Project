//
//  User.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI

// App-level user profile. `id` matches the Firebase Auth UID
// Stored fields are persisted to Firestore; `displayName`, `name`, and `avatarColor` are computed so the UI can read them without extra storage.
struct User: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var firstName: String = ""
    var lastName: String = ""
    var avatarColorHex: String = "D3D3D3"     // UI avatar color, persisted as hex (no "#").
    var connectionCode: String = ""           // Permanent, shareable code other users enter to connect.
    var connections: [String] = []            // Ids of users this user is mutually connected to.
    var avatarURL: URL? = nil
    var createdAt: Date? = nil
    var updatedAt: Date? = nil

    enum CodingKeys: String, CodingKey {
        case id, firstName, lastName, avatarColorHex, connectionCode, connections, avatarURL, createdAt, updatedAt
    }

    // MARK: - View-facing computed properties

    // "First Last", trimmed so a missing half doesn't leave a stray space
    var displayName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    // Alias the profile UI reads.
    var name: String { displayName }

    // SwiftUI avatar color built from the stored hex string.
    var avatarColor: Color { Color(hex: avatarColorHex) }

    // Deep link that should open the app and connect the opener to this user.
    // NOTE: actually opening this requires registering the `icarus` URL scheme
    // (Info.plist) and parsing it on launch — not wired yet. The raw  `connectionCode` works on its own in the meantime.
    var connectionLink: URL? {
        URL(string: "icarus://connect?code=\(connectionCode)")
    }
}

extension User {
    // Tolerant decoder: missing fields fall back to defaults so partial or legacy documents (e.g. an old doc that only had `displayName`) don't throw during decode.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        firstName = try c.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        lastName = try c.decodeIfPresent(String.self, forKey: .lastName) ?? ""
        avatarColorHex = try c.decodeIfPresent(String.self, forKey: .avatarColorHex) ?? "D3D3D3"
        connectionCode = try c.decodeIfPresent(String.self, forKey: .connectionCode) ?? ""
        connections = try c.decodeIfPresent([String].self, forKey: .connections) ?? []
        avatarURL = try c.decodeIfPresent(URL.self, forKey: .avatarURL)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}
