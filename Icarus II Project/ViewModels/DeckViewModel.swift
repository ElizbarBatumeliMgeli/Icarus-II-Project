//
//  DeckViewModel.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI

@MainActor
@Observable
final class DeckViewModel {
    // OLA NOTE:
    // This ViewModel drives the UI and proxies CRUD through `DeckCardRepository`.
    // Persistence target: Firestore `cards` collection (one doc per DeckCard).

    var user = User(id: "test-user-1", firstName: "Marco", lastName: "Rocco", avatarColorHex: "D3D3D3")
    // OLA: replace with the signed-in user from your auth/profile once it lands
    // Owner id used to scope card queries. Hardcoded until Sign in with Apple is wired up
    // TODO(auth): replace with `Auth.auth().currentUser?.uid` once `AuthService` is in place
    var currentOwnerID: String = "test-user-1"

    private let repository = DeckCardRepository()
    var isLoading: Bool = false
    var errorMessage: String?

    // Mock seed data — visible until the first `fetchCards()` returns from Firestore.
    var cards: [DeckCard] = [
        DeckCard(title: "Design a\ntable", category: "Food", dateText: "Tomorrow", location: "Naples", color: Color(.orange)),
        DeckCard(title: "Museum\nvisit", category: "Art", dateText: "Weekend", location: "Naples", color: Color(hex: "D8D8D8")),
        DeckCard(title: "Coffee\nwalk", category: "Social", dateText: "Today", location: "Centro", color: Color(hex: "5F5E69")),
        DeckCard(title: "Movie\nnight", category: "Fun", dateText: "Friday", location: "Home", color: Color(hex: "D1D1D1"))
    ]

    // UI-friendly mapping used in the profile deck (adjusts color for readability).
    var profileCards: [DeckCard] {
        cards.map {
            DeckCard(
                id: $0.id,
                title: $0.title,
                ownerName: $0.ownerName,
                category: $0.category,
                dateText: $0.dateText,
                location: $0.location,
                color: $0.color == Color(hex: "111111") ? Color(hex: "D8D8D8") : $0.color
            )
        }
    }

    // UI editor state (used by the sheet).
    var selectedCard: DeckCard?
    var isEditorPresented = false

    // MARK: - Data loading

    // Fetches the current user's cards from Firestore and replaces `cards`
    // Fire-and-forget from the UI; updates `isLoading`/`errorMessage` as it runs
    func fetchCards() {
        Task { await loadFromRepository() }
    }

    private func loadFromRepository() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            cards = try await repository.fetch(ownerID: currentOwnerID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Editor entry points

    // Opens the editor in "create" mode.
    func addCard() {
        selectedCard = nil
        isEditorPresented = true
    }

    // Opens the editor in "edit" mode for an existing card (or first card as fallback).
    func editCard(_ card: DeckCard? = nil) {
        selectedCard = card ?? cards.first
        isEditorPresented = true
    }

    // MARK: - Mutations

    // Upserts a card locally for instant UI feedback, then persists to Firestore in the background.
    func save(card: DeckCard) {
        var toSave = card
        if toSave.ownerID.isEmpty { toSave.ownerID = currentOwnerID }

        if let index = cards.firstIndex(where: { $0.id == toSave.id }) {
            cards[index] = toSave
        } else {
            cards.insert(toSave, at: 0)
        }

        selectedCard = nil
        isEditorPresented = false

        Task {
            do {
                try await repository.upsert(toSave)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // Removes a card locally for instant UI feedback, then deletes from Firestore in the background
    func delete(_ card: DeckCard) {
        cards.removeAll { $0.id == card.id }
        Task {
            do {
                try await repository.delete(id: card.id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // Handles a swipe action (dismisses current card from the feed).
    // TODO(matches): once the matches flow is wired, route the verdict through `MatchRepository`.
    func swipe(_ card: DeckCard) {
        if let index = cards.firstIndex(of: card) {
            cards.remove(at: index)
        }
    }

    // Randomizes the order of cards shown in the feed.
    // Local UX
    func shuffle() {
        cards.shuffle()
    }
}
