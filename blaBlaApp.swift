//
//  blaBlaApp.swift
//  blaBla
//
//  Created by Elizbar Kheladze on 21/05/26.
//
//  App entry point (@main). Launches AppSessionView, which routes to the
//  sign-in screen or the main app depending on auth state.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct blaBlaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            AppSessionView()
        }
    }
}
