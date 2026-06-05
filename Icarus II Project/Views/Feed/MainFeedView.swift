//
//  MainFeedView.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI

struct MainFeedView: View {
    @Bindable var viewModel: DeckViewModel
    let openProfile: () -> Void
    let openMatches: () -> Void

    // Used to refresh the feed when the app returns to the foreground.
    @Environment(\.scenePhase) private var scenePhase

    // Controls the pop-up stamp animation
    @State private var showDealStamp = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            
            let horizontal = width * 0.07
            let iconSize = width * 0.16
            let iconSizeNavigation = width * 0.12
            let cardWidth = width * 0.70
            let cardHeight = min(width * 1.36, height * 0.6)

            ZStack {
                DottedBackground()

                VStack(spacing: 0) {
                    HStack(alignment: .center) {
                        ProfileIcon(size: iconSizeNavigation) {
                            openProfile()
                        }

                        Spacer()

                        Text("Feed")
                            .font(.system(size: width * 0.106, weight: .semibold))
                            .foregroundStyle(.black)
                            .opacity(0)

                        Spacer()
                        
                        MatchesIcon(size: iconSizeNavigation) {
                            openMatches()
                        }
                    }
                    .padding(.horizontal, horizontal)

                    Spacer(minLength: height * 0.055)

                    if viewModel.isLoading {
                        LoadingFeedView(cardWidth: cardWidth, cardHeight: cardHeight)
                        Spacer()
                    } else if viewModel.feedCards.isEmpty {
                        EmptyFeedView(width: width, height: cardHeight)
                        Spacer()
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: cardWidth * 0.075, style: .continuous)
                                .fill(Color(hex: "D8D8D8"))
                                .frame(width: cardWidth, height: cardHeight * 0.96)
                                .rotationEffect(.degrees(-4.3))
                                .offset(x: -width * 0.025, y: height * 0.012)

                            RoundedRectangle(cornerRadius: cardWidth * 0.075, style: .continuous)
                                .fill(Color(hex: "989898"))
                                .frame(width: cardWidth, height: cardHeight * 0.96)
                                .rotationEffect(.degrees(4.4))
                                .offset(x: width * 0.025, y: -height * 0.004)

                            if let second = viewModel.feedCards.dropFirst().first {
                                FeedCardBackView(
                                    card: second,
                                    width: cardWidth,
                                    height: cardHeight
                                )
                                .zIndex(0)
                            }

                            if let first = viewModel.feedCards.first {
                                FeedCardView(
                                    card: first,
                                    width: cardWidth,
                                    height: cardHeight,
                                    onSwipe: { isRightSwipe in
                                        if isRightSwipe {
                                            triggerDeal()
                                            viewModel.match(first)   // right = like/match (persists)
                                        } else {
                                            viewModel.dismiss(first)  // left = dismiss (local only)
                                        }
                                    }
                                )
                                .zIndex(10)
                            }
                        }
                        .frame(height: cardHeight + height * 0.025)

                        Spacer(minLength: height * 0.015)

                        Spacer(minLength: height * 0.018)

                        HStack {
                            PhysicalXButton(size: iconSize) {
                                if let card = viewModel.feedCards.first {
                                    viewModel.dismiss(card) // left = dismiss (local only)
                                }
                            }
                            
                            Spacer()

//                            PhysicalShuffle(size: iconSize * 0.9) {
//                                viewModel.shuffle()
//                            }
                            
                            Spacer()

                            PhysicalHeartButton(size: iconSize) {
                                if let card = viewModel.feedCards.first {
                                    triggerDeal()
                                    viewModel.match(card) // right = like/match (persists)
                                }
                            }
                        }
                        .padding(.horizontal, horizontal)
                        .padding(.bottom, height * 0.02)
                    }
                }
                
                // Overlay rendering
                if showDealStamp {
                    DealStampOverlay()
                        .zIndex(100)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 2.5).combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            )
                        )
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.reloadFeed()
        }
        // (Pull-to-refresh removed: .refreshable needs a scrollable container, and the
        //  feed is a fixed card stack, so the gesture never fired. Foreground refresh below.)
        // Auto-refresh when returning to the app, so connections' new cards show up
        // without needing to quit and relaunch.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await viewModel.reloadFeed() }
            }
        }
        .onChange(of: viewModel.user.connections) { _, _ in
            Task { await viewModel.reloadFeed() }
        }
        .onChange(of: viewModel.currentOwnerID) { _, _ in
            Task { await viewModel.reloadFeed() }
        }
    }
    
    // Animates the stamp appearing and disappearing
    private func triggerDeal() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            showDealStamp = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.25)) {
                showDealStamp = false
            }
        }
    }
}

