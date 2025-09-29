//
//  UserSession.swift
//  seventy-two
//
//  Created by Mir Afreed Hassan on 2025-09-28.
//

import Foundation
import SwiftUI
import FirebaseAuth
import Combine

@MainActor
class UserSession: ObservableObject {
    @Published var uid: String?
    @Published var isSignedIn: Bool = false
    @Published var isCheckingAuth: Bool = true  // NEW: loading state

    init() {
        // Initially assume we're checking
        self.isCheckingAuth = true

        // Check current Firebase user
        if let user = Auth.auth().currentUser {
            self.isSignedIn = true
            self.uid = user.uid
        } else {
            self.isSignedIn = false
            self.uid = nil
        }

        // Auth state listener
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isSignedIn = (user != nil)
            self?.uid = user?.uid
            self?.isCheckingAuth = false  // done checking
        }

        // If listener doesn't fire immediately, still mark as checked
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isCheckingAuth = false
        }
    }
}
