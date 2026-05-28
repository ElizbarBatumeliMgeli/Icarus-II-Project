//
//  UserViewModel.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 26/05/26.
//

import Foundation
import FirebaseFirestore

/// Loads, creates, and updates user profile documents, and manages mutual
/// connections between users via a permanent, shareable code.
@MainActor
@Observable
final class UserViewModel {
    var user: User?
    var isLoading: Bool = false
    var errorMessage: String?

    private let db = Firestore.firestore()
    private var collection: CollectionReference { db.collection("users") }

    // MARK: - Load / Create / Update

    /// Load a user by id (nil if no document with that id exists).
    func load(id: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let snapshot = try await collection.document(id).getDocument()
            user = snapshot.exists ? try snapshot.data(as: User.self) : nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Create a user document keyed off `user.id`.
    /// Assigns a unique permanent connection code if the incoming user has none.
    func create(_ user: User) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var newUser = user
            if newUser.connectionCode.isEmpty {
                newUser.connectionCode = try await uniqueConnectionCode()
            }
            let now = Date()
            newUser.createdAt = now
            newUser.updatedAt = now

            let data = try Firestore.Encoder().encode(newUser)
            try await collection.document(newUser.id).setData(data)
            self.user = newUser
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Merge updates onto an existing user document.
    func update(_ user: User) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var updated = user
            updated.updatedAt = Date()
            let data = try Firestore.Encoder().encode(updated)
            try await collection.document(updated.id).setData(data, merge: true)
            self.user = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Connections

    /// Connects the current user to whoever owns `code`. The link is mutual:
    /// both user documents get the other's id added to their `connections`.
    func connect(usingCode code: String) async {
        guard let me = user else {
            errorMessage = "No current user loaded."
            return
        }
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else {
            errorMessage = "Enter a connection code."
            return
        }
        guard trimmed != me.connectionCode else {
            errorMessage = "That's your own code."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Find the owner of this code.
            let snapshot = try await collection
                .whereField("connectionCode", isEqualTo: trimmed)
                .limit(to: 1)
                .getDocuments()

            guard let doc = snapshot.documents.first else {
                errorMessage = "No user found for code \(trimmed)."
                return
            }

            let other = try doc.data(as: User.self)
            guard other.id != me.id else {
                errorMessage = "That's your own code."
                return
            }

            // Mutual link, atomic via a batch. arrayUnion avoids duplicate entries.
            let now = Timestamp(date: Date())
            let batch = db.batch()
            batch.updateData(
                ["connections": FieldValue.arrayUnion([other.id]), "updatedAt": now],
                forDocument: collection.document(me.id)
            )
            batch.updateData(
                ["connections": FieldValue.arrayUnion([me.id]), "updatedAt": now],
                forDocument: collection.document(other.id)
            )
            try await batch.commit()

            // Reflect locally.
            if user?.connections.contains(other.id) == false {
                user?.connections.append(other.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Loads the full User records for the current user's connections.
    /// NOTE: Firestore `in` queries cap at 10 ids — chunk this if a user can
    /// have more connections than that.
    func loadConnections() async throws -> [User] {
        guard let me = user, !me.connections.isEmpty else { return [] }
        let snapshot = try await collection
            .whereField(FieldPath.documentID(), in: Array(me.connections.prefix(10)))
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: User.self) }
    }

    // MARK: - Connection code helpers

    /// Generates a random, unambiguous code and ensures it isn't already taken (best effort).
    /// TODO: for guaranteed uniqueness at scale, back this with a `connectionCodes/{code}`
    /// registry written inside a transaction rather than a query-then-write check.
    private func uniqueConnectionCode() async throws -> String {
        for _ in 0..<5 {
            let code = Self.randomCode()
            let existing = try await collection
                .whereField("connectionCode", isEqualTo: code)
                .limit(to: 1)
                .getDocuments()
            if existing.documents.isEmpty { return code }
        }
        // Extremely unlikely fallback: a longer code for more entropy.
        return Self.randomCode(length: 8)
    }

    /// Random code from an unambiguous alphabet (no 0/O/1/I/L).
    private static func randomCode(length: Int = 6) -> String {
        let alphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
        return String((0..<length).compactMap { _ in alphabet.randomElement() })
    }
}
