//
//  MatchRepository.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 25/05/26.
//

import Foundation
import FirebaseFirestore

// CRUD for Match against the `matches` Firestore collection.
// Owns no UI state — view models are the consumers.
@MainActor
final class MatchRepository {
    private let db = Firestore.firestore()
    private var collection: CollectionReference { db.collection("matches") }

    // Insert a match. The id is deterministic (cardID_matcherID), so re-swiping the
    // same card just overwrites instead of creating a duplicate.
    func create(_ match: Match) async throws {
        var toSave = match
        if toSave.createdAt == nil { toSave.createdAt = Date() }
        let data = try Firestore.Encoder().encode(toSave)
        try await collection.document(toSave.id).setData(data)
    }

    // Every match this user made (cards they swiped on) — the matcher's perspective.
    func forMatcher(_ matcherID: String) async throws -> [Match] {
        let snapshot = try await collection
            .whereField("matcherID", isEqualTo: matcherID)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: Match.self) }
    }

    // Every match on a single card — the owner's perspective ("who matched this card").
    func forCard(_ cardID: String) async throws -> [Match] {
        let snapshot = try await collection
            .whereField("cardID", isEqualTo: cardID)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: Match.self) }
    }

    // Live updates of every match on a single card. Returns a registration the caller MUST
    // keep and `.remove()` when done. `onChange` is delivered on the main actor.
    func observeCard(cardID: String,
                     onChange: @escaping @MainActor ([Match]) -> Void) -> ListenerRegistration {
        collection
            .whereField("cardID", isEqualTo: cardID)
            .addSnapshotListener { snapshot, _ in
                let matches = (snapshot?.documents ?? []).compactMap { try? $0.data(as: Match.self) }
                Task { @MainActor in onChange(matches) }
            }
    }

    // Remove a match by its deterministic id (e.g. to undo a swipe).
    func delete(id: String) async throws {
        try await collection.document(id).delete()
    }
}
