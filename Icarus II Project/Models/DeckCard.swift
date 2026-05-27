//
//  DeckCard.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI

struct DeckCard: Identifiable, Equatable {
    // OLA NOTE:
    // This is the lightweight model we pass around the UI.
    // Purpose: just enough info to draw a card in the feed/matches.
    // How it should act: ViewModel will populate this from cloud data and keep it up to date.
    // TODO(OLA): If your backend has its own identifiers or extra fields,
    // map them here or add new props as needed (e.g. backendID, ownerID, status).

    let id: UUID           // Unique local identifier for list stability. Map your backend id here if you prefer.
    var title: String       // Big headline shown on the card. Can include a "\n" to split into two lines.
    var ownerName: String   // Display name shown on the card; not used for auth.
    var category: String    // Tag/pill text (e.g. Food, Social, Art, etc.).
    var dateText: String    // Small "When?" pill (e.g. "Today", "Tomorrow", "Weekend").
    var location: String    // Small "Where?" pill.
    var color: Color        // Accent/border color used for glow/border in the UI.

    // OLA: UI uses this init for mocks and editing.
    // ownerName defaults to a placeholder; feel free to replace when wiring auth/profile.
    init(
        id: UUID = UUID(),
        title: String,
        ownerName: String = "Marco\nRocco",
        category: String,
        dateText: String,
        location: String,
        color: Color
    ) {
        self.id = id
        self.title = title
        self.ownerName = ownerName
        self.category = category
        self.dateText = dateText
        self.location = location
        self.color = color
    }
}
