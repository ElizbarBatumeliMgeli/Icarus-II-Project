//
//  EditableCardView.swift
//  Icarus II Project
//
//  Created by Elizbar Kheladze on 31/05/26.
//

import SwiftUI

// 1. The custom shake animation effect
struct Shake: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit = 4
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

struct EditableCardView: View {
    @Binding var card: DeckCard
    let width: CGFloat
    let height: CGFloat
    
    // 2. Bindings to receive the shake triggers from the save button
    @Binding var shakeTitleThrows: Int
    @Binding var shakeCategoryThrows: Int
    @Binding var shakeLocationThrows: Int
    
    let categories = ["Food", "Social", "Art", "Fun", "Travel"]
    
    @State private var draftDate: Date = Date()

    var body: some View {
        let cardRadius = width * 0.08
        let borderColor = color(for: card.category)

        ZStack {
            // Glowing shadow
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(card.color)
                .frame(width: width * 0.96, height: height * 0.9)
                .blur(radius: width * 0.1)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.3), value: card.color) // Smooth color transition

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
                .animation(.easeInOut(duration: 0.3), value: card.color)

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
            .clipShape(
                RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
            )
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 0.3), value: card.color)

            // Borders
            ZStack {
                RoundedRectangle(cornerRadius: width * 0.07, style: .continuous)
                    .stroke(borderColor.opacity(0.95), lineWidth: width * 0.030)
                    .padding(width * 0.035)

                RoundedRectangle(cornerRadius: width * 0.07, style: .continuous)
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
            .animation(.easeInOut(duration: 0.3), value: borderColor)

            // Content
            VStack(spacing: 0) {
                // Top: editable category pill (right)
                HStack(alignment: .center, spacing: width * 0.02) {
                    Spacer()
                    Menu {
                        ForEach(categories, id: \.self) { cat in
                            Button(cat) {
                                card.category = cat
                            }
                        }
                    } label: {
                        categoryPill(card.category.isEmpty ? "add a category" : card.category, color: card.category.isEmpty ? Color(hex: "000000") : borderColor)
                    }
                    .modifier(Shake(animatableData: CGFloat(shakeCategoryThrows)))
                }
                .padding(.top, height * 0.055)

                Spacer()

                // Centre: title + date/location fields (editable)
                VStack(spacing: height * 0.025) {
                    // Title TextField with visible placeholder
                    TextField(
                        "",
                        text: $card.title,
                        prompt: Text(shakeTitleThrows > 0 && card.title.isEmpty ? "* Required *" : "What are\nwe doing?")
                            .foregroundColor(shakeTitleThrows > 0 ? .red : .black.opacity(0.45)),
                        axis: .vertical
                    )
                    .font(.custom("Nohemi-Medium", fixedSize: 40))
                    .foregroundStyle(.black.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .tint(borderColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .modifier(Shake(animatableData: CGFloat(shakeTitleThrows)))

                    HStack(spacing: width * 0.01) {
                        datePill()
                        locationPill(tintColor: borderColor)
                    }
                }
                .padding(.bottom, height * 0.06)

                Spacer()

                // Bottom: participants
//                participantsGroup()
//                    .padding(.bottom, height * 0.055)
            }
            .padding(.horizontal, width * 0.09)
        }
        .frame(width: width, height: height)
        .onAppear {
            // Apply the current date on load if it's empty, formatting it immediately
            if card.dateText.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yy"
                card.dateText = formatter.string(from: draftDate)
            }
        }
        .onChange(of: draftDate) { _, newDate in
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yy" // Forces strict formatting (e.g. 03/06/26)
            card.dateText = formatter.string(from: newDate)
        }
    }

    // MARK: - Category Color Mapping
    private func color(for category: String) -> Color {
        switch category {
        case "Food": return Color(hex: "FF9500")   // Energetic Orange
        case "Social": return Color(hex: "3478F6") // Vibrant Blue
        case "Art": return Color(hex: "AF52DE")    // Creative Purple
        case "Fun": return Color(hex: "FF2D55")    // Exciting Pink
        case "Travel": return Color(hex: "34C759") // Nature Green
        default: return Color(hex: "111111")
        }
    }

    private func categoryPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: width * 0.035, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, width * 0.04)
            .frame(height: height * 0.055)
            .background(
                Capsule(style: .continuous)
                    .fill(color)
            )
            .animation(.easeInOut(duration: 0.3), value: color)
    }

    private func infoPill(text: String, icon: String) -> some View {
        HStack(spacing: width * 0.01) {
            Image(systemName: icon)
                .font(.system(size: width * 0.05, weight: .semibold))
            Text(text)
                .font(.system(size: width * 0.05, weight: .semibold))
        }
        .foregroundStyle(.black)
        .padding(.horizontal, width * 0.01)
        .frame(height: height * 0.057)
    }

    private func datePill() -> some View {
        ZStack {
            // 1. The visual pill that shows our strict formatting
            infoPill(text: card.dateText.isEmpty ? "dd/mm/yy" : card.dateText, icon: "calendar")
            
            // 2. The invisible interactive layer
            DatePicker("", selection: $draftDate, in: Date()..., displayedComponents: .date)
                .labelsHidden()
                // Make the native component completely transparent but retain hit-testing
                .colorMultiply(.clear)
                // Expand its hit area to cover the visual pill underneath
                .scaleEffect(x: 3.5, y: 2.0)
                .contentShape(Rectangle())
        }
        .clipped() // Prevent the scaled hit area from overlapping the Location TextField
    }

    private func locationPill(tintColor: Color) -> some View {
        HStack(spacing: width * 0.01) {
            Image(systemName: "paperplane")
                .font(.system(size: width * 0.05, weight: .semibold))
            
            // Location TextField with visible placeholder
            TextField(
                "",
                text: $card.location,
                prompt: Text(shakeLocationThrows > 0 && card.location.isEmpty ? "* Required *" : "Where?")
                    .foregroundColor(shakeLocationThrows > 0 ? .red : .black.opacity(0.45))
            )
            .font(.system(size: width * 0.05, weight: .semibold))
            .tint(tintColor)
        }
        .foregroundStyle(.black)
        .padding(.horizontal, width * 0.01)
        .frame(height: height * 0.057)
        .modifier(Shake(animatableData: CGFloat(shakeLocationThrows)))
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
}
