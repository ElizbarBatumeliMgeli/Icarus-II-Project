//
//  blaBlaApp.swift
//  blaBla
//
//  Created by Elizbar Kheladze on 21/05/26.
//
//  NOTE: Commented out to avoid duplicate @main.
//  The active entry point is Icarus_II_ProjectApp.swift.
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
            SignInView()
        }
    }
}
