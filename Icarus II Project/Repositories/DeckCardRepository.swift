//
//  DeckCardRepository.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 25/05/26.
//

import Foundation
import FirebaseFirestore

// CRUD for DeckCard against the `cards` Firestore collection.
// Owns no UI state — `DeckViewModel` is the consumer.
@MainActor
final class DeckCardRepository {
    private let db = Firestore.firestore()
    private var collection: CollectionReference { db.collection("cards") }

    // Load every card owned by `ownerID`. Order is unspecified for now add `.order(by: "createdAt", descending: true)` once we want a stable feed order
    func fetch(ownerID: String) async throws -> [DeckCard] {
        let snapshot = try await collection
            .whereField("ownerID", isEqualTo: ownerID)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: DeckCard.self) }
    }

    /// Insert or update a card. Uses `card.id.uuidString` as the Firestore document id.
    /// Fills `createdAt` on first write and always bumps `updatedAt`.
    func upsert(_ card: DeckCard) async throws {
        var withTimestamps = card
        let now = Date()
        if withTimestamps.createdAt == nil { withTimestamps.createdAt = now }
        withTimestamps.updatedAt = now
        let data = try Firestore.Encoder().encode(withTimestamps)
        try await collection.document(card.id.uuidString).setData(data, merge: true)
    }

    /// Remove a card by id.
    func delete(id: UUID) async throws {
        try await collection.document(id.uuidString).delete()
    }
}
