//
//  Icarus_II_ProjectApp.swift
//  Icarus II Project
//
//  Created by Elizbar Kheladze on 18/05/26.
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
struct Icarus_II_ProjectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate 
    
    var body: some Scene {
        WindowGroup {
            SignInView()
        }
    }
}
