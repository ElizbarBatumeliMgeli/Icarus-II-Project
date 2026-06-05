//
//  UserViewModel.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 26/05/26.
//

import Foundation

// Loads, creates, and updates user profile documents, and manages mutual connections
// between users via a permanent, shareable code. Firestore I/O lives in ProfileRepository.
@MainActor
@Observable
final class UserViewModel {
    var user: User?
    var isLoading: Bool = false
    var errorMessage: String?
    var pendingConnectionUser: User?

    private let repository = ProfileRepository()

    // MARK: - Load / Create / Update

    // Load a user by id (nil if no document with that id exists).
    func load(id: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            user = try await repository.fetch(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Create a user document keyed off `user.id`.
    // Assigns a unique permanent connection code if the incoming user has none.
    func create(_ user: User) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var newUser = user
            if newUser.connectionCode.isEmpty {
                newUser.connectionCode = try await repository.uniqueConnectionCode()
            }
            self.user = try await repository.create(newUser)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Merge updates onto an existing user document.
    func update(_ user: User) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            self.user = try await repository.update(user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Connections

    // Connects the current user to whoever owns `code`. The link is mutual as both user
    // documents get the other's id added to their `connections`.
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
            errorMessage = "That's your own code silly."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { 
            isLoading = false 
            pendingConnectionUser = nil
        }

        do {
            guard let other = try await repository.user(withConnectionCode: trimmed) else {
                errorMessage = "No user found for code \(trimmed)."
                return
            }
            guard other.id != me.id else {
                errorMessage = "That's your own code dumbass."
                return
            }
            guard !me.connections.contains(other.id) else {
                errorMessage = "You're already connected with \(other.displayName)."
                return
            }

            try await repository.connect(me.id, other.id)

            // Reflect locally.
            if user?.connections.contains(other.id) == false {
                user?.connections.append(other.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadConnections() async throws -> [User] {
        guard let me = user else { return [] }
        return try await repository.users(withIDs: me.connections)
    }

    func handleDeepLink(_ url: URL) async {
        guard url.scheme == "icarus",
              url.host == "connect",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let targetUser = try await repository.user(withConnectionCode: code) {
                pendingConnectionUser = targetUser
            } else {
                errorMessage = "Invalid connection link."
            }
        } catch {
            errorMessage = "Failed to load connection data: \(error.localizedDescription)"
        }
    }
}
