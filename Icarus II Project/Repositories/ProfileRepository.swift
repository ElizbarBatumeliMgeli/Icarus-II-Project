//
//  ProfileRepository.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 25/05/26.
//

import Foundation
import FirebaseFirestore

// CRUD + connection operations for User profiles against the `users` Firestore collection.
// Owns no UI state — `UserViewModel` is the consumer.
@MainActor
final class ProfileRepository {
    private let db = Firestore.firestore()
    private var collection: CollectionReference { db.collection("users") }

    // MARK: - CRUD

    // Fetch a user by id; nil if no document with that id exists.
    func fetch(id: String) async throws -> User? {
        let snapshot = try await collection.document(id).getDocument()
        return snapshot.exists ? try snapshot.data(as: User.self) : nil
    }

    // Create a new user document keyed off `user.id`. Stamps createdAt/updatedAt and
    // returns the stored value so the caller can keep its copy in sync.
    @discardableResult
    func create(_ user: User) async throws -> User {
        var newUser = user
        let now = Date()
        newUser.createdAt = now
        newUser.updatedAt = now
        // Assign a random avatar color once, at creation, if none was set — so it's
        // stored and consistent for everyone (no need to recompute it later).
        if newUser.avatarColorHex.isEmpty || newUser.avatarColorHex.uppercased() == "D3D3D3" {
            newUser.avatarColorHex = User.randomAvatarHex()
        }
        let data = try Firestore.Encoder().encode(newUser)
        try await collection.document(newUser.id).setData(data)
        return newUser
    }

    // Merge updates onto an existing user document (bumps updatedAt). Returns the stored value.
    @discardableResult
    func update(_ user: User) async throws -> User {
        var updated = user
        updated.updatedAt = Date()
        let data = try Firestore.Encoder().encode(updated)
        try await collection.document(updated.id).setData(data, merge: true)
        return updated
    }

    // MARK: - Connections

    // Look up the user who owns `code` (nil if no one has it).
    func user(withConnectionCode code: String) async throws -> User? {
        let snapshot = try await collection
            .whereField("connectionCode", isEqualTo: code)
            .limit(to: 1)
            .getDocuments()
        guard let doc = snapshot.documents.first else { return nil }
        return try doc.data(as: User.self)
    }

    // Fetch multiple users by id (for the connections list). `in` caps at 10, so chunk + merge.
    func users(withIDs ids: [String]) async throws -> [User] {
        guard !ids.isEmpty else { return [] }
        var result: [User] = []
        for chunk in Self.chunked(ids, size: 10) {
            let snapshot = try await collection
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            result += try snapshot.documents.map { try $0.data(as: User.self) }
        }
        return result
    }

    // Mutually link two users — each gets the other's id added to `connections`.
    // Atomic via a batch; arrayUnion avoids duplicate entries.
    func connect(_ firstID: String, _ secondID: String) async throws {
        let now = Timestamp(date: Date())
        let batch = db.batch()
        batch.updateData(
            ["connections": FieldValue.arrayUnion([secondID]), "updatedAt": now],
            forDocument: collection.document(firstID)
        )
        batch.updateData(
            ["connections": FieldValue.arrayUnion([firstID]), "updatedAt": now],
            forDocument: collection.document(secondID)
        )
        try await batch.commit()
    }

    // MARK: - Connection code

    // Generate a random, unambiguous code not already taken (best effort).
    // TODO: for guaranteed uniqueness at scale, back this with a `connectionCodes/{code}`
    // registry written inside a transaction rather than a query-then-write check.
    func uniqueConnectionCode() async throws -> String {
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

    // MARK: - Helpers

    // Random code from an unambiguous alphabet (no 0/O/1/I/L).
    private static func randomCode(length: Int = 6) -> String {
        let alphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
        return String((0..<length).compactMap { _ in alphabet.randomElement() })
    }

    // Splits an array into sub-arrays of at most `size` elements (for chunked `in` queries).
    private static func chunked<T>(_ array: [T], size: Int) -> [[T]] {
        stride(from: 0, to: array.count, by: size).map {
            Array(array[$0..<Swift.min($0 + size, array.count)])
        }
    }
}
