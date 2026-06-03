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
            let horizontalPadding = max(0, (containerWidth - cardWidth) / 2)

            ScrollView(.horizontal) {
                LazyHStack(spacing: cardWidth * 0.065) {
                    
                    if let draft = viewModel.draftCard {
                        ZStack(alignment: .topLeading) {
                            EditableCardView(
                                card: Binding(
                                    get: { viewModel.draftCard ?? draft },
                                    set: { newValue in
                                        // THE FIX: Prevents the text field's "focus loss" from resurrecting a blank draft
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
                .padding(.horizontal, horizontalPadding + sideInset)
                .padding(.vertical, cardHeight * 0.05)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
            .frame(height: cardHeight + cardHeight * 0.1)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.draftCard != nil)
        }
    }
}

// Keep your existing CarouselCardView directly below this!

// Ensure you keep your CarouselCardView exactly as it was at the bottom of this file!

// MARK: - Carousel Card View (Visually identical to FeedCardView, but no drag gestures)
struct CarouselCardView: View {
    let card: DeckCard
    let width: CGFloat
    let height: CGFloat

    @State private var idleOffsetY: CGFloat = 0
    @State private var idleRotation: Double = 0
    @State private var idleScale: CGFloat = 1

    var body: some View {
        let cardRadius = width * 0.08

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
                Text("10% of your friends already voted")
                    .font(.system(size: width * 0.035, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.18))
                    .underline()
                    .padding(.top, height * 0.055)

                Spacer()

                VStack(spacing: height * 0.025) {
                    Text(card.title)
                        .font(.custom("Nohemi-Medium", fixedSize: 40))
                        .foregroundStyle(.black.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    HStack(spacing: width * 0.035) {
                        pill(card.dateText)
                        pill(card.location)
                    }
                }
                .padding(.bottom, height * 0.06)

                Spacer()

                Text("By \(card.ownerName)")
                    .font(.system(size: width * 0.033, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.18))
                    .padding(.bottom, height * 0.055)
            }
            .padding(.horizontal, width * 0.09)
        }
        .frame(width: width, height: height)
        .compositingGroup()
        // Kept only the idle animations, removed the drag offsets
        .offset(y: idleOffsetY)
        .rotationEffect(.degrees(idleRotation))
        .scaleEffect(idleScale)
        .onAppear { startIdle() }
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: width * 0.043, weight: .semibold))
            .foregroundStyle(.black.opacity(0.62))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(width: width * 0.27, height: height * 0.057)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.58))
                    .shadow(color: .black.opacity(0.22), radius: width * 0.012, x: 0, y: width * 0.006)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
    }

    private func startIdle() {
        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            idleOffsetY = -height * 0.01
        }
//        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
//            idleRotation = 1.7
//        }
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            idleScale = 1.015
        }
    }
}

