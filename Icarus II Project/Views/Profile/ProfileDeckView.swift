//
//  ProfileDeckView.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI

struct ProfileDeckView: View {
    @Bindable var viewModel: DeckViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isDeckEditing: Bool = false
    
    @Environment(UserViewModel.self) var userViewModel

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let side = width * 0.095
            let icon = width * 0.13
            let avatar = width * 0.24
            let cardWidth = width * 0.72
            let cardHeight = height * 0.61
            let confettiHeight = height * 0.385

            ZStack {
                DottedBackground()

                VStack(spacing: 0) {
                    FloatingConfetti(width: width, height: confettiHeight)
                        .frame(height: confettiHeight)
                        .allowsHitTesting(false)
                        .ignoresSafeArea()

                    Spacer()
                }
                .opacity(isDeckEditing ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: isDeckEditing)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: width * 0.075, weight: .semibold))
                                .foregroundStyle(.black)
                                .frame(width: icon, height: icon)
                                .background(.white.opacity(0.96), in: Circle())
                                .glassEffect(.regular, in: Circle())
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        if isDeckEditing {
                            Button("Done") {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                                    isDeckEditing = false
                                }
                            }
                            .font(.system(size: width * 0.055, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, width * 0.04)
                            .frame(height: icon)
                            .background(.white.opacity(0.96), in: Capsule())
                            .glassEffect(.regular, in: Capsule())
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, height * 0.022)

                    if !isDeckEditing {
                        VStack(spacing: height * 0.018) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.user.avatarColor)
                                    .frame(width: avatar * 1.45, height: avatar * 1.45)
                                    .shadow(color: .black.opacity(0.08), radius: width * 0.04, x: 0, y: width * 0.02)
                                    .glassEffect(.regular, in: Circle())

                                Image("BIBI")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: avatar * 1.32, height: avatar * 1.32)
                                    .clipShape(Circle())
                            }

                            Text(viewModel.user.name)
                                .font(.custom("Nohemi-Medium", fixedSize: width * 0.085))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)

                            HStack(spacing: width * 0.04) {
                                Button {
                                } label: {
                                    Text("Connections")
                                        .font(.system(size: width * 0.045, weight: .semibold))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, width * 0.06)
                                        .frame(height: height * 0.052)
                                        .background(
                                            Capsule(style: .continuous)
                                                .fill(Color(hex: "D3D3D3"))
                                        )
                                }
                                .buttonStyle(.plain)
                                // TODO(EL): This button should be changed to use ShareLink, calling userViewModel.user?.connectionLink and unwrap it.
                                CircleIconButton(systemName: "square.and.arrow.up", size: icon)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, height * 0.01)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if !isDeckEditing {
                        Rectangle()
                            .fill(Color.white.opacity(1))
                            .frame(height: 1)
                            .padding(.top, height * 0.019)
                            .transition(.opacity)
                    }

                    if !isDeckEditing {
                        HStack(alignment: .center) {
                            Text("Your deck")
                                .font(.system(size: width * 0.074, weight: .semibold))
                                .foregroundStyle(.black)

                            Spacer()

                            HStack(spacing: width * 0.04) {
                                Button {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                        isDeckEditing = true
                                    }
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.system(size: width * 0.058, weight: .regular))
                                        .foregroundStyle(Color(hex: "151515"))
                                        .frame(width: icon, height: icon)
                                        .background(.white.opacity(0.94), in: Circle())
                                        .glassEffect(.regular, in: Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, height * 0.012)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    ZStack(alignment: .bottom) {
                        Group {
                            if isDeckEditing {
                                VStack {
                                    Spacer(minLength: 0)
                                    DeckCarousel(
                                        cards: viewModel.profileCards,
                                        cardWidth: cardWidth,
                                        cardHeight: cardHeight,
                                        sideInset: 0,
                                        onEdit: { viewModel.editCard($0) }, // OLA: open editor for this card; persist edits in save(card:)
                                        onDelete: { viewModel.delete($0) } // OLA: delete locally and in backend
                                    )
                                    .padding(.horizontal, -side)
                                    .padding(.top, height * 0.07)
                                    Spacer(minLength: 0)
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            } else {
                                DeckCarousel(
                                    cards: viewModel.profileCards,
                                    cardWidth: cardWidth,
                                    cardHeight: cardHeight,
                                    sideInset: side,
                                    onEdit: { viewModel.editCard($0) }, // OLA: open editor for this card; persist edits in save(card:)
                                    onDelete: { viewModel.delete($0) } // OLA: delete locally and in backend
                                )
                                .ignoresSafeArea(edges: .horizontal)
                                .padding(.horizontal, -side)
                            }
                        }

                        if isDeckEditing {
                            HStack {
                                Spacer()
                                Button {
                                    viewModel.addCard() // OLA: open editor in create mode; persist new card in save(card:)
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "080808"))
                                            .shadow(color: .black.opacity(0.4), radius: icon * 0.1, x: 0, y: icon * 0.05)
                                            .shadow(color: .white, radius: icon * 0.1)

                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.15), .clear, .black.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )

                                        Image(systemName: "plus")
                                            .font(.system(size: icon * 0.45, weight: .black, design: .rounded))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [Color(hex: "C9EC5C"), Color(hex: "5BBF61")],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .shadow(color: Color(hex: "5BBF61").opacity(0.4), radius: 8, x: 0, y: 0)
                                            .overlay(
                                                Image(systemName: "plus")
                                                    .font(.system(size: icon * 0.45, weight: .black, design: .rounded))
                                                    .foregroundStyle(.clear)
                                                    .overlay(
                                                        LinearGradient(
                                                            colors: [.white.opacity(0.6), .clear],
                                                            startPoint: .top,
                                                            endPoint: .bottom
                                                        )
                                                        .mask(
                                                            Image(systemName: "plus")
                                                                .font(.system(size: icon * 0.45, weight: .black, design: .rounded))
                                                        )
                                                    )
                                            )
                                    }
                                    .frame(width: icon * 1.25, height: icon * 1.25)
                                }
                                .buttonStyle(PhysicalButtonStyle())
                                Spacer()
                            }
                            .padding(.bottom, height * 0.06)
                            .ignoresSafeArea(edges: .horizontal)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, -side)
                    .ignoresSafeArea(edges: .horizontal)
                    .contentShape(Rectangle())
                    .animation(.spring(response: 0.5, dampingFraction: 0.9), value: isDeckEditing)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, side)
            }
            .sheet(isPresented: $viewModel.isEditorPresented) {
                CardEditorSheet(
                    card: viewModel.selectedCard,
                    onCancel: {
                        viewModel.isEditorPresented = false
                        viewModel.selectedCard = nil
                    },
                    onSave: { card in
                        viewModel.save(card: card) // OLA: upsert to backend (create/update) then refresh local state if needed.
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(width * 0.1)
                .presentationBackground(.clear)
            }
        }
    }
}

