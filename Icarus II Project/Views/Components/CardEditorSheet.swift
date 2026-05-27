//
//  CardEditorSheet.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI

struct CardEditorSheet: View {
    let card: DeckCard?
    let onCancel: () -> Void
    let onSave: (DeckCard) -> Void // OLA: Persist the changes via ViewModel.save(card:) -> backend upsert

    @State private var title: String
    @State private var selectedTag: String
    @State private var allDay: Bool
    @State private var starts: Date
    @State private var ends: Date
    @State private var location: String

    private let tags = ["Food", "Social", "Art", "Fun"]

    init(card: DeckCard?, onCancel: @escaping () -> Void, onSave: @escaping (DeckCard) -> Void) {
        self.card = card
        self.onCancel = onCancel
        self.onSave = onSave
        _title = State(initialValue: card?.title.replacingOccurrences(of: "\n", with: " ") ?? "Design a table")
        _selectedTag = State(initialValue: card?.category ?? "Food")
        _allDay = State(initialValue: true)
        _starts = State(initialValue: .now)
        _ends = State(initialValue: .now.addingTimeInterval(7200))
        _location = State(initialValue: card?.location ?? "Location")
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let cardWidth = width * 0.84
            let cardHeight = height * 0.62

            ZStack {
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("Your deck")
                                    .font(.system(size: width * 0.062, weight: .semibold))
                                    .foregroundStyle(.black.opacity(0.18))
                                    .blur(radius: width * 0.018)

                                Spacer()

                                Circle()
                                    .fill(.black.opacity(0.11))
                                    .frame(width: width * 0.06, height: width * 0.06)
                                    .blur(radius: width * 0.018)
                            }
                            .padding(.horizontal, width * 0.085)
                            .padding(.top, height * 0.08)

                            Spacer()
                        }

