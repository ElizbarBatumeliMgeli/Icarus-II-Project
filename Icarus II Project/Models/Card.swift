//
//  Card.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 25/05/26.
//

import Foundation

/// A single card in a user's deck — what they want to do, when, where, and tags describing it.
struct Card: Identifiable, Codable, Hashable, Sendable {
    var id: String = UUID().uuidString
    var ownerID: String
    var title: String
    var tags: [String]
    var allDay: Bool
    var startDate: Date
    var endDate: Date
    var location: String
    var createdAt: Date?
    var updatedAt: Date?
}

extension Card {
    /// A blank card ready to be edited and inserted.
    static func draft(ownerID: String) -> Card {
        Card(
            ownerID: ownerID,
            title: "",
            tags: [],
            allDay: true,
            startDate: .now,
            endDate: .now,
            location: ""
        )
    }
}
