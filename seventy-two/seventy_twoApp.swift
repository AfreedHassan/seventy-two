//
//  seventy_twoApp.swift
//  seventy-two
//
//  Created by Mir Afreed Hassan on 2025-09-24.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

struct RootView: View {
    @EnvironmentObject var userSession: UserSession

    var body: some View {
        Group {
            if userSession.isCheckingAuth {
                ProgressView("Checking authentication…")
                    .progressViewStyle(CircularProgressViewStyle())
            } else if userSession.isSignedIn {
                ContentView()
            } else {
                SignInView()
            }
        }
    }
}

@main
struct seventy_twoApp: App {
    // App delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var userSession = UserSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(userSession)
        }
    }
}

#Preview {
RootView()
.environmentObject(UserSession())
}
