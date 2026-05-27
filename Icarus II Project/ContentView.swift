//
//  ContentView.swift
//  Icarus II Project
//
//  Created by Elizbar Kheladze on 18/05/26.
//

import SwiftUI

struct ContentView: View {
    @State private var connectionVM = FirebaseTestViewModel()
    @State private var cardVM = CardViewModel()
    @State private var userVM = UserViewModel()
    @State private var matchVM = MatchViewModel()

    @State private var cardStatus = "Idle"
    @State private var userStatus = "Idle"
    @State private var matchStatus = "Idle"

    private let testUserID = "test-user-1"
    private let otherUserID = "test-user-2"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Firebase test bench")
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                connectionSection
                cardSection
                userSection
                matchSection
            }
            .padding()
        }
    }

    // MARK: - Connection round-trip

    private var connectionSection: some View {
        section(title: "Connection round-trip", status: connectionStatusText) {
            Task { await connectionVM.runWriteThenRead() }
        }
    }

    private var connectionStatusText: String {
        switch connectionVM.status {
        case .idle:               return "Idle"
        case .running:            return "Running…"
        case .success(let m):     return "OK — \(m)"
        case .failure(let m):     return "Error — \(m)"
        }
    }

    // MARK: - Card CRUD

    private var cardSection: some View {
        section(title: "Cards (add + reload list)", status: cardStatus) {
            Task { await runCardTest() }
        }
    }

    private func runCardTest() async {
        cardStatus = "Running…"
        var card = Card.draft(ownerID: testUserID)
        card.title = "Test card \(Int.random(in: 1000...9999))"
        card.tags = ["test"]

        await cardVM.add(card)
        if let err = cardVM.errorMessage {
            cardStatus = "Error on add — \(err)"
            return
        }

        await cardVM.load(ownerID: testUserID)
        if let err = cardVM.errorMessage {
            cardStatus = "Error on load — \(err)"
        } else {
            cardStatus = "OK — \(cardVM.cards.count) card(s) for \(testUserID)"
        }
    }

    // MARK: - User profile

    private var userSection: some View {
        section(title: "User (create + load)", status: userStatus) {
            Task { await runUserTest() }
        }
    }

    private func runUserTest() async {
        userStatus = "Running…"
        let user = User(id: testUserID, displayName: "Test User")
        await userVM.create(user)
        if let err = userVM.errorMessage {
            userStatus = "Error on create — \(err)"
            return
        }

        await userVM.load(id: testUserID)
        if let err = userVM.errorMessage {
            userStatus = "Error on load — \(err)"
        } else if let u = userVM.user {
            userStatus = "OK — loaded \(u.displayName)"
        } else {
            userStatus = "No user returned"
        }
    }

    // MARK: - Match request

    private var matchSection: some View {
        section(title: "Match (other user matches on owner's card)", status: matchStatus) {
            Task { await runMatchTest() }
        }
    }

    private func runMatchTest() async {
        matchStatus = "Running…"

        // Need an existing card to match against — use the last one created by the Card test.
        guard let card = cardVM.cards.last else {
            matchStatus = "Run the Card test first — need a card to match on."
            return
        }

        // otherUserID expresses interest in testUserID's card.
        await matchVM.sendRequest(forCard: card.id, ownerID: card.ownerID, matcherID: otherUserID)
        if let err = matchVM.errorMessage {
            matchStatus = "Error on send — \(err)"
            return
        }

        // Reload all incoming matches for the card's owner.
        await matchVM.loadIncoming(ownerID: card.ownerID)
        if let err = matchVM.errorMessage {
            matchStatus = "Error on load — \(err)"
        } else {
            matchStatus = "OK — \(matchVM.matches.count) incoming match(es) on \(card.ownerID)'s cards"
        }
    }

    // MARK: - Section chrome

    @ViewBuilder
    private func section(title: String, status: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            Button("Run", action: action)
                .buttonStyle(.borderedProminent)
            Text(status)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.94), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
}
