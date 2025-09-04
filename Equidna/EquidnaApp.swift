//
//  EquidnaApp.swift
//  Equidna
//
//  Created by Gabriel Gardini on 14/08/25.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions lanchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("App inicializado")
        return true
    }
}

@main
struct EquidnaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var userManager = UserManager()

        var body: some Scene {
            WindowGroup {
                ContentView()
                    .environmentObject(userManager)
                    .onAppear {
                        userManager.setupCurrentUser()
                    }
            }
        }
}
