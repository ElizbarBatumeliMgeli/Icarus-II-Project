//
//  DeckCard.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI

struct DeckCard: Identifiable, Equatable, Hashable, Codable {
    // OLA NOTE:
    // This is the lightweight model we pass around the UI.
    // Purpose: just enough info to draw a card in the feed/matches.
    // How it should act: ViewModel will populate this from cloud data and keep it up to date.
    //
    // OLA  (Firestore):
    // Added `ownerID`, `tags`, `colorHex`, `createdAt`, `updatedAt` for firestorepersistence
    // `category` is now a computed view of `tags.first`, and `color` is computed
    // from `colorHex` — Views keep reading the same property names.

    let id: UUID                       // Stable identifier; also used as the Firestore doc id (as uuidString).
    var ownerID: String = ""           // Firebase Auth UID of the deck owner. TODO(auth)
    var title: String                  // Big headline shown on the card. Can include "\n" to split into two lines.
    var ownerName: String = "Marco\nRocco"  // Display name shown on the card; not used for auth.
    var tags: [String] = []            // Tag list; UI uses the first one as the "category" pill.
    var dateText: String = ""          // "When?" pill content (e.g. "Today", "Tomorrow", "27/05/2026") - to discuss with the team
    var location: String               // "Where?" pill
    var colorHex: String = "D8D8D8"    // Accent color persisted as a hex string (no "#"). UI reads `color`.
    var createdAt: Date? = nil
    var updatedAt: Date? = nil

    
    var category: String { tags.first ?? "" }
    // SwiftUI accent color built from the stored hex string.
    var color: Color { Color(hex: colorHex) }

    // MARK: - Initializers

    // initializer used by the data layer / Firestore decode
    init(
        id: UUID = UUID(),
        ownerID: String = "",
        title: String,
        ownerName: String = "Marco\nRocco",
        tags: [String] = [],
        dateText: String = "",
        location: String,
        colorHex: String = "D8D8D8",
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.ownerID = ownerID
        self.title = title
        self.ownerName = ownerName
        self.tags = tags
        self.dateText = dateText
        self.location = location
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Legacy initializer — preserved so existing UI code (CardEditorSheet, DeckViewModel mock data) keeps compiling Translates category as first tag and color as colorHex
    init(
        id: UUID = UUID(),
        title: String,
        ownerName: String = "Marco\nRocco",
        category: String,
        dateText: String,
        location: String,
        color: Color
    ) {
        self.init(
            id: id,
            ownerID: "",
            title: title,
            ownerName: ownerName,
            tags: category.isEmpty ? [] : [category],
            dateText: dateText,
            location: location,
            colorHex: DeckCard.hexString(from: color),
            createdAt: nil,
            updatedAt: nil
        )
    }

    // MARK: - Helpers

    // Converts a SwiftUI `Color` to a 6-digit uppercase hex string (no "#" prefix). Used by the legacy initializer so View-supplied colors are saved to Firestore
    private static func hexString(from color: Color) -> String {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(
            format: "%02X%02X%02X",
            Int((r * 255).rounded()),
            Int((g * 255).rounded()),
            Int((b * 255).rounded())
        )
    }
}
