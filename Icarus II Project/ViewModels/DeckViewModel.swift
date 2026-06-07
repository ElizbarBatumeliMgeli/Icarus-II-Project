//
//  DeckViewModel.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI
import FirebaseFirestore

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

    // MARK: - Loading state
    //
    // Each screen gets its OWN loading flag, so one screen's fetch can never make
    // another screen flash its loading UI. (Previously a single shared `isLoading`
    // was flipped by every fetch, which made the feed jump to its skeleton whenever
    // Matches, the profile deck, or a card save happened to be loading.)
    private(set) var isLoadingFeed = false
    private(set) var isLoadingMyDeck = false
    private(set) var isLoadingMatches = false

    // True once the feed has finished its first load attempt. Used so the shimmer
    // skeleton only appears on the very first load — never on later refreshes.
    private(set) var hasLoadedFeedOnce = false

    // Feed-facing loading flag that MainFeedView reads. Computed (not stored) so the
    // skeleton shows ONLY during the first feed load. On every refresh after that, the
    // existing cards stay on screen instead of flashing back to the skeleton.
    var isLoading: Bool { isLoadingFeed && !hasLoadedFeedOnce }

    // Coalesces duplicate one-shot loads (used by the Matches screen): when several views
    // trigger the same refresh at once, only ONE Firestore query runs and the extra callers
    // await that same result. See `LoadCoalescer`.
    // (Feed and My Deck no longer need this — they use the live snapshot listeners below,
    //  which are inherently a single source of truth.)
    private let matchesLoader = LoadCoalescer()

    // MARK: - Live listeners
    //
    // The feed and my-deck stay current in real time via Firestore snapshot listeners, so
    // they update without navigating away and back, and load instantly from Firestore's
    // on-device cache. We keep the registrations so we can detach/re-scope them when the
    // account or connections change, and remove them when the view model goes away.
    private var myDeckListener: ListenerRegistration?
    private var myDeckListenerOwnerID = ""

    private var feedChunkListeners: [ListenerRegistration] = []
    private var feedChunkResults: [Int: [DeckCard]] = [:]   // per-chunk cards, merged in rebuildFeed()
    private var feedScopeKey = ""                            // owner + connections signature; makes start idempotent

    // Holds the active registrations so they can be detached even from `deinit` (which is
    // nonisolated and can't read the main-actor properties above). See `ListenerBag`.
    private nonisolated let listenerBag = ListenerBag()

    // Real participants (other users who've matched a card) shown on feed cards, keyed by
    // card id. Populated just-in-time: a LIVE listener for the top card, plus a one-shot
    // pre-warm for the card behind it so there's no pop-in when it becomes top.
    private(set) var participantsByCardID: [String: [User]] = [:]
    private var topCardID = ""
    private var topMatchersListener: ListenerRegistration?

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
            feedScopeKey = ""            // force the feed listeners to restart for the new account
            participantsByCardID = [:]
            topCardID = ""
            topMatchersListener?.remove()
            topMatchersListener = nil
        }
        // Show the feed skeleton immediately on the very first load (before the first
        // snapshot arrives), then attach the live listeners. Re-binds after that don't
        // re-show the skeleton (see `isLoading`).
        if !hasLoadedFeedOnce { isLoadingFeed = true }
        startMyDeckListener()
        Task { await startFeedListeners() }
    }

    // MARK: - My deck

    // EL - Loads MY OWN cards into `cards` (used by the profile deck). Fire-and-forget from the UI.
    // Now backed by a live listener, so the deck stays current on its own.
    func fetchCards() {
        startMyDeckListener()
    }

    // Async variant kept for views that `await` it (e.g. .task). With the live listener in
    // place this just ensures we're listening; the data then updates on its own.
    func reloadCards() async {
        startMyDeckListener()
    }

    // True while the card's event day hasn't passed. Cards without an event date
    // never expire (we can't tell when they end).
    private func isEventLive(_ card: DeckCard) -> Bool {
        guard let event = card.eventDate else { return true }
        return Calendar.current.startOfDay(for: event) >= Calendar.current.startOfDay(for: Date())
    }

    // Starts (or keeps) the live listener for my own deck. Idempotent for the same account.
    private func startMyDeckListener() {
        guard !currentOwnerID.isEmpty else { return }
        if myDeckListener != nil && myDeckListenerOwnerID == currentOwnerID { return }

        myDeckListener?.remove()
        myDeckListenerOwnerID = currentOwnerID
        isLoadingMyDeck = true

        myDeckListener = repository.observeMyDeck(ownerID: currentOwnerID) { [weak self] cards in
            guard let self else { return }
            // Show my cards through the end of each event's day; drop expired ones.
            self.cards = cards.filter { self.isEventLive($0) }
            self.isLoadingMyDeck = false
        }
        syncListenerBag()
    }

    // MARK: - Feed (cards from my connections)

    // EL - Loads the swipe feed into `feedCards` (cards from my connections, excluding my own); call this when the feed appears — it relies on `user.connections`, which becomes the real list once auth/profile load is in.
    func loadFeed() {
        Task { await reloadFeed() }
    }

    // Async variant kept for views that `await` it (.task / scenePhase / onChange). With the
    // live listeners in place this just ensures we're listening for the current connection
    // set; the feed then updates on its own. Idempotent if nothing changed.
    func reloadFeed() async {
        await startFeedListeners()
    }

    // Starts (or re-scopes) the live feed listeners for my current connections.
    // Idempotent: if the connection set is unchanged and we're already listening, no-op.
    private func startFeedListeners() async {
        let connections = user.connections
        let scopeKey = currentOwnerID + "|" + connections.sorted().joined(separator: ",")
        if scopeKey == feedScopeKey && !feedChunkListeners.isEmpty { return }
        feedScopeKey = scopeKey

        // Detach any previous chunk listeners before re-scoping.
        feedChunkListeners.forEach { $0.remove() }
        feedChunkListeners = []
        feedChunkResults = [:]

        // No connections → empty feed (the view shows EmptyFeedView). My own cards are never
        // in the feed, since my own id is never in my connections list.
        guard !connections.isEmpty else {
            feedCards = []
            isLoadingFeed = false
            hasLoadedFeedOnce = true
            syncListenerBag()
            return
        }

        isLoadingFeed = true

        // Firestore `in` caps at 10 owner ids, so we listen per chunk and merge the results.
        // (Attach synchronously — no `await` before this — so two concurrent starts can't
        //  both slip past the idempotency check and double-attach.)
        for (index, chunk) in Self.chunked(connections, size: 10).enumerated() {
            let listener = repository.observeFeedChunk(ownerIDs: chunk) { [weak self] cards in
                guard let self else { return }
                self.feedChunkResults[index] = cards
                self.rebuildFeed()
                self.isLoadingFeed = false
                self.hasLoadedFeedOnce = true
            }
            feedChunkListeners.append(listener)
        }
        syncListenerBag()

        // Seed the acted-on set ONCE so the feed can exclude cards I've already swiped.
        // After that it's kept current locally by match()/dismiss(). Re-filter once it lands.
        if !actedSetLoaded {
            do {
                let actedOn = try await matchRepository.forMatcher(currentOwnerID)
                actedCardIDs = Set(actedOn.map { $0.cardID })
                actedSetLoaded = true
                rebuildFeed()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // Merges the per-chunk listener results and hides cards I've already acted on.
    private func rebuildFeed() {
        let all = feedChunkResults.values.flatMap { $0 }
        feedCards = all.filter { !actedCardIDs.contains($0.id.uuidString) }
        refreshFeedParticipants()
    }

    // MARK: - Feed participants (real avatars on the cards)

    // The other users who've matched `card` (rendered as colour + initial). Empty until
    // someone matches it (the view shows the "Be the first" state in that case).
    func participants(for card: DeckCard) -> [User] {
        participantsByCardID[card.id.uuidString] ?? []
    }

    // Keeps a LIVE listener pointed at the top feed card, and pre-warms the card behind it
    // so its participants are ready the moment it becomes top. Called whenever the feed
    // changes (load, match, dismiss).
    private func refreshFeedParticipants() {
        let topID = feedCards.first?.id.uuidString
        if topID != topCardID {
            topCardID = topID ?? ""
            topMatchersListener?.remove()
            topMatchersListener = nil
            if let topID {
                topMatchersListener = matchRepository.observeCard(cardID: topID) { [weak self] matches in
                    guard let self else { return }
                    Task { await self.resolveParticipants(forCardID: topID, from: matches) }
                }
            }
            syncListenerBag()
        }

        // Pre-warm the card behind the top one (one-shot) so there's no pop-in when it surfaces.
        if let backID = feedCards.dropFirst().first?.id.uuidString,
           participantsByCardID[backID] == nil {
            Task { [weak self] in
                guard let self else { return }
                if let matches = try? await self.matchRepository.forCard(backID) {
                    await self.resolveParticipants(forCardID: backID, from: matches)
                }
            }
        }
    }

    // Resolves a card's accepted matchers (excluding me; owners aren't matchers) into users
    // for the avatar row.
    private func resolveParticipants(forCardID cardID: String, from matches: [Match]) async {
        let otherIDs = matches
            .filter { $0.status == .accepted && $0.matcherID != currentOwnerID }
            .map { $0.matcherID }
        guard !otherIDs.isEmpty else {
            participantsByCardID[cardID] = []
            return
        }
        if let users = try? await profileRepository.users(withIDs: otherIDs) {
            participantsByCardID[cardID] = users
        }
    }

    // Splits an array into sub-arrays of at most `size` elements (for chunked `in` listeners).
    private static func chunked<T>(_ array: [T], size: Int) -> [[T]] {
        stride(from: 0, to: array.count, by: size).map {
            Array(array[$0..<Swift.min($0 + size, array.count)])
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
                // The my-deck listener reflects this automatically, and my own cards never
                // appear in the feed, so no manual refresh is needed here.
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
        refreshFeedParticipants()                 // top card changed → re-point the live listener

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
        refreshFeedParticipants()                 // top card changed → re-point the live listener

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

    // MARK: - Matched cards (for MatchesView)

    // EL - Loads the cards I've matched with into `matchedCards` (reads my matches, then fetches those cards); call this when MatchesView appears.
    func loadMatchedCards() {
        Task { await reloadMatchedCards() }
    }

    // Async variant for views that want to await the refresh (e.g. .task).
    // Coalesced, and uses its own loading flag so the feed is never affected.
    func reloadMatchedCards() async {
        await matchesLoader.run { [weak self] in
            guard let self else { return }
            await self.performMatchedCardsLoad()
        }
    }

    private func performMatchedCardsLoad() async {
        isLoadingMatches = true
        errorMessage = nil
        defer { isLoadingMatches = false }

        do {
            // Only real matches (.accepted) — dismissed cards (.blocked) live here too
            // for feed-exclusion, but must not show up in Matches.
            let myMatches = try await matchRepository.forMatcher(currentOwnerID)
            let cardIDs = myMatches.filter { $0.status == .accepted }.map { $0.cardID }
            let cards = try await repository.cards(withIDs: cardIDs)

            // Keep a match only until the end of the day of its event.
            let liveCards = cards.filter { isEventLive($0) }

            // Enrich each card with its owner and the other people who matched it.
            // Done concurrently: every card's lookups run at the same time, and within a
            // single card the owner fetch overlaps the card's match lookup. So the screen
            // loads in roughly the time of the slowest single card instead of the sum of
            // all of them (previously this was a serial loop = N cards × 3 round-trips).
            let me = currentOwnerID
            let profileRepo = profileRepository
            let matchRepo = matchRepository

            let infos = try await withThrowingTaskGroup(of: (Int, MatchedCardInfo).self) { group -> [MatchedCardInfo] in
                for (index, card) in liveCards.enumerated() {
                    group.addTask {
                        // owner and the card's matches don't depend on each other → fetch together
                        async let ownerLookup = profileRepo.fetch(id: card.ownerID)

                        let cardMatches = try await matchRepo.forCard(card.id.uuidString)
                        let otherIDs = cardMatches
                            .filter { $0.status == .accepted && $0.matcherID != me }
                            .map { $0.matcherID }
                        let otherMatchers = try await profileRepo.users(withIDs: otherIDs)

                        let owner = try? await ownerLookup
                        return (index, MatchedCardInfo(card: card, owner: owner, otherMatchers: otherMatchers))
                    }
                }

                // A TaskGroup yields results in completion order, so place each one back at
                // its original index to keep a stable on-screen order across loads.
                var ordered = [MatchedCardInfo?](repeating: nil, count: liveCards.count)
                for try await (index, info) in group {
                    ordered[index] = info
                }
                return ordered.compactMap { $0 }
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

    // Keeps `listenerBag` in sync with the currently-active listeners, so teardown can
    // detach them from `deinit` (which can't read main-actor state directly).
    private func syncListenerBag() {
        listenerBag.setRegistrations(
            [myDeckListener, topMatchersListener].compactMap { $0 } + feedChunkListeners
        )
    }

    // Detach all live listeners when the view model is torn down (e.g. on logout).
    deinit {
        listenerBag.removeAll()
    }
}

// MARK: - LoadCoalescer
//
// Ensures only ONE run of a given async load happens at a time. If extra callers ask
// for the same load while it's already running, they await the in-flight run instead
// of kicking off a duplicate Firestore query. This is what lets several views each
// trigger `reloadFeed()` on launch without causing multiple queries or UI flashes.
//
// One instance per data set (feed / my deck / matches), so the three loads stay
// independent of each other. Kept in this file for now; can move to its own file later.
@MainActor
final class LoadCoalescer {
    private var task: Task<Void, Never>?

    func run(_ work: @escaping () async -> Void) async {
        // A load is already running — piggy-back on it instead of starting another.
        if let task {
            await task.value
            return
        }
        let newTask = Task { await work() }
        task = newTask
        await newTask.value
        task = nil
    }
}

// MARK: - ListenerBag
//
// Small holder for Firestore listener registrations. Lets the view model detach its
// listeners from `deinit`, which is nonisolated and therefore can't read the view model's
// main-actor properties directly. Registrations are only set from the main actor and only
// flushed once at teardown, so @unchecked Sendable is safe here.
final class ListenerBag: @unchecked Sendable {
    private var registrations: [ListenerRegistration] = []

    // Replace the tracked set. The view model already attaches/detaches when it re-scopes;
    // this just mirrors the current set so `removeAll()` can clean everything up later.
    func setRegistrations(_ registrations: [ListenerRegistration]) {
        self.registrations = registrations
    }

    // Detach everything. Called once on teardown.
    func removeAll() {
        registrations.forEach { $0.remove() }
        registrations = []
    }
}

