//
//  SignInView.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 25/05/26.
//

import SwiftUI
import AuthenticationServices

/// A pure UI component responsible for displaying the "Create Account" screen.
/// It relies on the AppleAuthManager environment object to handle the actual login process.
struct SignInView: View {
    @Environment(AppleAuthManager.self) var authManager

    var body: some View {
        ZStack {
            DottedBackground()
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Text("Create Account")
                        .font(.title.bold())
                        .foregroundStyle(Color.white)
                    
                    Text("We need your full name and Apple ID to register your account.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .foregroundStyle(Color.white)
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
                    request.nonce = authManager.prepareNonce()
                } onCompletion: { result in
                    authManager.handleAuthorization(result: result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .padding(.horizontal, 32)
            }
        }
    }
}

#Preview {
    SignInView()
        .environment(AppleAuthManager())
}