// MARK: - Deal Stamp Overlay Component
struct DealStampOverlay: View {
    var body: some View {
        ZStack {
            // Darkens the background slightly behind the stamp
            Color.black.opacity(0.15)
                .ignoresSafeArea()
            
            ZStack {
                // Main dark pill
                Capsule()
                    .fill(Color(hex: "080808"))
                    .shadow(color: Color(hex: "5BBF61").opacity(0.5), radius: 35, x: 0, y: 15)
                    .shadow(color: .white.opacity(0.2), radius: 2)
                
                // Border gradient (matching physical buttons)
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .clear, .black.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                
                // Neon Text
                Text("DEAL!")
                    .font(.custom("Nohemi-Medium", fixedSize: 55))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "C9EC5C"), Color(hex: "5BBF61")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: "5BBF61").opacity(0.6), radius: 12)
            }
            .frame(width: 280, height: 110)
            .rotationEffect(.degrees(-12)) // Tilted for that stamped look
        }
    }
}

struct PhysicalXButton: View {
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: "080808"))
                    .shadow(color: .gray.opacity(0.4), radius: size * 0.1, x: 0, y: size * 0.05)
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
                
                Image(systemName: "xmark")
                    .font(.system(size: size * 0.45, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "D742B2"), Color(hex: "EE5C5C")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(hex: "D742B2").opacity(0.6), radius: 8, x: 0, y: 0)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: size * 0.45, weight: .black, design: .rounded))
                            .foregroundStyle(.clear)
                            .overlay(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .mask(
                                    Image(systemName: "xmark")
                                        .font(.system(size: size * 0.45, weight: .black, design: .rounded))
                                )
                            )
                    )
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(PhysicalButtonStyle())
    }
}

struct PhysicalHeartButton: View {
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

