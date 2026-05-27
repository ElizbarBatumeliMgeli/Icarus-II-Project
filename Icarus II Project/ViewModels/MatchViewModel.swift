//
//  MatchViewModel.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 26/05/26.
//

import Foundation
import FirebaseFirestore

// Manages match documents tied to cards: who expressed interest in which card and what the owner decided.
@MainActor
@Observable
final class MatchViewModel {
    var matches: [Match] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let db = Firestore.firestore()
    private var collection: CollectionReference { db.collection("matches") }

    // All matches received across every card I own.
    func loadIncoming(ownerID: String) async {
        await runQuery(collection.whereField("ownerID", isEqualTo: ownerID))
    }

    // All matches I have sent (cards I am interested in).
    func loadOutgoing(matcherID: String) async {
        await runQuery(collection.whereField("matcherID", isEqualTo: matcherID))
    }

    // All matches on a single card (owner viewing their card's interest list).
    func loadForCard(cardID: String) async {
        await runQuery(collection.whereField("cardID", isEqualTo: cardID))
    }

    // Express interest in a card. Doc id is deterministic, so re-matching just overwrites.
    func sendRequest(forCard cardID: String, ownerID: String, matcherID: String) async {
        let match = Match(
            id: Match.id(cardID: cardID, matcherID: matcherID),
            cardID: cardID,
            ownerID: ownerID,
            matcherID: matcherID,
            status: .pending,
            createdAt: Date()
        )

        do {
            let data = try Firestore.Encoder().encode(match)
            try await collection.document(match.id).setData(data)
            if let idx = matches.firstIndex(where: { $0.id == match.id }) {
                matches[idx] = match
            } else {
                matches.append(match)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Owner accepts, blocks, or otherwise changes the status of a match.
    func respond(to matchID: String, with status: Match.Status) async {
        do {
            try await collection.document(matchID).updateData([
                "status": status.rawValue,
                "respondedAt": Timestamp(date: Date())
            ])
            if let idx = matches.firstIndex(where: { $0.id == matchID }) {
                matches[idx].status = status
                matches[idx].respondedAt = Date()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Shared query runner — sets loading/error and decodes matches into the published list.
    private func runQuery(_ query: Query) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let snapshot = try await query.getDocuments()
            matches = try snapshot.documents.map { try $0.data(as: Match.self) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
