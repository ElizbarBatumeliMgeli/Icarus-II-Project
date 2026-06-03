//
//  FirebaseTestViewModel.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 26/05/26.
//

import Foundation
import FirebaseFirestore

// One-shot end-to-end check that Firestore is reachable: write a doc, read it back, and surface either the read value or the error to the view

/// WAS WORKING WITH PREVIOUS CONTENTVIEW - WONT RUN RN !!!
@MainActor
@Observable
final class FirebaseTestViewModel {
    enum Status: Equatable {
        case idle
        case running
        case success(String)
        case failure(String)
    }

    var status: Status = .idle

    private let db = Firestore.firestore()
    private let collectionName = "_connection_tests"

    func runWriteThenRead() async {
        status = .running

        let docID = UUID().uuidString
        let payload: [String: Any] = [
            "ts": Timestamp(date: .now),
            "message": "hello from iOS"
        ]

        do {
            try await db.collection(collectionName).document(docID).setData(payload)
            let snapshot = try await db.collection(collectionName).document(docID).getDocument()

            if let data = snapshot.data(),
               let message = data["message"] as? String {
                status = .success("Round-trip OK — read back: \"\(message)\"")
            } else {
                status = .failure("Document written but the read returned no data.")
            }
        } catch {
            status = .failure("\(error.localizedDescription)")
        }
    }
}
