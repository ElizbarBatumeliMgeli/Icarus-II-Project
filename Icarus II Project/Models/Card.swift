//
//  Card.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 25/05/26.
//
//  ⚠️ DUPLICATE NOTE:
//  This file duplicates `Icarus II Project/Models/DeckCard.swift` (from main).
//  Same concept (a card in the deck), different shape:
//    - `DeckCard` is a UI-only model used by the views.
//    - `Card` (this file) is the Codable/Firestore model used by the data layer.
//  TODO: decide which to keep, or map between them, when wiring the UI to Firestore.
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
    var createdAt: Date? = nil
    var updatedAt: Date? = nil
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
