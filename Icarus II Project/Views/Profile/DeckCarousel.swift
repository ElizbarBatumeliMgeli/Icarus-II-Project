//
//  DeckCarousel.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI

struct DeckCarousel: View {
    @Bindable var viewModel: DeckViewModel
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let sideInset: CGFloat
//    let isDeleteMode: Bool
//    let onEdit: (DeckCard) -> Void
    let onDelete: (DeckCard) -> Void
    
    // State triggers for our smart shake validation
    @State private var shakeTitleThrows: Int = 0
    @State private var shakeLocationThrows: Int = 0
    
    @State private var showLogoutAlert = false
    @Environment(AppleAuthManager.self) private var authManager

    var body: some View {
        GeometryReader { geo in
            let containerWidth = geo.size.width
            let containerHeight = geo.size.height
            // Mathematically perfect centering
            let horizontalPadding = max(0, (containerWidth - cardWidth) / 2)

            ScrollView (.vertical) {
                LazyVStack(spacing: cardWidth * 0.065) {
                    
//                    if let draft = viewModel.draftCard {
//                        ZStack(alignment: .topLeading) {
//                            EditableCardView(
//                                card: Binding(
//                                    get: { viewModel.draftCard ?? draft },
//                                    set: { newValue in
//                                        if viewModel.draftCard != nil {
//                                            viewModel.draftCard = newValue
//                                        }
//                                    }
//                                ),
//                                width: cardWidth,
//                                height: cardHeight,
//                                shakeTitleThrows: $shakeTitleThrows,
//                                shakeLocationThrows: $shakeLocationThrows
//                            )
//                            
//                            // SAVE BUTTON
//                            Button {
//                                var isTitleInvalid = false
//                                var isLocInvalid = false
//                                
//                                // 1. Check if the fields are empty or match the placeholders
//                                if let currentDraft = viewModel.draftCard {
//                                    let t = currentDraft.title.trimmingCharacters(in: .whitespacesAndNewlines)
//                                    let l = currentDraft.location.trimmingCharacters(in: .whitespacesAndNewlines)
//                                    
//                                    if t.isEmpty || t == "What are\nwe doing?" || t == "* Required *" {
//                                        isTitleInvalid = true
//                                    }
//                                    if l.isEmpty || l == "Where?" || l == "* Required *" {
//                                        isLocInvalid = true
//                                    }
//                                }
//                                
//                                // 2. Trigger shakes and force empty state for smart placeholders
//                                if isTitleInvalid {
//                                    viewModel.draftCard?.title = ""
//                                    withAnimation(.default) { shakeTitleThrows += 1 }
//                                }
//                                if isLocInvalid {
//                                    viewModel.draftCard?.location = ""
//                                    withAnimation(.default) { shakeLocationThrows += 1 }
//                                }
//                                
//                                // 3. If valid, safely close the draft
//                                if !isTitleInvalid && !isLocInvalid {
//                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
//                                        viewModel.saveDraft()
//                                    }
//                                }
//                            } label: {
//                                Image(systemName: "checkmark")
//                                    .font(.system(size: cardWidth * 0.045, weight: .bold))
//                                    .foregroundStyle(.white)
//                                    .frame(width: cardWidth * 0.09, height: cardWidth * 0.09)
//                                    .background(Color(hex: "5BBF61"), in: Circle())
//                            }
//                            .buttonStyle(.plain)
//                            .offset(x: cardWidth * 0.93, y: -cardWidth * 0.012)
//
//                            // CANCEL BUTTON
//                            Button {
//                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
//                                    viewModel.cancelDraft()
//                                }
//                            } label: {
//                                Image(systemName: "xmark")
//                                    .font(.system(size: cardWidth * 0.045, weight: .bold))
//                                    .foregroundStyle(.white)
//                                    .frame(width: cardWidth * 0.07, height: cardWidth * 0.07)
//                                    .background(Color(hex: "EE5C5C"), in: Circle())
//                            }
//                            .buttonStyle(.plain)
//                            .offset(x: -cardWidth * 0.02, y: -cardWidth * 0.012)
//                        }
//                        .transition(.scale.combined(with: .opacity))
//                    }

                    ForEach(viewModel.cards) { card in
                        SwipeToDeleteWrapper(cardWidth: cardWidth, action: {
                            onDelete(card)
                        }) {
                            CarouselCardView(
                                card: card,
                                width: cardWidth,
                                height: cardHeight
                            )
                        }
                    }
                    
                    // Logout Picker Menu
                    Menu {
                        Button("Log Out", role: .destructive) {
                            showLogoutAlert = true
                        }
//                        Button("Delete Account", role: .destructive) {
//                            // TODO: Eliminate account logic
//                            print("Delete account tapped")
//                        }
                    } label: {
                        Text("Logout")
                            .font(.system(size: containerWidth * 0.040, weight: .semibold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, containerWidth * 0.04)
                            .frame(height: containerHeight * 0.055)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color(hex: "D3D3D3"))
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, cardHeight * 0.05)
                }
                .scrollTargetLayout()
                .padding(.horizontal, horizontalPadding)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .frame(maxHeight: .infinity)
        }
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                Task {
                    await authManager.logout()
                }
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
}

struct CarouselCardView: View {
    let card: DeckCard
    let width: CGFloat
    let height: CGFloat 

    var body: some View {
        let sw = width / 0.82
        let cardRadius = sw * 0.06
        let innerCorner = sw * 0.045
        let borderColor = card.color == Color(hex: "111111") ? Color(hex: "3478F6") : card.color

        ZStack {
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

            // Border
            RoundedRectangle(cornerRadius: innerCorner, style: .continuous)
                .stroke(borderColor, lineWidth: sw * 0.025)
                .padding(sw * 0.02)

            VStack(alignment: .leading, spacing: sw * 0.04) {
                // Category pill
                HStack(alignment: .bottom) {
                    Spacer()
                    categoryPill(card.category, color: borderColor, sw: sw)
                }
                
                // Title section
                Text(card.title.replacingOccurrences(of: "\n", with: " "))
                    .font(.custom("Nohemi-Medium", fixedSize: sw * 0.08))
                    .foregroundStyle(.black.opacity(0.82))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                // Date and location info
                HStack(spacing: sw * 0.04) {
                    rowInfo(text: card.dateText, icon: "calendar", sw: sw)
                    rowInfo(text: card.location, icon: "paperplane", sw: sw)
                }
                
                Spacer()
                
            }
            .padding(.horizontal, sw * 0.08)
            .padding(.top, sw * 0.07)
            .padding(.bottom, sw * 0.06)
        }
        .frame(minHeight: sw * 0.55) // Forces the background to be 50% taller overall
        .shadow(color: .black.opacity(0.2), radius: sw * 0.02, x: 0, y: sw * 0.01)
        .compositingGroup()
    }

    private func rowInfo(text: String, icon: String, sw: CGFloat) -> some View {
        HStack(spacing: sw * 0.015) {
            Image(systemName: icon)
                .font(.system(size: sw * 0.045, weight: .semibold))
            Text(text.isEmpty ? "—" : text)
                .font(.system(size: sw * 0.045, weight: .semibold))
        }
        .foregroundStyle(.black.opacity(0.8))
    }

    private func categoryPill(_ text: String, color: Color, sw: CGFloat) -> some View {
        Text(text.isEmpty ? "Category" : text)
            .font(.system(size: sw * 0.035, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, sw * 0.04)
            .padding(.vertical, sw * 0.02)
            .background(
                Capsule(style: .continuous)
                    .fill(color)
            )
    }
}

struct SwipeToDeleteWrapper<Content: View>: View {
    let cardWidth: CGFloat
    let action: () -> Void
    @ViewBuilder let content: Content
    
    @State private var offset: CGFloat = 0
    @State private var previousOffset: CGFloat = 0
    @State private var isDeleted: Bool = false
    
    var body: some View {
        if !isDeleted {
            let sw = cardWidth / 0.82
            let cardRadius = sw * 0.06
            let buttonWidth = sw * 0.25
            
            ZStack(alignment: .trailing) {
                // Background Trash Area
                RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                    .fill(Color(hex: "EE5C5C"))
                    .onTapGesture {
                        if offset == -buttonWidth {
                            deleteCard()
                        }
                    }
                
                Image(systemName: "trash")
                    .font(.system(size: sw * 0.07, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.trailing, sw * 0.08)
                    .opacity(offset < -sw * 0.1 ? 1 : 0)
                    .scaleEffect(offset < -sw * 0.25 ? 1.1 : 1.0)
                    .animation(.spring(), value: offset)
                    .onTapGesture {
                        if offset == -buttonWidth {
                            deleteCard()
                        }
                    }
                
                content
                    .offset(x: offset)
                    .gesture(
                        DragGesture(minimumDistance: 20, coordinateSpace: .local)
                            .onChanged { gesture in
                                let totalTranslation = gesture.translation.width + previousOffset
                                if totalTranslation < 0 { // Only allow swiping left
                                    offset = totalTranslation
                                } else {
                                    offset = 0
                                }
                            }
                            .onEnded { gesture in
                                if offset < -cardWidth * 0.4 {
                                    // Trigger auto delete
                                    deleteCard()
                                } else if offset < -buttonWidth * 0.5 {
                                    // Snap to button open state
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        offset = -buttonWidth
                                        previousOffset = offset
                                    }
                                } else {
                                    // Snap back
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        offset = 0
                                        previousOffset = 0
                                    }
                                }
                            }
                    )
            }
        }
    }
    
    private func deleteCard() {
        withAnimation(.easeOut(duration: 0.3)) {
            offset = -cardWidth * 1.5 // Swipe it completely off screen
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isDeleted = true
            action()
        }
    }
}
