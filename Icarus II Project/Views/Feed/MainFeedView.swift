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
                // OLA: On first app load, fetch cards from your cloud and populate viewModel.cards.
                // You can call viewModel.fetchCards() from AppRootView .task, or here on appear.
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

                        Spacer()

                        Button {
                            openMatches()
                        } label: {
                            Image(systemName: "point.3.connected.trianglepath.dotted")
                                .font(.system(size: (width * 0.122) * 0.38, weight: .regular))
                                .foregroundStyle(.black)
                                .frame(width: width * 0.122, height: width * 0.122)
                                .background(.white.opacity(0.96), in: Circle())
                                .glassEffect(.regular, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, horizontal)

                    Spacer(minLength: height * 0.055)

                    if viewModel.feedCards.isEmpty {
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
                                    onSwipe: { viewModel.match(first) } // OLA: persist swipe/decision if needed (e.g., dismissed/liked)
                                )
                                .zIndex(10)
                            }
                        }
                        .frame(height: cardHeight + height * 0.025)

                        Spacer(minLength: height * 0.015)

//                        PhysicalShuffle(size: iconSize) {
//                            viewModel.shuffle()
//                        }

                        Spacer(minLength: height * 0.018)

                        HStack {
                            PhysicalXButton(size: iconSize) {
                                if let card = viewModel.feedCards.first {
                                    viewModel.dismiss(card) // OLA: treat as a dismiss; optionally persist to backend.
                                }
                            }
                            Spacer()

                            PhysicalShuffle(size: iconSize * 0.9) {
                                viewModel.shuffle() // OLA: purely local shuffle; no backend work needed.
                            }
                            
                            Spacer()

                            PhysicalHeartButton(size: iconSize) {
                                if let card = viewModel.feedCards.first {
                                    viewModel.match(card) // OLA: treat as an approve/like; optionally persist to backend.
                                }
                            }
                        }
                        .padding(.horizontal, horizontal)
                        .padding(.bottom, height * 0.02)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.reloadFeed()
        }
        .refreshable {
            await viewModel.reloadFeed()
        }
        .onChange(of: viewModel.user.connections) { _ in
            Task { await viewModel.reloadFeed() }
        }
        .onChange(of: viewModel.currentOwnerID) { _ in
            Task { await viewModel.reloadFeed() }
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
//                    .overlay(
//                        Image(systemName: "person")
//                            .font(.system(size: size * 0.42, weight: .medium))
//                            .foregroundStyle(.black)
//                    )
//                    .overlay(
//                        Image(systemName: "person.fill")
//                            .font(.system(size: size * 0.42))
//                            .foregroundStyle(.clear)
//                            .overlay(
//                                LinearGradient(
//                                    colors: [.black.opacity(0.8), .clear],
//                                    startPoint: .top,
//                                    endPoint: .bottom
//                                )
//                                .mask(
//                                    Image(systemName: "person.fill")
//                                        .font(.system(size: size * 0.42))
//                                )
//                            )
//                    )
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

