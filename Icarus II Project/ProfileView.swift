//
//  ProfileView.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 21/05/26.
//

import SwiftUI

struct ProfileView: View {
    @State private var cards: [Card] = [
        Card(
            ownerID: UUID().uuidString,
            title: "Design a table",
            tags: ["Food", "Tommorow"],
            allDay: true,
            startDate: .now,
            endDate: .now,
            location: ""
        ),
        Card(
            ownerID: UUID().uuidString,
            title: "Coffee with Elizbar and Carlo",
            tags: ["Drinks", "Friday"],
            allDay: false,
            startDate: .now,
            endDate: .now,
            location: "Cafe Centrale"
        ),
        Card(
            ownerID: UUID().uuidString,
            title: "Smoke with Luigi",
            tags: ["Self", "Weekend"],
            allDay: true,
            startDate: .now,
            endDate: .now,
            location: ""
        )
    ]

    @State private var currentCardID: String?
    @State private var editingSheet: SheetMode?

    private enum SheetMode: Identifiable {
        case add
        case edit(Card)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let card): return card.id
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                userRow

                Divider()

                deckHeader

                deck
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .onAppear {
            if currentCardID == nil { currentCardID = cards.first?.id }
        }
        .floatingPanel(item: $editingSheet) { mode in
            floatingEditor(for: mode)
        }
    }

    @ViewBuilder
    private func floatingEditor(for mode: SheetMode) -> some View {
        switch mode {
        case .add:
            AddEditCardView(
                card: nil,
                onSave: { newCard in
                    cards.append(newCard)
                    currentCardID = newCard.id
                    editingSheet = nil
                },
                onCancel: { editingSheet = nil }
            )
        case .edit(let card):
            AddEditCardView(
                card: card,
                onSave: { updated in
                    if let idx = cards.firstIndex(where: { $0.id == updated.id }) {
                        cards[idx] = updated
                    }
                    editingSheet = nil
                },
                onCancel: { editingSheet = nil }
            )
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Profile")
                .font(.system(size: 34, weight: .bold))
            Spacer()
            circleIconButton(systemName: "square.and.arrow.up") { }
            circleIconButton(systemName: "doc.text") { }
        }
    }

    private var userRow: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(white: 0.85))
                .frame(width: 84, height: 84)

            VStack(alignment: .leading, spacing: 8) {
                Text("Marco Rocco")
                    .font(.system(size: 24, weight: .bold))

                Text("Connections")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(white: 0.88), in: Capsule())
            }

            Spacer()
        }
    }

    private var deckHeader: some View {
        HStack {
            Text("Your deck")
                .font(.system(size: 22, weight: .bold))
            Spacer()
            circleIconButton(systemName: "plus") { editingSheet = .add }
            circleIconButton(systemName: "pencil") {
                if let id = currentCardID, let card = cards.first(where: { $0.id == id }) {
                    editingSheet = .edit(card)
                }
            }
            .disabled(cards.isEmpty)
            .opacity(cards.isEmpty ? 0.4 : 1)
        }
    }

    private var deck: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(cards) { card in
                    CardView(card: card) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            cards.removeAll { $0.id == card.id }
                        }
                    }
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $currentCardID)
        .scrollClipDisabled()
    }

    private func circleIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.black)
                .frame(width: 40, height: 40)
                .background(Color(white: 0.92), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfileView()
}
