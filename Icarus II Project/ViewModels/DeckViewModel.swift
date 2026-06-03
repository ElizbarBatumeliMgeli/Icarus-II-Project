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
    // This ViewModel drives the UI and proxies CRUD through `DeckCardRepository` (cards)
    // and `MatchRepository` (matches). Persistence target: Firestore.

    var user = User(id: "test-user-1", firstName: "Marco", lastName: "Rocco", avatarColorHex: "D3D3D3")
    // OLA: replace with the signed-in user from your auth/profile once it lands
    // Owner id used to scope card queries. Hardcoded until Sign in with Apple is wired up
    // TODO(auth): replace with `Auth.auth().currentUser?.uid` once `AuthService` is in place
    var currentOwnerID: String = "test-user-1"
    // For development: include my own cards in the feed when there are no connections
    var showOwnCardsInFeedForTesting: Bool = true

    private let repository = DeckCardRepository()
    private let matchRepository = MatchRepository()
    var isLoading: Bool = false
    var errorMessage: String?

    // EL - My own cards (my personal deck). Populated by fetchCards(). The profile screen uses this.
    // Mock seed data — visible until the first fetchCards() returns from Firestore.
    var cards: [DeckCard] = [
        DeckCard(title: "Design a\ntable", category: "Food", dateText: "Tomorrow", location: "Naples", color: Color(.orange)),
        DeckCard(title: "Museum\nvisit", category: "Art", dateText: "Weekend", location: "Naples", color: Color(hex: "D8D8D8")),
        DeckCard(title: "Coffee\nwalk", category: "Social", dateText: "Today", location: "Centro", color: Color(hex: "5F5E69")),
        DeckCard(title: "Movie\nnight", category: "Fun", dateText: "Friday", location: "Home", color: Color(hex: "D1D1D1"))
    ]

    // EL - The swipe feed: cards from people I'm connected to (never my own), populated by loadFeed(); MainFeedView should read this instead of `cards`.
    var feedCards: [DeckCard] = []

    // EL - Cards I've matched with (the ones I swiped right on), populated by loadMatchedCards(); MatchesView should read this.
    var matchedCards: [DeckCard] = []

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
    var isEditorPresented = false // Controls the editor sheet presentation.

    // Inline-draft state for the new card editor flow (from main's UI).
    var draftCard: DeckCard?

    // MARK: - My deck

    // EL - Loads MY OWN cards into `cards` (used by the profile deck). Fire-and-forget from the UI.
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

    // MARK: - Feed (cards from my connections)

    // EL - Loads the swipe feed into `feedCards` (cards from my connections, excluding my own); call this when the feed appears — it relies on `user.connections`, which becomes the real list once auth/profile load is in.
    func loadFeed() {
        Task { await loadFeedFromRepository() }
    }

    // Async variant for views that want to await the refresh (e.g., .task or .refreshable)
    func reloadFeed() async {
        await loadFeedFromRepository()
    }

    private func loadFeedFromRepository() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // If we have connection IDs, load only from them; otherwise, load everything and exclude my own.
            if !user.connections.isEmpty {
                feedCards = try await repository.feed(fromOwnerIDs: user.connections)
            } else {
                // Fallback: global feed minus my own cards
                var all = try await repository.all()
                if !showOwnCardsInFeedForTesting {
                    all.removeAll { $0.ownerID == currentOwnerID }
                }
                feedCards = all
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Editor entry points

    // EL - Creates an inline draft card (main's inline-draft flow) instead of opening the sheet.
    func addCard() {
        draftCard = DeckCard(
            title: "",
            ownerName: user.name,
            category: "Food", // Default fallback
            dateText: "Today", // Default fallback
            location: "",
            color: Color(hex: "D8D8D8")
        )
    }

    /// Saves the inline draft card to the main list and stops drafting
    func saveDraft() {
        guard let draft = draftCard else { return }
        
        // 1. Insert or update the card in the main list
        save(card: draft)
        
        // 2. Setting this to nil stops the drafting UI from rendering
        draftCard = nil
    }

    /// Cancels the inline editing session and stops drafting
    func cancelDraft() {
        draftCard = nil
    }

    // EL - Opens the editor to edit an existing card (falls back to the first card).
    func editCard(_ card: DeckCard? = nil) {
        selectedCard = card ?? cards.first
        isEditorPresented = true
    }

    // MARK: - Card mutations (my own deck)

    // EL - Saves a card (create or update). Updates `cards` immediately for instant UI, then persists.
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
                await loadFeedFromRepository()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // EL - Deletes one of my own cards. Removes it from `cards` immediately, then deletes from Firestore.
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

    // MARK: - Swipe actions (on the feed)

    // EL - RIGHT / like swipe: records a match between me (the matcher) and the card's owner, removes it from `feedCards`, makes it appear in `matchedCards`, and saves in the background (no owner approval — the swipe is the match).
    func match(_ card: DeckCard) {
        feedCards.removeAll { $0.id == card.id }

        let newMatch = Match(
            id: Match.id(cardID: card.id.uuidString, matcherID: currentOwnerID),
            cardID: card.id.uuidString,
            ownerID: card.ownerID,
            matcherID: currentOwnerID,
            status: .accepted,
            createdAt: Date()
        )

        Task {
            do {
                try await matchRepository.create(newMatch)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // EL - LEFT / dismiss swipe. Just removes the card from `feedCards` locally — no match, nothing saved.
    func dismiss(_ card: DeckCard) {
        feedCards.removeAll { $0.id == card.id }
    }

    // EL - Old local-only swipe, kept so existing feed code still compiles; for the real flow use match(_:) on a right swipe and dismiss(_:) on a left swipe instead of this.
    func swipe(_ card: DeckCard) {
        if let index = cards.firstIndex(of: card) {
            cards.remove(at: index)
        }
        
        
    }

    // MARK: - Matched cards (for MatchesView)

    // EL - Loads the cards I've matched with into `matchedCards` (reads my matches, then fetches those cards); call this when MatchesView appears.
    func loadMatchedCards() {
        Task { await loadMatchedCardsFromRepository() }
    }

    private func loadMatchedCardsFromRepository() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let myMatches = try await matchRepository.forMatcher(currentOwnerID)
            let cardIDs = myMatches.map { $0.cardID }
            matchedCards = try await repository.cards(withIDs: cardIDs)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Misc

    // Purely local UX.
    func shuffle() {
        cards.shuffle()
    }
}

