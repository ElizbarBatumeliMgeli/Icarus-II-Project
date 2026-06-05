//
//  ConnectionView.swift
//  Icarus II Project
//
//  Created by Elizbar Kheladze on 31/05/26.
//

import SwiftUI

struct ConnectionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserViewModel.self) private var userViewModel

    // Real connections, loaded from Firestore (the people this user is connected with).
    @State private var connections: [User] = []
    @State private var isLoading = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let horizontal = width * 0.07

            ZStack {
                DottedBackground()

                VStack(alignment: .leading, spacing: 0) {
                    // Header Area matching existing navigation structures
                    HStack(alignment: .center) {
                        BackToFeedButton(size: width * 0.12) {
                            dismiss()
                        }

                        Text("Connections")
                            .font(.custom("Nohemi-Medium", fixedSize: width * 0.09))
                            .foregroundStyle(.white)
                            .padding(.leading, width * 0.04)

                        Spacer()
                    }
                    .padding(.horizontal, horizontal)
                    .padding(.top, height * 0.06)
                    .padding(.bottom, height * 0.04)

                    if connections.isEmpty {
                        // Empty / loading state
                        VStack(spacing: height * 0.012) {
                            Spacer()
                            Text(isLoading ? "Loading…" : "No connections yet")
                                .font(.system(size: width * 0.05, weight: .semibold))
                                .foregroundStyle(.white)
                            if !isLoading {
                                Text("Share your link to connect with people.")
                                    .font(.system(size: width * 0.04, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .multilineTextAlignment(.center)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, horizontal)
                    } else {
                        // Minimalist List of real connections
                        ScrollView {
                            LazyVStack(spacing: width * 0.04) {
                                ForEach(Array(connections.enumerated()), id: \.element.id) { index, user in
                                    ConnectionRow(user: user, rank: index + 1, width: width)
                                }
                            }
                            .padding(.horizontal, horizontal)
                            .padding(.bottom, height * 0.05)
                        }
                    }
                }
            }
        }
        .task { await loadConnections() }
    }

    private func loadConnections() async {
        isLoading = true
        defer { isLoading = false }
        do {
            connections = try await userViewModel.loadConnections()
        } catch {
            connections = []
        }
    }
}

// A reusable row mimicking the minimalist aesthetic
struct ConnectionRow: View {
    let user: User
    let rank: Int
    let width: CGFloat

    var body: some View {
        HStack(spacing: width * 0.04) {
            // Position in the list
            Text("\(rank).")
                .font(.system(size: width * 0.055, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: width * 0.08, alignment: .leading)

            // Avatar: derived color + first initial of the connection's name
            ZStack {
                Circle()
                    .fill(user.avatarColor)
                    .frame(width: width * 0.14, height: width * 0.14)
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))

                Text(user.initial)
                    .font(.system(size: width * 0.06, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Name
            Text(user.displayName)
                .font(.system(size: width * 0.045, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(width * 0.04)
        .background(
            RoundedRectangle(cornerRadius: width * 0.05, style: .continuous)
                .fill(Color(hex: "222222").opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: width * 0.05, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
