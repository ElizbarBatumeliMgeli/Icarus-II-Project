//
//  MatchesView.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI

enum MatchesTab: String, CaseIterable { case pending = "Pending", deal = "Deal!" }

struct MatchesView: View {
    @Bindable var viewModel: DeckViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: MatchesTab = .pending
    @State private var expandedCard: DeckCard? = nil // Tracks the tapped card

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let horizontal = width * 0.07
            let icon = width * 0.10
            
            let iconSize = width * 0.16

            ZStack {
                DottedBackground()

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: icon) {
                        GoBackToFeed(size: iconSize) {
                                dismiss()
                        }

                        Text("Matches!")
                            .font(.custom("Nohemi-Medium", fixedSize: width * 0.106))
                            .foregroundStyle(.white)

                        Spacer()
                    }
                    .padding(.horizontal, horizontal)
                    .padding(.top, height * 0.06)

                    SegmentedTabs(selected: $selectedTab, width: width)
                        .padding(.horizontal, horizontal)
                        .padding(.top, height * 0.04)

                    HStack(alignment: .center, spacing: width * 0.02) {
                        Text("Everything")
                            .font(.system(size: width * 0.045, weight: .medium))
                            .foregroundStyle(.white)
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: width * 0.035, weight: .semibold))
                            .foregroundStyle(.white)

                        Spacer()
                    }
                    .padding(.horizontal, horizontal)
                    .padding(.top, height * 0.035)

                    ScrollView {
                        if cardsForSelectedTab.isEmpty {
                                                VStack(spacing: height * 0.02) {
                                                    Spacer()
                                                    
                                                    Image(systemName: selectedTab == .pending ? "person.2.slash" : "hand.thumbsdown")
                                                        .font(.system(size: width * 0.15))
                                                        .foregroundStyle(.white.opacity(0.3))
                                                        
                                                    Text(selectedTab == .pending ? "No pending matches." : "No deals yet.")
                                                        .font(.custom("Nohemi-Medium", fixedSize: width * 0.055))
                                                        .foregroundStyle(.white.opacity(0.6))
                                                        
                                                    Spacer()
                                                }
                                                .frame(maxWidth: .infinity)
                                            } else {
                                                ScrollView {
                                                    LazyVStack(spacing: width * 0.06) {
                                                        ForEach(cardsForSelectedTab) { card in
                                                            Button {
                                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                                    expandedCard = card
                                                                }
                                                            } label: {
                                                                MatchRowCardView(card: card, width: width)
                                                            }
                                                            .buttonStyle(.plain)
                                                        }
                                                    }
                                                    .padding(.horizontal, horizontal)
                                                    .padding(.top, height * 0.02)
                                                    .padding(.bottom, height * 0.04)
                                                }
                                            }
                    }

                    Spacer(minLength: 0)
                }
                .blur(radius: expandedCard != nil ? 15 : 0) // Blur background when overlay is active
                
                // Full-screen overlay for expanded card details
                if let card = expandedCard {
                    ExpandedMatchOverlay(
                        card: card,
                        width: width,
                        height: height,
                        onClose: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                expandedCard = nil
                            }
                        },
                        onFail: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                expandedCard = nil
                            }
                            // TODO(OLA): Record a failure/can't-do action for this match and update lists.
                            // Example: viewModel.delete(card) or mark as failed in backend.
                        },
                        onSuccess: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                expandedCard = nil
                            }
                            // TODO(OLA): Mark this match as completed/success in backend and move to deals array.
                            // Example: viewModel.moveToDeal(card)
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(1)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
    }

    // OLA: Replace with your real pending/deal sources (e.g., viewModel.pendingMatches, viewModel.deals).
    private var cardsForSelectedTab: [DeckCard] {
        switch selectedTab {
        case .pending:
            return viewModel.cards
        case .deal:
            return [] // Deals array
        }
    }
}

