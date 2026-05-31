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
    @Binding var shakeLocationThrows: Int
    
    let categories = ["Food", "Social", "Art", "Fun", "Travel"]
    
    @State private var draftDate: Date = Date()

    var body: some View {
        let cardRadius = width * 0.08

        ZStack {
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(card.color)
                .frame(width: width * 0.96, height: height * 0.9)
                .blur(radius: width * 0.1)
                .blendMode(.plusLighter)

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

            ZStack {
                RoundedRectangle(cornerRadius: width * 0.07, style: .continuous)
                    .stroke(card.color.opacity(0.95), lineWidth: width * 0.030)
                    .padding(width * 0.035)

                RoundedRectangle(cornerRadius: width * 0.07, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    .padding(width * 0.049)
            }

            VStack(spacing: 0) {
                Text("Drafting new card...")
                    .font(.system(size: width * 0.035, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.4))
                    .padding(.top, height * 0.055)

                Spacer()

                VStack(spacing: height * 0.025) {
                    
                    // 3. Smart Title Placeholder + Shake Modifier
                    TextField(
                        shakeTitleThrows > 0 && card.title.isEmpty ? "* Required *" : "What are\nwe doing?",
                        text: $card.title,
                        axis: .vertical
                    )
                    .font(.custom("Nohemi-Medium", size: width * 0.095))
                    .foregroundStyle(.black.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .tint(Color(hex: "3478F6"))
                    .fixedSize(horizontal: false, vertical: true)
                    .modifier(Shake(animatableData: CGFloat(shakeTitleThrows))) // Applies the shake
                    
                    HStack(spacing: width * 0.035) {
                        ZStack {
                            pill(card.dateText.isEmpty ? "When?" : card.dateText)
                            
                            // 4. Restricted DatePicker (in: Date()... blocks past dates)
                            DatePicker("", selection: $draftDate, in: Date()..., displayedComponents: .date)
                                .labelsHidden()
                                .scaleEffect(2.5)
                                .colorMultiply(.clear)
                        }
                        
                        Menu {
                            ForEach(categories, id: \.self) { cat in
                                Button(cat) { card.category = cat }
                            }
                        } label: {
                            pill(card.category)
                        }
                    }
                    
                    // 5. Smart Location Placeholder + Shake Modifier
                    TextField(
                        shakeLocationThrows > 0 && card.location.isEmpty ? "* Required *" : "Where?",
                        text: $card.location
                    )
                    .font(.system(size: width * 0.043, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .frame(width: width * 0.5, height: height * 0.057)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.3))
                            .overlay(Capsule().stroke(Color.black.opacity(0.1), lineWidth: 1))
                    )
                    .modifier(Shake(animatableData: CGFloat(shakeLocationThrows))) // Applies the shake
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
        .onChange(of: draftDate) { _, newDate in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            card.dateText = formatter.string(from: newDate)
        }
    }

    private func pill(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: width * 0.025))
        }
        .font(.system(size: width * 0.043, weight: .semibold))
        .foregroundStyle(.black.opacity(0.8))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .frame(width: width * 0.32, height: height * 0.057)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.1), radius: width * 0.012, x: 0, y: width * 0.006)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.black.opacity(0.15), lineWidth: 1)
        )
    }
}
