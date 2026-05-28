//
//  SignInViewModel.swift
//  Icarus II Project
//
//  Created by Gianluca Pascarella on 26/05/2026.
//

import Foundation
import AuthenticationServices
import Observation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "IcarusII", category: "Auth")

/// Represents the three possible authentication states.
enum AuthState: Equatable {
    case loading
    case signedOut
    case signedIn
}

@Observable
@MainActor
final class AppleAuthManager {
    var currentUserProfile: AppleUserProfile?
    var errorMessage: String?
    var authState: AuthState = .loading

    /// The raw nonce generated for the current sign-in attempt.
    /// Needed to create the Firebase credential after Apple returns.
    private(set) var currentNonce: String?

    init() {
       Task {
            if let savedUserID = KeychainHelper.loadUserID() {
                self.currentUserProfile = LocalProfileStore.shared.fetchProfile(for: savedUserID)
                await checkCredentialState(userID: savedUserID)
           } else {
               self.authState = .signedOut
            }
        }
    }

    // MARK: - Nonce Helper

    /// Generates a random nonce and stores its raw value for Firebase verification.
    /// Call this right before presenting the Apple sign-in sheet.
    func prepareNonce() -> String {
        let noncePair = AppleNonceGenerator.generateNonce()
        currentNonce = noncePair.raw
        return noncePair.hashed
    }

    // MARK: - Handle Apple Authorization

    func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                self.errorMessage = "Received an unknown credential type."
                return
            }

            let userID = credential.user

            // --- Firebase Auth: sign in with the Apple credential ---
            guard let nonce = currentNonce else {
                logger.error("Missing nonce. Cannot authenticate with Firebase.")
                self.errorMessage = "Internal error: missing nonce."
                return
            }

            guard let appleIDToken = credential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                logger.error("Unable to fetch Apple ID token.")
                self.errorMessage = "Unable to retrieve identity token."
                return
            }

            Task {
                do {
                    let _ = try await FirebaseAuthService.signInWithApple(
                        idToken: idTokenString,
                        rawNonce: nonce,
                        fullName: credential.fullName
                    )

                    // Save profile locally (same as before)
                    self.saveProfileLocally(credential: credential, userID: userID)

                } catch {
                    self.errorMessage = "Firebase sign-in failed: \(error.localizedDescription)"
                }
            }

        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                logger.debug("User cancelled Sign in with Apple.")
            } else {
                logger.error("Sign in with Apple failed: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Local Profile Persistence

    /// Extracts the profile from the Apple credential and saves it locally.
    private func saveProfileLocally(credential: ASAuthorizationAppleIDCredential, userID: String) {
        if let nameComponents = credential.fullName,
           nameComponents.givenName != nil || nameComponents.familyName != nil {

            let newProfile = AppleUserProfile(
                userID: userID,
                firstName: nameComponents.givenName,
                lastName: nameComponents.familyName,
                email: credential.email
            )

            self.currentUserProfile = newProfile
            self.authState = .signedIn

            LocalProfileStore.shared.saveProfile(newProfile)
            KeychainHelper.save(userID: userID)

            logger.info("First login successful. Captured full name: \(newProfile.formattedFullName). Captured email: \(newProfile.email ?? "n/a").")

        } else {
            // Returning user — Apple only provides the userID.
            logger.info("Returning user login. UserID: \(userID)")

            if let cachedProfile = LocalProfileStore.shared.fetchProfile(for: userID) {
                self.currentUserProfile = cachedProfile
            } else {
                let minimalProfile = AppleUserProfile(
                    userID: userID,
                    firstName: nil,
                    lastName: nil,
                    email: nil)
                self.currentUserProfile = minimalProfile
                LocalProfileStore.shared.saveProfile(minimalProfile)
                logger.warning("Missed Profile in cache")
            }
            KeychainHelper.save(userID: userID)
            self.authState = .signedIn
        }
    }

    // MARK: - Logout

    func logout() async {
        // Sign out from Firebase
        FirebaseAuthService.signOut()

        // Clear local data
        KeychainHelper.deleteUserID()
        self.currentUserProfile = nil
        self.authState = .signedOut
    }

    // MARK: - Credential Revocation Check

    /// Checks with Apple whether the credential is still valid.
    /// Call on every app launch to handle users who revoked access
    /// via Settings → Apple ID → Sign-In & Security.
    private func checkCredentialState(userID: String) async {
        do {
            let state = try await ASAuthorizationAppleIDProvider()
                .credentialState(forUserID: userID)

            switch state {
            case .authorized:
                // Also verify Firebase session is still valid
                if FirebaseAuthService.isUserSignedIn {
                    self.authState = .signedIn
                } else {
                    logger.warning("Apple credential valid but no Firebase session. Requiring re-sign-in.")
                    await logout()
                }

            case .revoked, .notFound:
                logger.warning("Apple credential revoked or not found. Logging out.")
                await logout()

            case .transferred:
                logger.info("Apple credential transferred to a new team.")
                self.authState = .signedIn

            @unknown default:
                self.authState = .signedIn
            }
        } catch {
            logger.error("Failed to check credential state: \(error.localizedDescription)")
            // Don't force logout on transient network errors; keep local state.
            self.authState = .signedIn
        }
    }
}
