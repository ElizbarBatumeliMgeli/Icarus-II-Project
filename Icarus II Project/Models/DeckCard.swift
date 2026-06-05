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
    // Added `ownerID`, `colorHex`, `createdAt`, `updatedAt` for Firestore persistence.
    // `category` is a stored field (the card's pill text); `color` is computed
    // from `colorHex` — Views keep reading the same property names.

    let id: UUID                       // Stable identifier; also used as the Firestore doc id (as uuidString).
    var ownerID: String = ""           // Firebase Auth UID of the deck owner. TODO(auth)
    var title: String                  // Big headline shown on the card. Can include "\n" to split into two lines.
    var ownerName: String = "Marco\nRocco"  // Display name shown on the card; not used for auth.
    var category: String = ""          // Tag/pill text shown on the card (e.g. Food, Social, Art). Editable from the UI.
    var dateText: String = ""          // "When?" pill content (e.g. "Today", "Tomorrow", "27/05/2026") - to discuss with the team
    var location: String               // "Where?" pill
    var colorHex: String = "D8D8D8"    // Accent color persisted as a hex string (no "#"). UI reads `color`.
    var eventDate: Date? = nil         // Real event date (the day the activity happens). Drives match expiry.
    var createdAt: Date? = nil
    var updatedAt: Date? = nil

    // SwiftUI accent color built from the stored hex string.
    var color: Color { Color(hex: colorHex) }

    // MARK: - Initializers

    // initializer used by the data layer / Firestore decode
    init(
        id: UUID = UUID(),
        ownerID: String = "",
        title: String,
        ownerName: String = "Marco\nRocco",
        category: String = "",
        dateText: String = "",
        location: String,
        colorHex: String = "D8D8D8",
        eventDate: Date? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.ownerID = ownerID
        self.title = title
        self.ownerName = ownerName
        self.category = category
        self.dateText = dateText
        self.location = location
        self.colorHex = colorHex
        self.eventDate = eventDate
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
            category: category,
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
extension DeckCard {
    private enum CodingKeys: String, CodingKey {
        case id, ownerID, title, ownerName, category, dateText, location, colorHex, eventDate, createdAt, updatedAt
    }

    // Tolerant decoder: missing fields fall back to sensible defaults so older or partial documents don't fail to load.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        if let uuid = try c.decodeIfPresent(UUID.self, forKey: .id) {
            self.id = uuid
        } else if let idString = try c.decodeIfPresent(String.self, forKey: .id), let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            // Fallback to a generated UUID so the card can render even if the stored id is missing.
            // Prefer ensuring the document contains an `id` field equal to its documentID.
            self.id = UUID()
        }

        self.ownerID = try c.decodeIfPresent(String.self, forKey: .ownerID) ?? ""
        self.title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.ownerName = try c.decodeIfPresent(String.self, forKey: .ownerName) ?? "Marco\nRocco"
        self.category = try c.decodeIfPresent(String.self, forKey: .category) ?? ""
        self.dateText = try c.decodeIfPresent(String.self, forKey: .dateText) ?? ""
        self.location = try c.decodeIfPresent(String.self, forKey: .location) ?? ""
        self.colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex) ?? "D8D8D8"
        self.eventDate = try c.decodeIfPresent(Date.self, forKey: .eventDate)
        self.createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

