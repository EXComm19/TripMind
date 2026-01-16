//
//  TripMindApp.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/16.
//

import SwiftUI
import FirebaseCore // RE-ADDED: Import FirebaseCore for FirebaseApp.configure()

// RE-ADDED: Define an AppDelegate class to handle Firebase initialization
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure() // RE-ADDED: Configure Firebase when the app launches
    print("FirebaseApp configured.") // Added for debugging confirmation
    return true
  }
}

@main
struct TripMindApp: App {
  // RE-ADDED: Register the AppDelegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  // Create a StateObject for the TripStore to manage its lifecycle
  @StateObject private var tripStore = TripStore()

  var body: some Scene {
    WindowGroup {
        NavigationView {
            ContentView()
        }
        // Inject the TripStore into the environment for descendant views
        .environmentObject(tripStore)
    }
  }
}

