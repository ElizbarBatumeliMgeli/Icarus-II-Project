//
//  DeckViewModel.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI

@Observable
final class DeckViewModel {
    // OLA NOTE:
    // This ViewModel is temporary/local-only. You're free to replace/extend it.
    // Purpose: drive the UI and proxy calls to your cloud/backend.
    // How it should act: expose async load/save/delete APIs, publish derived UI state.

    var user = ProfileUser(name: "Marco Rocco", avatarColor: Color(hex: "D3D3D3")) // OLA: replace with the signed-in user from your auth/profile.

    // TODO(OLA): Replace this mocked array with data fetched from your cloud source.
    // Load into `cards` in `fetchCards()` below and publish changes as needed.
    var cards: [DeckCard] = [
//        DeckCard(title: "Design a\ntable", category: "Food", dateText: "Tomorrow", location: "Naples", color: Color(.orange)),
//        DeckCard(title: "Museum\nvisit", category: "Art", dateText: "Weekend", location: "Naples", color: Color(hex: "D8D8D8")),
//        DeckCard(title: "Coffee\nwalk", category: "Social", dateText: "Today", location: "Centro", color: Color(hex: "5F5E69")),
//        DeckCard(title: "Movie\nnight", category: "Fun", dateText: "Friday", location: "Home", color: Color(hex: "D1D1D1"))
    ]

    // UI-friendly mapping used in the profile deck (adjusts color for readability).
    // OLA: Keep/adjust if your backend color palette differs.
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
    
    

    // MARK: - Data loading
    /// OLA: Fetch the latest cards for the current user from your backend.
    /// Call this on app start and when you need to refresh.
    func fetchCards() {
        // TODO(OLA): Implement cloud fetch here.
        // Example (pseudo):
        // self.cards = try await api.fetchCards(for: user)
        // For now we keep the mocked data defined above.
    }

    // Add this property near your other UI states in DeckViewModel
    var draftCard: DeckCard?

    // Update addCard() to create the inline draft instead of opening the sheet
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

    /// Opens the editor in "edit" mode for an existing card (or first card as fallback).
    func editCard(_ card: DeckCard? = nil) {
        selectedCard = card ?? cards.first
        isEditorPresented = true
    }

    func save(card: DeckCard) {
        // TODO(OLA): Upsert this card in your backend (create if new, update if existing).
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
        } else {
            cards.insert(card, at: 0)
        }

        selectedCard = nil
        isEditorPresented = false
    }

    /// Removes a card from the local list.
    /// OLA: Also delete it from your backend.
    func delete(_ card: DeckCard) {
        // TODO(OLA): Delete this card in your backend as well.
        cards.removeAll { $0.id == card.id }
    }

    /// Handles a swipe action (dismisses current card from the feed).
    /// OLA: Optionally record this interaction in your backend (e.g., liked/dismissed).
    func swipe(_ card: DeckCard) {
        // TODO(OLA): Optionally persist swipe/decision state to your backend.
        if let index = cards.firstIndex(of: card) {
            cards.remove(at: index)
        }
        
        
    }

    /// Randomizes the order of cards shown in the feed.
    /// OLA: Purely local UX; you likely don't need to sync this.
    func shuffle() {
        cards.shuffle()
    }
}

