//
//  AppleUserProfile.swift
//  Icarus II Project
//
//  Created by Gianluca Pascarella on 25/05/26.
//

import Foundation

/// The essential pieces of identity we grab from Apple when a user logs in.
struct AppleUserProfile: Codable, Sendable {
    let userID: String
    let firstName: String?
    let lastName: String?
    let email: String?
    
    var formattedFullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        let combined = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return combined.isEmpty ? "Unknown Name" : combined
    }
}
