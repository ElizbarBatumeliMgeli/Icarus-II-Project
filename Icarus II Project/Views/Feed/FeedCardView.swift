//
//  FeedCardView.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI

struct FeedCardView: View {
    let card: DeckCard
    let width: CGFloat
    let height: CGFloat
    let onSwipe: (Bool) -> Void

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var isDragging: Bool = false
    @State private var idleOffsetY: CGFloat = 0
    @State private var idleRotation: Double = 0
    @State private var idleScale: CGFloat = 1

    var body: some View {
        let cardRadius = width * 0.08
        let borderColor = card.color == Color(hex: "111111") ? Color(hex: "3478F6") : card.color

        ZStack {
            // Glowing shadow behind the card, matching card.color
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(card.color)
                .frame(width: width * 0.96, height: height * 0.9)
                .blur(radius: width * 0.1)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
            
//            Circle()
//                .fill(card.color.opacity(0.95))
//                .frame(width: width , height: width)
//                .blur(radius: width * 0.1)
//                .offset(x: width, y: -height * 0.5)
//
//            Circle()
//                .fill(card.color.opacity(0.72))
//                .frame(width: width * 0.95, height: width * 0.95)
//                .blur(radius: width * 0.28)
//                .offset(x: width, y: height * 0.5)

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

            LinearGradient(
                colors: [
                    Color.white.opacity(0.2),
                    Color.clear,
                    card.color.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(
                RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
            )
            .allowsHitTesting(false)

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
        .offset(x: offset.width, y: offset.height + (isDragging ? 0 : idleOffsetY))
        .rotationEffect(.degrees(rotation + (isDragging ? 0 : idleRotation)))
        .scaleEffect(isDragging ? 1 : idleScale)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    offset = value.translation
                    rotation = Double(value.translation.width / width) * 10
                    withAnimation(.easeOut(duration: 0.2)) {
                        idleOffsetY = 0
                        idleRotation = 0
                        idleScale = 1
                    }
                }
                .onEnded { value in
                    if abs(value.translation.width) > width * 0.27 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                            offset = CGSize(
                                width: value.translation.width > 0 ? width * 1.4 : -width * 1.4,
                                height: value.translation.height
                            )
                            rotation = value.translation.width > 0 ? 16 : -16
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                            offset = .zero
                            rotation = 0
                            isDragging = false
                            startIdle()
                            onSwipe(value.translation.width > 0)
                        }
                    } else {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                            offset = .zero
                            rotation = 0
                        }
                        isDragging = false
                        startIdle()
                    }
                }
        )
        .onAppear { startIdle() }
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
        guard !isDragging else { return }
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

