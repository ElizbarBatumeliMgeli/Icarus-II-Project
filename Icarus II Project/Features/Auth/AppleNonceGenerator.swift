//
//  AppleNonceGenerator.swift
//  Icarus II Project
//
//  Created by Gianluca Pascarella on 26/05/2026.
//

import Foundation
import CryptoKit

/// A helper struct for generating and hashing cryptographic nonces used during Apple Sign-In.
struct AppleNonceGenerator {
    
    /// Generates a random nonce and returns a tuple containing both the raw nonce and its SHA256 hash.
    static func generateNonce() -> (raw: String, hashed: String) {
        let rawNonce = randomNonceString()
        let hashedNonce = sha256(rawNonce)
        return (rawNonce, hashedNonce)
    }
    
    /// Creates a cryptographically secure random string.
    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
    
    /// Returns the SHA256 hash of the input string as a hex string.
    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
