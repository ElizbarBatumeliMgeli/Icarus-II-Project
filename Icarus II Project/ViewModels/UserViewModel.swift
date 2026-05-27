//
//  UserViewModel.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 26/05/26.
//

import Foundation
import FirebaseFirestore

// Loads, creates, and updates user profile documents.
@MainActor
@Observable
final class UserViewModel {
    var user: User?
    var isLoading: Bool = false
    var errorMessage: String?

    private let db = Firestore.firestore()
    private var collection: CollectionReference { db.collection("users") }

    // Load a user by id (nil if no document with that id exists).
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

    // Create a new user document keyed off `user.id`.
    func create(_ user: User) async {
        var withTimestamps = user
        let now = Date()
        withTimestamps.createdAt = now
        withTimestamps.updatedAt = now

        do {
            let data = try Firestore.Encoder().encode(withTimestamps)
            try await collection.document(withTimestamps.id).setData(data)
            self.user = withTimestamps
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Merge updates onto an existing user document.
    func update(_ user: User) async {
        var updated = user
        updated.updatedAt = Date()

        do {
            let data = try Firestore.Encoder().encode(updated)
            try await collection.document(updated.id).setData(data, merge: true)
            self.user = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
