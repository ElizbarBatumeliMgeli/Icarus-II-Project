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
    
    var formattedFullName: String {
        var components = PersonNameComponents()
        components.givenName = firstName
        components.familyName = lastName
        
        let formatter = PersonNameComponentsFormatter()
        let formatted = formatter.string(from: components).trimmingCharacters(in: .whitespaces)
        return formatted.isEmpty ? "Unknown Name" : formatted
    }
}