private struct ExpandedMatchOverlay: View {
    let card: DeckCard
    let width: CGFloat
    let height: CGFloat
    let onClose: () -> Void
    let onFail: () -> Void
    let onSuccess: () -> Void

    // Idle float state
    @State private var idleOffsetY: CGFloat = 0
    @State private var idleRotation: Double = 0
    @State private var idleScale: CGFloat = 1

    var body: some View {
        ZStack {
            // Semi-transparent tap-to-dismiss layer
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                // ── Top label ──────────────────────────────────────────────
                Text("Make a choice")
                    .font(.custom("Nohemi-Medium", fixedSize: width * 0.06))
                    .foregroundStyle(.white)
                    .padding(.top, height * 0.06)

                Spacer()

                // ── Floating FeedCard-style card ───────────────────────────
                floatingCard
                    .offset(y: idleOffsetY)
                    .rotationEffect(.degrees(idleRotation))
                    .scaleEffect(idleScale)
                    .onAppear { startIdle() }

                Spacer()

                // ── Action buttons ─────────────────────────────────────────
                HStack(spacing: width * 0.05) {
                    actionButton(
                        label: "I CANT",
                        background: .black,
                        width: width,
                        action: onFail
                    )
                    actionButton(
                        label: "I DID IT",
                        background: .black,
                        width: width,
                        action: onSuccess
                    )
                }
                .padding(.horizontal, width * 0.07)
                .padding(.bottom, height * 0.08)
            }
        }
    }

    // MARK: - FeedCard-style card body
    private var floatingCard: some View {
        let cardW = width * 0.70
        let cardH = min(width * 1.36, height * 0.6)
        let cardRadius = cardW * 0.08
        let borderColor = card.color == Color(hex: "111111") ? Color(hex: "3478F6") : card.color
        

        return ZStack {
            // Glow behind card
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(borderColor)
                .frame(width: cardW * 0.96, height: cardH * 0.9)
                .blur(radius: cardW * 0.1)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

            // Main card surface
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.96),
                            Color.white.opacity(0.90),
                            Color(hex: "F1EEF8").opacity(0.88)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: borderColor.opacity(0.5), radius: cardW * 0.1, x: 0, y: cardW * 0.02)
                .shadow(color: .black.opacity(0.24), radius: cardW * 0.025, x: 0, y: cardW * 0.012)

            // Overlay shimmer
            LinearGradient(
                colors: [Color.white.opacity(0.2), .clear, borderColor.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: cardRadius, style: .continuous))
            .allowsHitTesting(false)

            // Layered border rings (matches FeedCardView exactly)
            ZStack {
                RoundedRectangle(cornerRadius: cardW * 0.07, style: .continuous)
                    .stroke(borderColor.opacity(0.95), lineWidth: cardW * 0.030)
                    .padding(cardW * 0.035)

                RoundedRectangle(cornerRadius: cardW * 0.07, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.38),
                                borderColor.opacity(0.85),
                                borderColor.opacity(0.55),
                                Color.black.opacity(0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: cardW * 0.011
                    )
                    .padding(cardW * 0.041)

                RoundedRectangle(cornerRadius: cardW * 0.07, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    .padding(cardW * 0.049)
            }

            // Card content
            VStack(spacing: 0) {
//                // ── Top row: author (top-right) ───────────────────────────
//                HStack {
//                    Spacer()
//                    HStack(spacing: cardW * 0.025) {
//                        Text(card.ownerName.replacingOccurrences(of: "\n", with: " "))
//                            .font(.system(size: cardW * 0.032, weight: .medium))
//                            .foregroundStyle(.black.opacity(0.7))
//                            .lineLimit(1)
//
//                        ZStack {
//                            RoundedRectangle(cornerRadius: cardW * 0.025, style: .continuous)
//                                .fill(Color(hex: "BBE4C6"))
//                                .frame(width: cardW * 0.11, height: cardW * 0.11)
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: cardW * 0.025, style: .continuous)
//                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
//                                )
//                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
//
//                            Text("🤪")
//                                .font(.system(size: cardW * 0.065))
//                        }
//                    }
//                }
//                .padding(.top, cardH * 0.055)
//                .padding(.horizontal, cardW * 0.09)

                Spacer()

                // ── Centre: title + date/location pills ───────────────────
                VStack(spacing: cardH * 0.025) {
                    Text(card.title)
                        .font(.custom("Nohemi-Medium", fixedSize: 36))
                        .foregroundStyle(.black.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    HStack(spacing: cardW * 0.035) {
                        feedPill(card.dateText, cardW: cardW, cardH: cardH, color: borderColor)
                        feedPill(card.location, cardW: cardW, cardH: cardH, color: borderColor)
                    }
                }

                Spacer()

                // ── Bottom row: participants (bottom-left) ────────────────
                    VStack(alignment: .center, spacing: cardW * 0.01) {

                        HStack(spacing: -cardW * 0.035) {
                            Circle().fill(Color(hex: "FF6B6B")).frame(width: cardW * 0.085).overlay(Circle().stroke(.black, lineWidth: 1.5))
                            Circle().fill(Color(hex: "4ECDC4")).frame(width: cardW * 0.085).overlay(Circle().stroke(.black, lineWidth: 1.5))
                            Circle().fill(Color(hex: "FFE66D")).frame(width: cardW * 0.085).overlay(Circle().stroke(.black, lineWidth: 1.5))
                        }
                        .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, cardH * 0.04)
                
            }
        }
        .frame(width: cardW, height: cardH)
        .compositingGroup()
    }

    // MARK: - Pill (matches FeedCardView pill style)
    private func feedPill(_ text: String, cardW: CGFloat, cardH: CGFloat, color: Color) -> some View {
        Text(text)
            .font(.system(size: cardW * 0.043, weight: .semibold))
            .foregroundStyle(.black.opacity(0.62))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(width: cardW * 0.27, height: cardH * 0.057)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.58))
                    .shadow(color: .black.opacity(0.22), radius: cardW * 0.012, x: 0, y: cardW * 0.006)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
    }

    // MARK: - Action button
    private func actionButton(label: String, background: Color, width: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: width * 0.055, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: width * 0.15)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: width * 0.045))
                .shadow(color: .white, radius: width * 1.1)
                .overlay(
                    RoundedRectangle(cornerRadius: width * 0.045)
                        .stroke(.black, lineWidth: 2)
                )
                .shadow(color: .white.opacity(0.9), radius: 4, x: 0, y: 4)
        }
    }

    // MARK: - Idle float (same as FeedCardView)
    private func startIdle() {
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            idleOffsetY = -height * 0.018
        }
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
            idleRotation = 1.5
        }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            idleScale = 1.012
        }
    }
}

