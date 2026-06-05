//
//  Match.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 25/05/26.
//

import Foundation

// One user (the matcher) expressing interest in another user's card.
// A single card can have many matches — one per interested user.
struct Match: Identifiable, Codable, Hashable, Sendable {
    enum Status: String, Codable, Hashable, Sendable {
        case pending
        case accepted
        case blocked
        case completed
    }

    let id: String
    let cardID: String
    let ownerID: String
    let matcherID: String
    var status: Status
    var createdAt: Date? = nil
    var respondedAt: Date? = nil
}

extension Match {
    // Deterministic id so each (card, matcher) pair has at most one match document.
    static func id(cardID: String, matcherID: String) -> String {
        "\(cardID)_\(matcherID)"
    }

    // Given one participant's id, return the id of the other side of the match.
    func otherParticipant(relativeTo userID: String) -> String? {
        if ownerID == userID { return matcherID }
        if matcherID == userID { return ownerID }
        return nil
    }
}

// A matched card enriched with the people involved, for the Matches screen:
// the card's owner, plus everyone else who also matched the same card.
struct MatchedCardInfo: Identifiable {
    let card: DeckCard
    let owner: User?
    let otherMatchers: [User]
    var id: UUID { card.id }
}
