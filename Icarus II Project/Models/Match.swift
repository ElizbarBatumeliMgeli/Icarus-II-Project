//
//  Match.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 25/05/26.
//

import Foundation

///  request, acceptance, or block
struct Match: Identifiable, Codable, Hashable, Sendable {
    enum Status: String, Codable, Hashable, Sendable {
        case pending
        case accepted
        case blocked
    }

    let id: String
    let requesterID: String
    let recipientID: String
    var status: Status
    var createdAt: Date?
    var respondedAt: Date?
}

extension Match {
    /// Given one participant's id, return the id of the other side of the match.
    func otherParticipant(relativeTo userID: String) -> String? {
        if requesterID == userID { return recipientID }
        if recipientID == userID { return requesterID }
        return nil
    }
}


    // history inside the match - is what we already did, where, with who, storing all the data of the activity
