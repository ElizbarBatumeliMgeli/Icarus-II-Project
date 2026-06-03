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

    // Load all cards (no filtering). Useful as a simple global feed or a fallback when connections are empty.
    func all() async throws -> [DeckCard] {
        let snapshot = try await collection.getDocuments()
        return try snapshot.documents.map { try $0.data(as: DeckCard.self) }
    }

    // Load the feed: every card owned by any of `ownerIDs` (i.e. the current user's connections).
    // Firestore `in` queries cap at 10 values, so we split into chunks and merge the results.
    func feed(fromOwnerIDs ownerIDs: [String]) async throws -> [DeckCard] {
        guard !ownerIDs.isEmpty else { return [] }
        var result: [DeckCard] = []
        for chunk in Self.chunked(ownerIDs, size: 10) {
            let snapshot = try await collection
                .whereField("ownerID", in: chunk)
                .getDocuments()
            result += try snapshot.documents.map { try $0.data(as: DeckCard.self) }
        }
        return result
    }

    // Load specific cards by their document ids — used to turn a list of matched card ids into cards.
    // Same 10-value `in` limit, so we chunk here too.
    func cards(withIDs ids: [String]) async throws -> [DeckCard] {
        guard !ids.isEmpty else { return [] }
        var result: [DeckCard] = []
        for chunk in Self.chunked(ids, size: 10) {
            let snapshot = try await collection
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            result += try snapshot.documents.map { try $0.data(as: DeckCard.self) }
        }
        return result
    }

    // Splits an array into sub-arrays of at most `size` elements (for chunked `in` queries).
    private static func chunked<T>(_ array: [T], size: Int) -> [[T]] {
        stride(from: 0, to: array.count, by: size).map {
            Array(array[$0..<Swift.min($0 + size, array.count)])
        }
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

