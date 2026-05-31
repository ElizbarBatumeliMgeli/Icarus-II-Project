//
//  ConnectionView.swift
//  Icarus II Project
//
//  Created by Elizbar Kheladze on 31/05/26.
//

import SwiftUI

// Mock Data Model
struct ConnectionUser: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let points: Int
    let avatarColor: Color
}

struct ConnectionsView: View {
    @Environment(\.dismiss) private var dismiss

    // Mock Data Array
    let connections: [ConnectionUser] = [
        ConnectionUser(rank: 1, name: "Carlo Cudicini", points: 256, avatarColor: Color(hex: "FF6B6B")),
        ConnectionUser(rank: 2, name: "Maria Rossi", points: 198, avatarColor: Color(hex: "4ECDC4")),
        ConnectionUser(rank: 3, name: "Luca Bianchi", points: 145, avatarColor: Color(hex: "FFE66D")),
        ConnectionUser(rank: 4, name: "Giulia Verdi", points: 90, avatarColor: Color(hex: "9B5DE5")),
        ConnectionUser(rank: 5, name: "Andrea Neri", points: 42, avatarColor: Color(hex: "00BBF9"))
    ]

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
                        GoBackToFeed(size: width * 0.16) {
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

                    // Minimalist List
                    ScrollView {
                        LazyVStack(spacing: width * 0.04) {
                            ForEach(connections) { connection in
                                ConnectionRow(connection: connection, width: width)
                            }
                        }
                        .padding(.horizontal, horizontal)
                        .padding(.bottom, height * 0.05)
                    }
                }
            }
        }
    }
}

// A reusable row mimicking the minimalist aesthetic
struct ConnectionRow: View {
    let connection: ConnectionUser
    let width: CGFloat

    var body: some View {
        HStack(spacing: width * 0.04) {
            // Ranking Number
            Text("\(connection.rank).")
                .font(.system(size: width * 0.055, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: width * 0.08, alignment: .leading)

            // Avatar Frame
            ZStack {
                Circle()
                    .fill(connection.avatarColor)
                    .frame(width: width * 0.14, height: width * 0.14)
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                
                // Fallback initial
                Text(String(connection.name.prefix(1)))
                    .font(.system(size: width * 0.06, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Name and Points breakdown
            VStack(alignment: .leading, spacing: width * 0.01) {
                Text(connection.name)
                    .font(.system(size: width * 0.045, weight: .semibold))
                    .foregroundStyle(.white)

                Text("\(connection.points) pts")
                    .font(.system(size: width * 0.035, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }

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
