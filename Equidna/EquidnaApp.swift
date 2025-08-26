//
//  EquidnaApp.swift
//  Equidna
//
//  Created by Gabriel Gardini on 14/08/25.
//

import SwiftUI

struct EquidnaApp: App {

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
