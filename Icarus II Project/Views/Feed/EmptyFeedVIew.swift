//
//  EmptyFeedVIew.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI

struct EmptyFeedView: View {
    let width: CGFloat
    let height: CGFloat
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            SpotlightBeam(width: width, height: height, angle: isAnimating ? 12 : -14, intensity: 0.95)
                .offset(x: -width * 0.25)
                
            
            SpotlightBeam(width: width, height: height, angle: isAnimating ? -10 : 16, intensity: 0.8)
                .offset(x: width * 0.25)
            
            Text("You swiped through all the cards…\nIt’s time to plan!!")
                .font(.custom("Nohemi-Medium", fixedSize: 30))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.7)
                .frame(width: width * 0.8)
                .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: 6)
                .offset(y: height * 0.05)
        }
        .frame(width: width, height: height)
        .allowsTightening(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct SpotlightBeam: View {
    var width: CGFloat
    var height: CGFloat
    var angle: Double
    var intensity: Double

    var body: some View {
        let beamWidth = width * 2.8
        let beamHeight = height * 1.85

        Path { path in
            let padding = width * 0.6
            path.move(to: CGPoint(x: beamWidth / 2 - width * 0.05, y: 0))
            path.addLine(to: CGPoint(x: beamWidth / 2 + width * 0.05, y: 0))
            path.addLine(to: CGPoint(x: beamWidth - padding, y: beamHeight))
            path.addLine(to: CGPoint(x: padding, y: beamHeight))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                stops: [
                    .init(color: .spotLight.opacity(intensity), location: 0.0),
                    .init(color: .spotLight.opacity(intensity * 0.65), location: 0.25),
                    .init(color: .spotLight.opacity(intensity * 0.25), location: 0.65),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .blur(radius: width * 0.07)
        .frame(width: beamWidth, height: beamHeight)
        .rotationEffect(.degrees(angle), anchor: .top)
        .offset(y: -height * 0.2)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        
        
    }
}