                Image(systemName: "heart.fill")
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
                        Image(systemName: "heart")
                            .font(.system(size: size * 0.42, weight: .medium))
                            .foregroundStyle(Color(hex: "6CD475"))
                    )
                    .overlay(
                        Image(systemName: "heart.fill")
                            .font(.system(size: size * 0.42))
                            .foregroundStyle(.clear)
                            .overlay(
                                LinearGradient(
                                    colors: [.white.opacity(0.6), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .mask(
                                    Image(systemName: "heart.fill")
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

struct PhysicalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct ProfileIcon: View {
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

                Image(systemName: "person.fill")
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
        .buttonStyle(PhysicalButtonStyle())
    }
}

struct MatchesIcon: View {
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

                Image(systemName: "rectangle.on.rectangle")
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
        .buttonStyle(PhysicalButtonStyle())
    }
}

struct PhysicalShuffle: View {
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

                Image(systemName: "shuffle")
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow.opacity(0.6), .yellow],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .yellow.opacity(0.4), radius: 8, x: 0, y: 0)
                    .overlay(
                        Image(systemName: "shuffle")
                            .font(.system(size: size * 0.42, weight: .medium))
                            .foregroundStyle(.white)
                    )
                    .overlay(
                        Image(systemName: "shuffle")
                            .font(.system(size: size * 0.42))
                            .foregroundStyle(.clear)
                            .overlay(
                                LinearGradient(
                                    colors: [.yellow.opacity(0.6), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .mask(
                                    Image(systemName: "shuffle")
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
struct LoadingFeedView: View {
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    
    @State private var shimmerX: CGFloat = -1.2
    @State private var idleOffsetY: CGFloat = 0
    @State private var idleScale: CGFloat = 1

    var body: some View {
        ZStack {
            // Backing tilted placeholders (matches the deck stack style)
            RoundedRectangle(cornerRadius: cardWidth * 0.075, style: .continuous)
                .fill(Color(hex: "D8D8D8"))
                .frame(width: cardWidth, height: cardHeight * 0.96)
                .rotationEffect(.degrees(-4.3))
                .offset(x: -cardWidth * 0.035, y: cardHeight * 0.02)

            RoundedRectangle(cornerRadius: cardWidth * 0.075, style: .continuous)
                .fill(Color(hex: "989898"))
                .frame(width: cardWidth, height: cardHeight * 0.96)
                .rotationEffect(.degrees(4.4))
                .offset(x: cardWidth * 0.035, y: -cardHeight * 0.006)

            // Floating skeleton card with shimmer
            SkeletonCardView(cardWidth: cardWidth, cardHeight: cardHeight)
                .offset(y: idleOffsetY)
                .scaleEffect(idleScale)
                .overlay(
                    LinearGradient(
                        colors: [Color.white.opacity(0.0), Color.white.opacity(0.42), Color.white.opacity(0.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: cardWidth * 0.8, height: cardHeight)
                    .offset(x: shimmerX * cardWidth)
                    .rotationEffect(.degrees(12))
                )
                .mask(
                    RoundedRectangle(cornerRadius: cardWidth * 0.08, style: .continuous)
                        .frame(width: cardWidth, height: cardHeight)
                )
        }
        .frame(height: cardHeight + cardHeight * 0.025)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                idleOffsetY = -cardHeight * 0.02
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                idleScale = 1.012
            }
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                shimmerX = 1.2
            }
        }
    }
}

private struct SkeletonCardView: View {
    let cardWidth: CGFloat
    let cardHeight: CGFloat

    var body: some View {
        let radius = cardWidth * 0.08
        // Using orange for the card's stylized borders and glow effects
        let borderColor = Color.orange

        return ZStack {
            // Glow behind card
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(borderColor)
                .frame(width: cardWidth * 0.96, height: cardHeight * 0.9)
                .blur(radius: cardWidth * 0.1)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

            // Main card surface
            RoundedRectangle(cornerRadius: radius, style: .continuous)
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
                .shadow(color: borderColor.opacity(0.35), radius: cardWidth * 0.1, x: 0, y: cardWidth * 0.02)
                .shadow(color: .black.opacity(0.24), radius: cardWidth * 0.025, x: 0, y: cardWidth * 0.012)

            // Texture/Pattern Background
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(
                    ImagePaint(
                        image: Image("ELIZBARSVG"),
                        sourceRect: CGRect(x: 0, y: 0, width: 1, height: 1),
                        scale: 0.3
                    )
                )
                .opacity(0.12)
                .blendMode(.multiply)
                .allowsHitTesting(false)

            // Premium Border rings
            ZStack {
                RoundedRectangle(cornerRadius: cardWidth * 0.07, style: .continuous)
                    .stroke(borderColor.opacity(0.95), lineWidth: cardWidth * 0.030)
                    .padding(cardWidth * 0.035)

                RoundedRectangle(cornerRadius: cardWidth * 0.07, style: .continuous)
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
                        lineWidth: cardWidth * 0.011
                    )
                    .padding(cardWidth * 0.041)

                RoundedRectangle(cornerRadius: cardWidth * 0.07, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    .padding(cardWidth * 0.049)

                RoundedRectangle(cornerRadius: cardWidth * 0.07, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    .blur(radius: 0.7)
                    .padding(cardWidth * 0.031)
            }

            // Central Loading Animation
            ProgressView()
                .tint(borderColor)
                .scaleEffect(cardWidth * 0.005) // Scale loading indicator dynamically with card width
        }
        .frame(width: cardWidth, height: cardHeight)
        .compositingGroup()
    }
}

