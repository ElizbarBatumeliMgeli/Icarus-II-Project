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

    // Bound to the signed-in user via `bind(to:)` from AppRootView once auth/profile loads.
    // Empty placeholder until then, so nothing real is queried.
    var user = User(id: "")
    // Owner id used to scope card queries — set to the real Firebase UID by `bind(to:)`.
    var currentOwnerID: String = ""

    private let repository = DeckCardRepository()
    private let matchRepository = MatchRepository()
    private let profileRepository = ProfileRepository()
    var isLoading: Bool = false
    var errorMessage: String?

    // Card ids I've already acted on (matched or dismissed), used to filter the feed.
    // Seeded ONCE per login from Firestore, then kept up to date locally on each swipe —
    // so a feed refresh no longer re-downloads the whole swipe history every time.
    private var actedCardIDs: Set<String> = []
    private var actedSetLoaded = false

    // EL - My own cards (my personal deck). Populated by fetchCards() from Firestore.
    var cards: [DeckCard] = []

    // Sample cards for SwiftUI previews / manual testing ONLY — NOT used in the real flow.
    // To try placeholder data, assign `DeckViewModel.mockCards` to `cards` from a #Preview.
    static let mockCards: [DeckCard] = [
        DeckCard(title: "Design a\ntable", category: "Food", dateText: "Tomorrow", location: "Naples", color: Color(.orange)),
        DeckCard(title: "Museum\nvisit", category: "Art", dateText: "Weekend", location: "Naples", color: Color(hex: "D8D8D8")),
        DeckCard(title: "Coffee\nwalk", category: "Social", dateText: "Today", location: "Centro", color: Color(hex: "5F5E69")),
        DeckCard(title: "Movie\nnight", category: "Fun", dateText: "Friday", location: "Home", color: Color(hex: "D1D1D1"))
    ]

    // EL - The swipe feed: cards from people I'm connected to (never my own), populated by loadFeed(); MainFeedView should read this instead of `cards`.
    var feedCards: [DeckCard] = []

    // EL - Cards I've matched with, enriched with owner + other matchers, populated by
    // loadMatchedCards(); MatchesView reads this. Only shows events whose day hasn't passed.
    var matchedCardInfos: [MatchedCardInfo] = []

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

    // MARK: - Session binding

    // Bind this view model to the signed-in user (call from AppRootView once the real
    // profile loads, and whenever it changes). Scopes the deck/feed queries to the real
    // Firebase UID and the user's real connections.
    func bind(to user: User) {
        let userChanged = user.id != currentOwnerID
        self.user = user
        self.currentOwnerID = user.id
        // Only drop the acted-on cache when the actual account changes — not on every
        // re-bind (e.g. a connections update re-binds the same user).
        if userChanged {
            actedCardIDs = []
            actedSetLoaded = false
        }
    }

    // MARK: - My deck

    // EL - Loads MY OWN cards into `cards` (used by the profile deck). Fire-and-forget from the UI.
    func fetchCards() {
        Task { await loadFromRepository() }
    }

    // Async variant for views that want to await the refresh (e.g. .task).
    func reloadCards() async {
        await loadFromRepository()
    }

    // True while the card's event day hasn't passed. Cards without an event date
    // never expire (we can't tell when they end).
    private func isEventLive(_ card: DeckCard) -> Bool {
        guard let event = card.eventDate else { return true }
        return Calendar.current.startOfDay(for: event) >= Calendar.current.startOfDay(for: Date())
    }

    private func loadFromRepository() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Show my cards through the end of each event's day; drop expired ones.
            let mine = try await repository.fetch(ownerID: currentOwnerID)
            cards = mine.filter { isEventLive($0) }
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
            // Strictly connection-scoped: only cards owned by people I'm connected to.
            // No connections → empty feed (EmptyFeedView). My own cards are excluded
            // automatically, since my own id is never in my connections list.
            let connectionCards = try await repository.feed(fromOwnerIDs: user.connections)

            // Seed the acted-on set ONCE from Firestore (matched .accepted + dismissed .blocked).
            // After that it's maintained locally by match()/dismiss(), so refreshes don't
            // re-download the whole swipe history.
            if !actedSetLoaded {
                let actedOn = try await matchRepository.forMatcher(currentOwnerID)
                actedCardIDs = Set(actedOn.map { $0.cardID })
                actedSetLoaded = true
            }

            // Hide cards I've already acted on so they never resurrect on a refresh.
            feedCards = connectionCards.filter { !actedCardIDs.contains($0.id.uuidString) }
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
        actedCardIDs.insert(card.id.uuidString)   // keep the feed-exclusion cache current

        // Instant feedback: show it in Matches immediately (deduped). Owner + other matchers
        // get filled in by the next loadMatchedCards() when the Matches screen opens.
        if !matchedCardInfos.contains(where: { $0.id == card.id }) {
            matchedCardInfos.insert(MatchedCardInfo(card: card, owner: nil, otherMatchers: []), at: 0)
        }

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

    // EL - LEFT / dismiss swipe. Removes the card from `feedCards` and records a
    // "dismissed" marker (status .blocked) so it stays out of the feed across refreshes.
    func dismiss(_ card: DeckCard) {
        feedCards.removeAll { $0.id == card.id }
        actedCardIDs.insert(card.id.uuidString)   // keep the feed-exclusion cache current

        let dismissal = Match(
            id: Match.id(cardID: card.id.uuidString, matcherID: currentOwnerID),
            cardID: card.id.uuidString,
            ownerID: card.ownerID,
            matcherID: currentOwnerID,
            status: .blocked,
            createdAt: Date()
        )

        Task {
            do {
                try await matchRepository.create(dismissal)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // EL - Old local-only swipe, kept so existing feed code still compiles; for the real flow use match(_:) on a right swipe and dismiss(_:) on a left swipe instead of this.
    func swipe(_ card: DeckCard) {
        if let index = cards.firstIndex(of: card) {
            cards.remove(at: index)
        }
        
        
    }

    // MARK: - Matches UI Actions

    // EL - Cancel a match (I can't button). Removes the match from Firestore.
    // If you are the owner, this removes all matches for this card (cancels the event).
    // If you are the matcher, this removes your specific match.
    func cancelMatch(card: DeckCard) async {
        matchedCardInfos.removeAll { $0.card.id == card.id }
        
        do {
            if card.ownerID == currentOwnerID {
                let matches = try await matchRepository.forCard(card.id.uuidString)
                for match in matches {
                    try await matchRepository.delete(id: match.id)
                }
            } else {
                let matchID = Match.id(cardID: card.id.uuidString, matcherID: currentOwnerID)
                try await matchRepository.delete(id: matchID)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // EL - Complete a match (I did it button). Marks the match as completed.
    func completeMatch(card: DeckCard) async {
        matchedCardInfos.removeAll { $0.card.id == card.id }
        
        do {
            if card.ownerID == currentOwnerID {
                let matches = try await matchRepository.forCard(card.id.uuidString)
                for var match in matches where match.status == .accepted {
                    match.status = .completed
                    try await matchRepository.create(match)
                }
            } else {
                let matchID = Match.id(cardID: card.id.uuidString, matcherID: currentOwnerID)
                let myMatch = Match(id: matchID, cardID: card.id.uuidString, ownerID: card.ownerID, matcherID: currentOwnerID, status: .completed)
                try await matchRepository.create(myMatch)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Matched cards (for MatchesView)

    // EL - Loads the cards I've matched with into `matchedCards` (reads my matches, then fetches those cards); call this when MatchesView appears.
    func loadMatchedCards() {
        Task { await loadMatchedCardsFromRepository() }
    }

    // Async variant for views that want to await the refresh (e.g. .task).
    func reloadMatchedCards() async {
        await loadMatchedCardsFromRepository()
    }

    private func loadMatchedCardsFromRepository() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Only real matches (.accepted) — dismissed cards (.blocked) live here too
            // for feed-exclusion, but must not show up in Matches.
            let myMatches = try await matchRepository.forMatcher(currentOwnerID)
            let cardIDs = myMatches.filter { $0.status == .accepted }.map { $0.cardID }
            let cards = try await repository.cards(withIDs: cardIDs)

            // Keep a match only until the end of the day of its event.
            let liveCards = cards.filter { isEventLive($0) }

            // Enrich each card with its owner and the other people who matched it.
            var infos: [MatchedCardInfo] = []
            for card in liveCards {
                let owner = try? await profileRepository.fetch(id: card.ownerID)

                let cardMatches = try await matchRepository.forCard(card.id.uuidString)
                let otherIDs = cardMatches
                    .filter { $0.status == .accepted && $0.matcherID != currentOwnerID }
                    .map { $0.matcherID }
                let otherMatchers = try await profileRepository.users(withIDs: otherIDs)

                infos.append(MatchedCardInfo(card: card, owner: owner, otherMatchers: otherMatchers))
            }
            matchedCardInfos = infos
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

