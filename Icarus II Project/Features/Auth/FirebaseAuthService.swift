//
//  FirebaseAuthService.swift
//  Icarus II Project
//
//  Created by Gianluca Pascarella on 26/05/2026.
//

import Foundation
import FirebaseAuth
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "IcarusII", category: "FirebaseAuthService")

/// A dedicated service for Firebase Authentication operations.
struct FirebaseAuthService {
    
    /// Signs in to Firebase using an Apple ID token and its raw nonce.
    /// - Parameters:
    ///   - idToken: The Apple identity token string.
    ///   - rawNonce: The raw nonce string used during the Apple Sign-In request.
    ///   - fullName: The user's full name (if provided by Apple).
    /// - Returns: The UID of the authenticated Firebase user.
    static func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async throws -> String {
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: rawNonce,
            fullName: fullName
        )
        
        do {
            let authResult = try await Auth.auth().signIn(with: firebaseCredential)
            logger.info("Firebase sign-in successful. UID: \(authResult.user.uid)")
            return authResult.user.uid
        } catch {
            logger.error("Firebase sign-in failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Signs out the current user from Firebase.
    static func signOut() {
        do {
            try Auth.auth().signOut()
            logger.info("Firebase sign-out successful.")
        } catch {
            logger.error("Firebase sign-out failed: \(error.localizedDescription)")
        }
    }
    
    /// Checks if there is a valid Firebase session.
    static var isUserSignedIn: Bool {
        return Auth.auth().currentUser != nil
    }
}
