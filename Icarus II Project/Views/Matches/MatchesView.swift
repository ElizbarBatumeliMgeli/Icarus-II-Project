//
//  MatchesView.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI

struct MatchesView: View {
    @Bindable var viewModel: DeckViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var expandedCard: DeckCard? = nil // Tracks the tapped card

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let horizontal = width * 0.07
            let iconSize = width * 0.12

            ZStack {
                DottedBackground()

                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: height * 0.03)
                    
                    // Header
                    HStack(alignment: .center, spacing: iconSize) {
                        BackToFeedButton(size: iconSize) {
                            dismiss()
                        }

                        Text("Matches!")
                            .font(.custom("Nohemi-Medium", fixedSize: width * 0.106))
                            .foregroundStyle(.white)

                        Spacer()
                    }
                    .padding(.horizontal, horizontal)
                    .padding(.top, height * 0.06)

                    // Filter / Sort row (optional, left in as requested previously)
//                    HStack(alignment: .center, spacing: width * 0.02) {
//                        Text("Everything")
//                            .font(.system(size: width * 0.045, weight: .medium))
//                            .foregroundStyle(.white)
//                        
//                        Image(systemName: "chevron.up.chevron.down")
//                            .font(.system(size: width * 0.035, weight: .semibold))
//                            .foregroundStyle(.white)
//
//                        Spacer()
////                    }
//                    .padding(.horizontal, horizontal)
//                    .padding(.top, height * 0.045)
//                    .padding(.bottom, height * 0.02)

                    // Main List Area
                    ScrollView {
                        if viewModel.matchedCardInfos.isEmpty {
                            // Empty State
                            VStack(spacing: height * 0.02) {
                                Spacer()
                                
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: width * 0.15))
                                    .foregroundStyle(.white.opacity(0.3))
                                
                                Text("No matches yet.")
                                    .font(.custom("Nohemi-Medium", fixedSize: width * 0.055))
                                    .foregroundStyle(.white.opacity(0.6))
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            // Matches List
                            LazyVStack(spacing: width * 0.06) {
                                ForEach(viewModel.matchedCardInfos) { info in
                                    Button {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            expandedCard = info.card
                                        }
                                    } label: {
                                        MatchRowCardView(info: info, width: width)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, horizontal)
                            .padding(.top, height * 0.02)
                            .padding(.bottom, height * 0.04)
                        }
                    }
                    .padding(.top, height * 0.02)

                    Spacer(minLength: 0)
                }
                .ignoresSafeArea(edges: .top)
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
                            Task { await viewModel.cancelMatch(card: card) }
                        },
                        onSuccess: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                expandedCard = nil
                            }
                            Task { await viewModel.completeMatch(card: card) }
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(1)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        // Load the cards I've matched with from Firestore whenever this screen appears.
        .task {
            await viewModel.reloadMatchedCards()
        }
    }
}

