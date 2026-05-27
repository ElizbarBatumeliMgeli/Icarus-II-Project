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

    func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                self.errorMessage = "Received an unknown credential type."
                return
            }

            let userID = credential.user

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
                    //logger.info("Data Retrieved from Cache")
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

        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                logger.debug("User cancelled Sign in with Apple.")
            } else {
                logger.error("Sign in with Apple failed: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func logout() async {
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
                self.authState = .signedIn

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