                        editorCard(cardWidth: cardWidth, cardHeight: cardHeight)
                            .padding(.top, height * 0.14)
                    }

                    Spacer()
                }
            }
        }
    }

    private func editorCard(cardWidth: CGFloat, cardHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button {
                    onCancel()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: cardWidth * 0.073, weight: .regular))
                        .foregroundStyle(.black)
                        .frame(width: cardWidth * 0.147, height: cardWidth * 0.147)
                        .background(.white.opacity(0.65), in: Circle())
                        .glassEffect(.regular, in: Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                RoundedRectangle(cornerRadius: cardWidth * 0.003, style: .continuous)
                    .fill(.black)
                    .frame(width: cardWidth * 0.18, height: cardHeight * 0.012)
                    .mask {
                        HStack(spacing: cardWidth * 0.008) {
                            ForEach(0..<9) { _ in
                                RoundedRectangle(cornerRadius: cardWidth * 0.003, style: .continuous)
                                    .frame(width: cardWidth * 0.013)
                            }
                        }
                    }
                    .padding(.top, -cardHeight * 0.025)

                Spacer()

                Button {
                    let savedCard = DeckCard(
                        id: card?.id ?? UUID(),
                        title: normalizedTitle,
                        category: selectedTag,
                        dateText: allDay ? "Tomorrow" : "Today",
                        location: location.isEmpty ? "Location" : location,
                        color: card?.color ?? Color(hex: "D8D8D8")
                    )

                    // OLA: This triggers ViewModel.save(card:), where you upsert to your backend.
                    onSave(savedCard)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: cardWidth * 0.073, weight: .regular))
                        .foregroundStyle(.black)
                        .frame(width: cardWidth * 0.147, height: cardWidth * 0.147)
                        .background(.white.opacity(0.65), in: Circle())
                        .glassEffect(.regular, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, cardWidth * 0.056)
            .padding(.top, cardHeight * 0.018)

            VStack(alignment: .leading, spacing: cardHeight * 0.02) {
                Text("What?")
                    .font(.system(size: cardWidth * 0.046, weight: .semibold))
                    .foregroundStyle(.black)

                TextField("", text: $title, axis: .vertical)
                    .font(.system(size: cardWidth * 0.099, weight: .semibold))
                    .foregroundStyle(.black)
                    .lineLimit(2...3)
                    .padding(.horizontal, cardWidth * 0.03)
                    .padding(.vertical, cardHeight * 0.012)
                    .frame(height: cardHeight * 0.2, alignment: .topLeading)
                    .background(
                        RoundedRectangle(cornerRadius: cardWidth * 0.053, style: .continuous)
                            .fill(Color(hex: "D2D2D2"))
                    )
            }
            .padding(.top, cardHeight * 0.05)
            .padding(.horizontal, cardWidth * 0.104)

            VStack(alignment: .leading, spacing: cardHeight * 0.018) {
                Text("Tags")
                    .font(.system(size: cardWidth * 0.046, weight: .semibold))
                    .foregroundStyle(.black)

                HStack(spacing: cardWidth * 0.025) {
                    ForEach(tags, id: \.self) { tag in
                        Button {
                            selectedTag = tag
                        } label: {
                            Text(selectedTag == tag ? tag : "")
                                .font(.system(size: cardWidth * 0.036, weight: .semibold))
                                .foregroundStyle(.black)
                                .frame(width: cardWidth * 0.17, height: cardHeight * 0.064)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(selectedTag == tag ? Color(hex: "B8B8B8") : Color(hex: "D2D2D2"))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, cardWidth * 0.104)
            .padding(.top, cardHeight * 0.018)

            VStack(alignment: .leading, spacing: cardHeight * 0.015) {
                Text("When?")
                    .font(.system(size: cardWidth * 0.046, weight: .semibold))
                    .foregroundStyle(.black)

                VStack(spacing: 0) {
                    HStack {
                        Text("All day")
                            .font(.system(size: cardWidth * 0.046, weight: .regular))
                            .foregroundStyle(.black)

                        Spacer()

                        Toggle("", isOn: $allDay)
                            .labelsHidden()
                            .tint(Color(hex: "AFAFAF"))
                            .scaleEffect(cardWidth / 460)
                    }
                    .frame(height: cardHeight * 0.065)

                    Divider()
                        .background(.black.opacity(0.25))

                    Button {
                        starts = starts.addingTimeInterval(3600)
                    } label: {
                        HStack {
                            Text("Starts")
                                .font(.system(size: cardWidth * 0.046, weight: .regular))
                                .foregroundStyle(.black)

                            Spacer()
                        }
                        .frame(height: cardHeight * 0.043)
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .background(.black.opacity(0.25))

                    Button {
                        ends = ends.addingTimeInterval(3600)
                    } label: {
                        HStack {
                            Text("Ends")
                                .font(.system(size: cardWidth * 0.046, weight: .regular))
                                .foregroundStyle(.black)

                            Spacer()
                        }
                        .frame(height: cardHeight * 0.046)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, cardWidth * 0.04)
                .frame(height: cardHeight * 0.166)
                .background(
                    RoundedRectangle(cornerRadius: cardWidth * 0.053, style: .continuous)
                        .fill(Color(hex: "D0D0D0"))
                )
            }
            .padding(.horizontal, cardWidth * 0.104)
            .padding(.top, cardHeight * 0.024)

            VStack(alignment: .leading, spacing: cardHeight * 0.012) {
                Text("Where?")
                    .font(.system(size: cardWidth * 0.046, weight: .semibold))
                    .foregroundStyle(.black)

                TextField("", text: $location)
                    .font(.system(size: cardWidth * 0.043, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, cardWidth * 0.03)
                    .frame(height: cardHeight * 0.062)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color(hex: "D0D0D0"))
                    )
            }
            .padding(.horizontal, cardWidth * 0.104)
            .padding(.top, cardHeight * 0.045)

            Spacer(minLength: cardHeight * 0.03)
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(
            RoundedRectangle(cornerRadius: cardWidth * 0.061, style: .continuous)
                .fill(Color(hex: "D7D7D7"))
                .shadow(color: .black.opacity(0.16), radius: cardWidth * 0.07, x: 0, y: cardHeight * 0.02)
        )
    }

    private var normalizedTitle: String {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.count > 12 {
            let words = cleaned.split(separator: " ")

            if words.count > 2 {
                return words.prefix(words.count / 2).joined(separator: " ") + "\n" + words.suffix(words.count - words.count / 2).joined(separator: " ")
            }
        }

        return cleaned.isEmpty ? "Design a\ntable" : cleaned
    }
}