// ── Expanded Match Overlay ───────────────────────────────────────────────────
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
                // Top label
                Text("Make a choice")
                    .font(.custom("Nohemi-Medium", fixedSize: width * 0.06))
                    .foregroundStyle(.white)
                    .padding(.top, height * 0.06)

                Spacer()

                // Floating FeedCard-style card
                floatingCard
                    .offset(y: idleOffsetY)
                    .rotationEffect(.degrees(idleRotation))
                    .scaleEffect(idleScale)
                    .onAppear { startIdle() }

                Spacer()

                // Action buttons
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
            // Glowing shadow
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(card.color)
                .frame(width: cardW * 0.96, height: cardH * 0.9)
                .blur(radius: cardW * 0.1)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

            // Card Base
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.96),
                            Color.white.opacity(0.9),
                            Color(hex: "F1EEF8").opacity(0.88)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: card.color.opacity(0.5), radius: cardW * 0.1, x: 0, y: cardW * 0.02)
                .shadow(color: .black.opacity(0.24), radius: cardW * 0.025, x: 0, y: cardW * 0.012)

            // Texture/Pattern
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(
                    ImagePaint(
                        image: Image("ELIZBARSVG"),
                        sourceRect: CGRect(x: 0, y: 0, width: 1, height: 1),
                        scale: 0.3
                    )
                )
                .opacity(0.16)
                .blendMode(.multiply)
                .allowsHitTesting(false)

            // Highlight gradient
            LinearGradient(
                colors: [
                    Color.white.opacity(0.2),
                    Color.clear,
                    card.color.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: cardRadius, style: .continuous))
            .allowsHitTesting(false)

            // Borders
            ZStack {
                RoundedRectangle(cornerRadius: cardW * 0.07, style: .continuous)
                    .stroke(card.color.opacity(0.95), lineWidth: cardW * 0.030)
                    .padding(cardW * 0.035)

                RoundedRectangle(cornerRadius: cardW * 0.07, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.38),
                                card.color.opacity(0.85),
                                card.color.opacity(0.55),
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

                RoundedRectangle(cornerRadius: cardW * 0.07, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    .blur(radius: 0.7)
                    .padding(cardW * 0.031)
            }

            // Content
            VStack(spacing: 0) {
                // Top: author (left) + category pill (right)
                HStack(alignment: .center, spacing: cardW * 0.02) {
                    HStack(spacing: cardW * 0.02) {
                        Circle()
                            .fill(Color(hex: "BBE4C6"))
                            .frame(width: cardW * 0.06, height: cardW * 0.06)
                            .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 1))
                        Text(card.ownerName.replacingOccurrences(of: "\n", with: " "))
                            .font(.system(size: cardW * 0.038, weight: .medium))
                            .foregroundStyle(.black.opacity(0.75))
                            .lineLimit(1)
                    }
                    Spacer()
                    feedCategoryPill(card.category, cardW: cardW, cardH: cardH, color: borderColor)
                }
                .padding(.top, cardH * 0.055)

                Spacer()

                // Centre: title + date/location pills
                VStack(spacing: cardH * 0.025) {
                    Text(card.title)
                        .font(.custom("Nohemi-Medium", fixedSize: 40))
                        .foregroundStyle(.black.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    HStack(spacing: cardW * 0.01) {
                        feedInfoPill(text: card.dateText, icon: "calendar", cardW: cardW, cardH: cardH)
                        feedInfoPill(text: card.location, icon: "paperplane", cardW: cardW, cardH: cardH)
                    }
                }
                .padding(.bottom, cardH * 0.06)

                Spacer()

                // Bottom: participants
                participantsGroup(cardW: cardW)
                    .padding(.bottom, cardH * 0.055)
            }
            .padding(.horizontal, cardW * 0.09)
        }
        .frame(width: cardW, height: cardH)
        .compositingGroup()
    }

    private func feedCategoryPill(_ text: String, cardW: CGFloat, cardH: CGFloat, color: Color) -> some View {
        Text(text.isEmpty ? "Category" : text)
            .font(.system(size: cardW * 0.035, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, cardW * 0.04)
            .frame(height: cardH * 0.055)
            .background(
                Capsule(style: .continuous)
                    .fill(color)
            )
    }

    private func feedInfoPill(text: String, icon: String, cardW: CGFloat, cardH: CGFloat) -> some View {
        HStack(spacing: cardW * 0.01) {
            Image(systemName: icon)
                .font(.system(size: cardW * 0.05, weight: .semibold))
            Text(text.isEmpty ? "—" : text)
                .font(.system(size: cardW * 0.05, weight: .semibold))
        }
        .foregroundStyle(.black)
        .padding(.horizontal, cardW * 0.01)
        .frame(height: cardH * 0.057)
    }

    private func participantsGroup(cardW: CGFloat) -> some View {
        VStack(alignment: .center, spacing: cardW * 0.02) {
            HStack(spacing: -cardW * 0.06) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color(hex: "D8D8D8"))
                        .frame(width: cardW * 0.12, height: cardW * 0.12)
                        .overlay(Circle().stroke(.black, lineWidth: 1.5))
                }
            }
            Text("Other participants")
                .font(.system(size: cardW * 0.03, weight: .medium))
                .foregroundStyle(.black.opacity(0.6))
        }
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

// ── MatchRowCardView (List Item) ─────────────────────────────────────────────
private struct MatchRowCardView: View {
    let info: MatchedCardInfo
    let width: CGFloat

    private var card: DeckCard { info.card }

    var body: some View {
        let corner = width * 0.06
        let innerCorner = width * 0.045
        let borderColor = card.color == Color(hex: "111111") ? Color(hex: "3478F6") : card.color

        ZStack {
            // Card Base
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.96),
                            Color.white.opacity(0.9),
                            Color(hex: "F1EEF8").opacity(0.88)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Pattern Background
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(
                    ImagePaint(
                        image: Image("ELIZBARSVG"),
                        sourceRect: CGRect(x: 0, y: 0, width: 1, height: 1),
                        scale: 0.3
                    )
                )
                .opacity(0.16)
                .blendMode(.multiply)
                .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: innerCorner, style: .continuous)
                .stroke(borderColor, lineWidth: width * 0.025)
                .padding(width * 0.02)