// MARK: - Existing Component Updates
private struct SegmentedTabs: View {
    @Binding var selected: MatchesTab
    let width: CGFloat

    var body: some View {
        let containerHeight = width * 0.12
        let segmentHeight = containerHeight * 0.85

        ZStack {
            Capsule(style: .continuous)
                .fill(Color(hex: "222222"))
                .frame(height: containerHeight)

            HStack(spacing: 0) {
                ForEach(MatchesTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            selected = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: width * 0.042, weight: .medium))
                            .foregroundStyle(selected == tab ? .black : .white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: segmentHeight)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(selected == tab ? Color(hex: "D8D8D8") : .clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, width * 0.01)
        }
    }
}

private struct MatchRowCardView: View {
    let card: DeckCard
    let width: CGFloat

    var body: some View {
        let corner = width * 0.06
        let innerCorner = width * 0.045
        let borderColor = card.color == Color(hex: "111111") ? Color(hex: "3478F6") : card.color

        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(.white)
            
            RoundedRectangle(cornerRadius: innerCorner, style: .continuous)
                .stroke(borderColor, lineWidth: width * 0.025)
                .padding(width * 0.02)

            VStack(alignment: .leading, spacing: width * 0.03) {
                HStack(spacing: width * 0.03) {
                    ZStack {
                        RoundedRectangle(cornerRadius: width * 0.025, style: .continuous)
                            .fill(Color(hex: "BBE4C6"))
                            .frame(width: width * 0.11, height: width * 0.11)
                            .overlay(
                                RoundedRectangle(cornerRadius: width * 0.025, style: .continuous)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        Text("🤪")
                            .font(.system(size: width * 0.065))
                    }

                    Text(card.ownerName.replacingOccurrences(of: "\n", with: " "))
                        .font(.system(size: width * 0.038, weight: .medium))
                        .foregroundStyle(.black)
                        .lineLimit(2)

                    Spacer()
                }

                Text(card.title.replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: width * 0.08, weight: .bold))
                    .foregroundStyle(.black)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                HStack(spacing: width * 0.02) {
                    MatchPill(text: card.dateText, width: width, isPrimary: false, color: borderColor)
                    MatchPill(text: card.location, width: width, isPrimary: false, color: borderColor)
                }

                HStack(alignment: .bottom) {
                    MatchPill(text: card.category, width: width, isPrimary: true, color: borderColor)

                    Spacer()

                    // Participants on bottom right
                    VStack(alignment: .trailing, spacing: width * 0.01) {
                        Text("other participants")
                            .font(.system(size: width * 0.025, weight: .medium))
                            .foregroundStyle(.black)
                        
                        HStack(spacing: -width * 0.035) {
                            Circle().fill(Color(hex: "FF6B6B")).frame(width: width * 0.075).overlay(Circle().stroke(.black, lineWidth: 1.5))
                            Circle().fill(Color(hex: "4ECDC4")).frame(width: width * 0.075).overlay(Circle().stroke(.black, lineWidth: 1.5))
                            Circle().fill(Color(hex: "FFE66D")).frame(width: width * 0.075).overlay(Circle().stroke(.black, lineWidth: 1.5))
                        }
                    }
                }
            }
            .padding(.horizontal, width * 0.08)
            .padding(.top, width * 0.07)
            .padding(.bottom, width * 0.06)
        }
        .shadow(color: .black.opacity(0.2), radius: width * 0.02, x: 0, y: width * 0.01)
    }
}