struct FloatingConfetti: View {
    let width: CGFloat
    let height: CGFloat

    private let pieces: [ConfettiPiece] = [
        .init(x: 0.07, y: 0.18, rotation: -18, color: Color(hex: "FF4D6D"), delay: 0.0),
        .init(x: 0.17, y: 0.12, rotation: 12, color: Color(hex: "FFD166"), delay: 0.4),
        .init(x: 0.28, y: 0.20, rotation: 34, color: Color(hex: "06D6A0"), delay: 0.8),
        .init(x: 0.41, y: 0.13, rotation: -29, color: Color(hex: "118AB2"), delay: 0.2),
        .init(x: 0.56, y: 0.18, rotation: 47, color: Color(hex: "9B5DE5"), delay: 0.6),
        .init(x: 0.72, y: 0.11, rotation: -41, color: Color(hex: "F15BB5"), delay: 1.0),
        .init(x: 0.89, y: 0.19, rotation: 22, color: Color(hex: "00BBF9"), delay: 0.9),

        .init(x: 0.11, y: 0.33, rotation: 39, color: Color(hex: "FEE440"), delay: 0.3),
        .init(x: 0.23, y: 0.28, rotation: -12, color: Color(hex: "EF476F"), delay: 0.7),
        .init(x: 0.35, y: 0.36, rotation: 64, color: Color(hex: "43AA8B"), delay: 0.1),
        .init(x: 0.49, y: 0.30, rotation: -52, color: Color(hex: "FF9F1C"), delay: 0.5),
        .init(x: 0.63, y: 0.37, rotation: 18, color: Color(hex: "3A86FF"), delay: 1.1),
        .init(x: 0.76, y: 0.29, rotation: -33, color: Color(hex: "8338EC"), delay: 0.2),
        .init(x: 0.91, y: 0.35, rotation: 55, color: Color(hex: "FB5607"), delay: 0.6),

        .init(x: 0.06, y: 0.52, rotation: -48, color: Color(hex: "2EC4B6"), delay: 1.0),
        .init(x: 0.16, y: 0.47, rotation: 26, color: Color(hex: "FFBE0B"), delay: 0.4),
        .init(x: 0.27, y: 0.56, rotation: -7, color: Color(hex: "FF006E"), delay: 0.8),
        .init(x: 0.39, y: 0.50, rotation: 73, color: Color(hex: "8AC926"), delay: 0.3),
        .init(x: 0.51, y: 0.58, rotation: -66, color: Color(hex: "1982C4"), delay: 0.7),
        .init(x: 0.64, y: 0.49, rotation: 9, color: Color(hex: "FF595E"), delay: 0.1),
        .init(x: 0.76, y: 0.56, rotation: -24, color: Color(hex: "6A4C93"), delay: 0.9),
        .init(x: 0.90, y: 0.50, rotation: 42, color: Color(hex: "4ECDC4"), delay: 0.5),

        .init(x: 0.10, y: 0.70, rotation: 17, color: Color(hex: "FFCA3A"), delay: 0.15),
        .init(x: 0.22, y: 0.76, rotation: -38, color: Color(hex: "7209B7"), delay: 0.55),
        .init(x: 0.34, y: 0.68, rotation: 52, color: Color(hex: "00F5D4"), delay: 0.95),
        .init(x: 0.47, y: 0.74, rotation: -16, color: Color(hex: "F72585"), delay: 0.35),
        .init(x: 0.59, y: 0.69, rotation: 31, color: Color(hex: "B5E48C"), delay: 0.75),
        .init(x: 0.71, y: 0.77, rotation: -58, color: Color(hex: "4361EE"), delay: 0.25),
        .init(x: 0.84, y: 0.71, rotation: 68, color: Color(hex: "FF7B00"), delay: 0.65),

        .init(x: 0.15, y: 0.88, rotation: -27, color: Color(hex: "90BE6D"), delay: 0.85),
        .init(x: 0.30, y: 0.92, rotation: 44, color: Color(hex: "577590"), delay: 0.45),
        .init(x: 0.44, y: 0.86, rotation: -63, color: Color(hex: "F94144"), delay: 0.05),
        .init(x: 0.58, y: 0.91, rotation: 21, color: Color(hex: "F9C74F"), delay: 0.95),
        .init(x: 0.72, y: 0.87, rotation: -11, color: Color(hex: "277DA1"), delay: 0.35),
        .init(x: 0.87, y: 0.93, rotation: 59, color: Color(hex: "C77DFF"), delay: 0.7)
    ]

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let size = width * 0.022

            ZStack {
                ForEach(pieces) { piece in
                    let movement = sin(time * 1.35 + piece.delay * 4.2)
                    let sideMovement = cos(time * 1.05 + piece.delay * 3.4)

                    Rectangle()
                        .fill(piece.color.opacity(0.88))
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(piece.rotation + movement * 7))
                        .position(
                            x: width * piece.x + sideMovement * width * 0.007,
                            y: height * piece.y + movement * height * 0.013
                        )
                }
            }
            .clipped()
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let color: Color
    let delay: Double
}