            VStack(alignment: .leading, spacing: width * 0.04) {
                
                // Profile section — the card's owner (color + initial)
                HStack(spacing: width * 0.02) {
                    let ownerColor = info.owner?.avatarColor ?? card.color
                    let ownerInitial = info.owner?.initial
                        ?? card.ownerName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1).uppercased()

                    Circle()
                        .fill(ownerColor)
                        .frame(width: width * 0.08, height: width * 0.08)
                        .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 1))
                        .overlay(
                            Text(ownerInitial)
                                .font(.system(size: width * 0.04, weight: .bold))
                                .foregroundStyle(.white)
                        )

                    Text((info.owner?.displayName ?? card.ownerName).replacingOccurrences(of: "\n", with: " "))
                        .font(.system(size: width * 0.038, weight: .medium))
                        .foregroundStyle(.black.opacity(0.75))
                        .lineLimit(1)

                    Spacer()
                }

                // Title section (using Nohemi-Medium)
                Text(card.title.replacingOccurrences(of: "\n", with: " "))
                    .font(.custom("Nohemi-Medium", fixedSize: width * 0.08))
                    .foregroundStyle(.black.opacity(0.82))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                // Date and location info
                HStack(spacing: width * 0.04) {
                    rowInfo(text: card.dateText, icon: "calendar", width: width)
                    rowInfo(text: card.location, icon: "paperplane", width: width)
                }

                HStack(alignment: .bottom) {
                    // Category pill
                    categoryPill(card.category, width: width, color: borderColor)

                    Spacer()

                    // Participants on bottom right — others who also matched this card
                    VStack(alignment: .trailing, spacing: width * 0.01) {
                        Text("other participants")
                            .font(.system(size: width * 0.025, weight: .medium))
                            .foregroundStyle(.black.opacity(0.6))

                        if info.otherMatchers.isEmpty {
                            Text("Just you so far")
                                .font(.system(size: width * 0.03, weight: .medium))
                                .foregroundStyle(.black.opacity(0.4))
                        } else {
                            HStack(spacing: -width * 0.035) {
                                ForEach(info.otherMatchers.prefix(3)) { user in
                                    matcherBadge(color: user.avatarColor, text: user.initial)
                                }
                                if info.otherMatchers.count > 3 {
                                    matcherBadge(
                                        color: Color.black.opacity(0.6),
                                        text: "+\(info.otherMatchers.count - 3)"
                                    )
                                }
                            }
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
    
    // A small circular avatar (color + initial) for a participant.
    private func matcherBadge(color: Color, text: String) -> some View {
        Circle()
            .fill(color)
            .frame(width: width * 0.075, height: width * 0.075)
            .overlay(Circle().stroke(.black, lineWidth: 1.5))
            .overlay(
                Text(text)
                    .font(.system(size: width * 0.032, weight: .bold))
                    .foregroundStyle(.white)
            )
    }

    // Sub-view function for the Date & Location
    private func rowInfo(text: String, icon: String, width: CGFloat) -> some View {
        HStack(spacing: width * 0.015) {
            Image(systemName: icon)
                .font(.system(size: width * 0.045, weight: .semibold))
            Text(text.isEmpty ? "—" : text)
                .font(.system(size: width * 0.045, weight: .semibold))
        }
        .foregroundStyle(.black.opacity(0.8))
    }
    
    // Sub-view function for the Category pill
    private func categoryPill(_ text: String, width: CGFloat, color: Color) -> some View {
        Text(text.isEmpty ? "Category" : text)
            .font(.system(size: width * 0.035, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, width * 0.04)
            .frame(height: width * 0.08)
            .background(
                Capsule(style: .continuous).fill(color)
            )
    }
}

// ── Shared Buttons ───────────────────────────────────────────────────────────
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

                Image(systemName: "chevron.left")
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
                        Image(systemName: "chevron.left")
                            .font(.system(size: size * 0.42, weight: .medium))
                            .foregroundStyle(.white)
                    )
                    .overlay(
                        Image(systemName: "chevron.left")
                            .font(.system(size: size * 0.42))
                            .foregroundStyle(.clear)
                            .overlay(
                                LinearGradient(
                                    colors: [.white.opacity(0.6), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .mask(
                                    Image(systemName: "rectangle.portrait.on.rectangle.portrait")
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

struct BackToFeedButton: View {
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.white)
                    .shadow(color: .white.opacity(0.4), radius: size * 0.1, x: 0, y: size * 0.05)
                    .shadow(color: .white,radius: size * 0.1)
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .clear, .black.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )

                Image(systemName: "chevron.left")
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.black, .topbuttonsgradient],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }
}


