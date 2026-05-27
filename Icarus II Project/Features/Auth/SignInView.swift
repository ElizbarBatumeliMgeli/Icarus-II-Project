//
//  SignInView.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 25/05/26.
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @State private var authManager = AppleAuthManager()

    var body: some View {
        NavigationStack {
            Group {
                switch authManager.authState {
                case .loading:
                    ProgressView("Loading…")

                case .signedIn:
                    if let profile = authManager.currentUserProfile {
                        signedInView(profile: profile)
                    }

                case .signedOut:
                    signedOutView
                }
            }
            .navigationTitle("Onboarding")
        }
    }

    // MARK: - Signed In

    private func signedInView(profile: AppleUserProfile) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill.badge.checkmark")
                .font(.system(size: 80))
                .foregroundStyle(.green, .blue)

            Text("Profile Saved")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(profile.formattedFullName)
                .font(.largeTitle.bold())

            if let email = profile.email {
                Text(email)
                    .font(.subheadline)
            }

            Button(role: .destructive) {
                Task { await authManager.logout() }
            } label: {
                Text("Clear Local Data (Logout)")
            }
            .buttonStyle(.bordered)
            .padding(.top, 20)
        }
    }

    // MARK: - Signed Out

    private var signedOutView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "applelogo")
                    .font(.system(size: 60))

                Text("Create Account")
                    .font(.title.bold())

                Text("Your name will be securely captured on the first attempt.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.bottom, 40)

            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                authManager.handleAuthorization(result: result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    SignInView()
}