private struct MatchPill: View {
    let text: String
    let width: CGFloat
    let isPrimary: Bool
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: width * 0.035, weight: isPrimary ? .semibold : .medium))
            .foregroundStyle(isPrimary ? .white : .black)
            .padding(.horizontal, width * 0.04)
            .frame(height: width * 0.08)
            .background(
                Capsule(style: .continuous)
                    .fill(isPrimary ? color : Color(hex: "D8D8D8"))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.black.opacity(isPrimary ? 0 : 0.8), lineWidth: 1)
                    )
            )
    }
}

struct GoBackToFeed: View {
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: "080808"))
                    .shadow(color: .black.opacity(0.4), radius: size * 0.1, x: 0, y: size * 0.05)
                    .shadow(color: .white,radius: size * 0.1)
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .clear, .black.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )

                Image(systemName: "iphone.app.switcher")
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "C9EC5C"), Color(hex: "5BBF61")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: "5BBF61").opacity(0.4), radius: 8, x: 0, y: 0)
                    .overlay(
                        Image(systemName: "iphone.app.switcher")
                            .font(.system(size: size * 0.42, weight: .medium))
                            .foregroundStyle(.white)
                    )
                    .overlay(
                        Image(systemName: "iphone.app.switcher")
                            .font(.system(size: size * 0.42))
                            .foregroundStyle(.clear)
                            .overlay(
                                LinearGradient(
                                    colors: [.white.opacity(0.6), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .mask(
                                    Image(systemName: "iphone.app.switcher")
                                        .font(.system(size: size * 0.42))
                                )
                            )
                    )
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(PhysicalButtonStyle())
    }
}

