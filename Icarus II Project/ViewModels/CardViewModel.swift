//
//  CardViewModel.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 26/05/26.
//

import Foundation
import FirebaseFirestore

// Owns the in-memory list of cards for a user and the Firestore operations to make it mutable
@MainActor
@Observable
final class CardViewModel {
    var cards: [Card] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let db = Firestore.firestore()
    private var collection: CollectionReference { db.collection("cards") }

    // Load every card belonging to `ownerID`, ordered by start date
    func load(ownerID: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let snapshot = try await collection
                .whereField("ownerID", isEqualTo: ownerID)
                .order(by: "startDate")
                .getDocuments()
            cards = try snapshot.documents.map { try $0.data(as: Card.self) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Insert a new card. The card's `id` is used as the Firestore document ID
    func add(_ card: Card) async {
        var withTimestamps = card
        let now = Date()
        withTimestamps.createdAt = now
        withTimestamps.updatedAt = now

        do {
            let data = try Firestore.Encoder().encode(withTimestamps)
            try await collection.document(withTimestamps.id).setData(data)
            cards.append(withTimestamps)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // overwrite the card (merge) if the ids are thee same
    func update(_ card: Card) async {
        var updated = card
        updated.updatedAt = Date()

        do {
            let data = try Firestore.Encoder().encode(updated)
            try await collection.document(updated.id).setData(data, merge: true)
            if let idx = cards.firstIndex(where: { $0.id == updated.id }) {
                cards[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // deleting the card by its id
    func delete(_ id: String) async {
        do {
            try await collection.document(id).delete()
            cards.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
