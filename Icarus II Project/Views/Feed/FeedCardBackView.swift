//
//  FeedCardBackView.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI

struct FeedCardBackView: View {
    let card: DeckCard
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let cardRadius = width * 0.08

        return RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
            .fill(card.color)
            .overlay(
                RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                    .fill(
                        ImagePaint(
                            image: Image("ELIZBARSVG"),
                            sourceRect: CGRect(x: 0, y: 0, width: 1, height: 1),
                            scale: 0.3
                        )
                    )
                    .opacity(0.18)
                    .blendMode(.multiply)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: width * 0.02, x: 0, y: width * 0.01)
            .frame(width: width, height: height)
    }
}
