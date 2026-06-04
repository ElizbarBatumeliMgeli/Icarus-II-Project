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
    let onEdit: (DeckCard) -> Void
    let onDelete: (DeckCard) -> Void
    
    // State triggers for our smart shake validation
    @State private var shakeTitleThrows: Int = 0
    @State private var shakeLocationThrows: Int = 0

    var body: some View {
        GeometryReader { geo in
            let containerWidth = geo.size.width
            // Mathematically perfect centering
            let horizontalPadding = max(0, (containerWidth - cardWidth) / 2)

            ScrollView(.horizontal) {
                LazyHStack(spacing: cardWidth * 0.065) {
                    
                    if let draft = viewModel.draftCard {
                        ZStack(alignment: .topLeading) {
                            EditableCardView(
                                card: Binding(
                                    get: { viewModel.draftCard ?? draft },
                                    set: { newValue in
                                        if viewModel.draftCard != nil {
                                            viewModel.draftCard = newValue
                                        }
                                    }
                                ),
                                width: cardWidth,
                                height: cardHeight,
                                shakeTitleThrows: $shakeTitleThrows,
                                shakeLocationThrows: $shakeLocationThrows
                            )
                            
                            // SAVE BUTTON
                            Button {
                                var isTitleInvalid = false
                                var isLocInvalid = false
                                
                                // 1. Check if the fields are empty or match the placeholders
                                if let currentDraft = viewModel.draftCard {
                                    let t = currentDraft.title.trimmingCharacters(in: .whitespacesAndNewlines)
                                    let l = currentDraft.location.trimmingCharacters(in: .whitespacesAndNewlines)
                                    
                                    if t.isEmpty || t == "What are\nwe doing?" || t == "* Required *" {
                                        isTitleInvalid = true
                                    }
                                    if l.isEmpty || l == "Where?" || l == "* Required *" {
                                        isLocInvalid = true
                                    }
                                }
                                
                                // 2. Trigger shakes and force empty state for smart placeholders
                                if isTitleInvalid {
                                    viewModel.draftCard?.title = ""
                                    withAnimation(.default) { shakeTitleThrows += 1 }
                                }
                                if isLocInvalid {
                                    viewModel.draftCard?.location = ""
                                    withAnimation(.default) { shakeLocationThrows += 1 }
                                }
                                
                                // 3. If valid, safely close the draft
                                if !isTitleInvalid && !isLocInvalid {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        viewModel.saveDraft()
                                    }
                                }
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.system(size: cardWidth * 0.045, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: cardWidth * 0.09, height: cardWidth * 0.09)
                                    .background(Color(hex: "5BBF61"), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .offset(x: cardWidth * 0.93, y: -cardWidth * 0.012)

                            // CANCEL BUTTON
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    viewModel.cancelDraft()
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: cardWidth * 0.045, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: cardWidth * 0.07, height: cardWidth * 0.07)
                                    .background(Color(hex: "EE5C5C"), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .offset(x: -cardWidth * 0.02, y: -cardWidth * 0.012)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    ForEach(viewModel.cards) { card in
                        ZStack(alignment: .topLeading) {
                            CarouselCardView(
                                card: card,
                                width: cardWidth,
                                height: cardHeight
                            )
                            .onTapGesture {
                                onEdit(card)
                            }

                            Button {
                                onDelete(card)
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: cardWidth * 0.045, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: cardWidth * 0.07, height: cardWidth * 0.07)
                                    .background(.black, in: Circle())
                            }
                            .buttonStyle(.plain)
                            .offset(x: -cardWidth * 0.02, y: -cardWidth * 0.012)
                        }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, horizontalPadding)
                // THE FIX: Provide just enough padding to protect the drop shadows and bounce.
                .padding(.top, cardHeight * 0.05)
                .padding(.bottom, cardHeight * 0.15)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
            .frame(height: cardHeight * 1.2)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.draftCard != nil)
        }
    }
}

struct CarouselCardView: View {
    let card: DeckCard
    let width: CGFloat
    let height: CGFloat

    @State private var idleOffsetY: CGFloat = 0
    @State private var idleRotation: Double = 0
    @State private var idleScale: CGFloat = 1

    var body: some View {
        let cardRadius = width * 0.08
        let borderColor = card.color == Color(hex: "111111") ? Color(hex: "3478F6") : card.color

        ZStack {
            // Glowing shadow
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(card.color)
                .frame(width: width * 0.96, height: height * 0.9)
                .blur(radius: width * 0.1)
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
                .shadow(color: card.color.opacity(0.5), radius: width * 0.1, x: 0, y: width * 0.02)
                .shadow(color: .black.opacity(0.24), radius: width * 0.025, x: 0, y: width * 0.012)

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
                RoundedRectangle(cornerRadius: width * 0.07, style: .continuous)
                    .stroke(card.color.opacity(0.95), lineWidth: width * 0.030)
                    .padding(width * 0.035)

                RoundedRectangle(cornerRadius: width * 0.07, style: .continuous)
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
                        lineWidth: width * 0.011
                    )
                    .padding(width * 0.041)

                RoundedRectangle(cornerRadius: width * 0.07, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    .padding(width * 0.049)

                RoundedRectangle(cornerRadius: width * 0.07, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    .blur(radius: 0.7)
                    .padding(width * 0.031)
            }

            // Content
            VStack(spacing: 0) {
                // Top: author (left) + category pill (right)
                HStack(alignment: .center, spacing: width * 0.02) {
                    HStack(spacing: width * 0.02) {
                        Circle()
                            .fill(Color(hex: "BBE4C6"))
                            .frame(width: width * 0.06, height: width * 0.06)
                            .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 1))
                        Text(card.ownerName.replacingOccurrences(of: "\n", with: " "))
                            .font(.system(size: width * 0.038, weight: .medium))
                            .foregroundStyle(.black.opacity(0.75))
                            .lineLimit(1)
                    }
                    Spacer()
                    categoryPill(card.category, color: borderColor)
                }
                .padding(.top, height * 0.055)

                Spacer()

                // Centre: title + date/location pills
                VStack(spacing: height * 0.025) {
                    Text(card.title)
                        .font(.custom("Nohemi-Medium", fixedSize: 40))
                        .foregroundStyle(.black.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    HStack(spacing: width * 0.01) {
                        infoPill(text: card.dateText, icon: "calendar")
                        infoPill(text: card.location, icon: "paperplane")
                    }
                }
                .padding(.bottom, height * 0.06)

                Spacer()

                // Bottom: participants
                participantsGroup()
                    .padding(.bottom, height * 0.055)
            }
            .padding(.horizontal, width * 0.09)
        }
        .frame(width: width, height: height)
        .compositingGroup()
        .offset(y: idleOffsetY)
        .rotationEffect(.degrees(idleRotation))
        .scaleEffect(idleScale)
        .onAppear { startIdle() }
        .onDisappear {
            // Optionally reset states to zero to prevent visual jumps
            // when popping back
            idleOffsetY = 0
            idleRotation = 0
            idleScale = 1
        }
    }

    private func categoryPill(_ text: String, color: Color) -> some View {
        Text(text.isEmpty ? "Category" : text)
            .font(.system(size: width * 0.035, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, width * 0.04)
            .frame(height: height * 0.055)
            .background(
                Capsule(style: .continuous)
                    .fill(color)
            )
    }

    private func infoPill(text: String, icon: String) -> some View {
        HStack(spacing: width * 0.01) {
            Image(systemName: icon)
                .font(.system(size: width * 0.05, weight: .semibold))
            Text(text.isEmpty ? "—" : text)
                .font(.system(size: width * 0.05, weight: .semibold))
        }
        .foregroundStyle(.black)
        .padding(.horizontal, width * 0.01)
        .frame(height: height * 0.057)
    }

    private func participantsGroup() -> some View {
        VStack(alignment: .center, spacing: width * 0.02) {
            HStack(spacing: -width * 0.06) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color(hex: "D8D8D8"))
                        .frame(width: width * 0.12, height: width * 0.12)
                        .overlay(Circle().stroke(.black, lineWidth: 1.5))
                }
            }
            Text("Other participants")
                .font(.system(size: width * 0.03, weight: .medium))
                .foregroundStyle(.black.opacity(0.6))
        }
    }

    private func startIdle() {
        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            idleOffsetY = -height * 0.03
        }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            idleRotation = 1.7
        }
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            idleScale = 1.015
        }
    }
}
