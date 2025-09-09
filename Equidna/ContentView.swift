////
////  ContentView.swift
////  Equidna
////
////  Created by Gabriel Gardini on 14/08/25.
////
//



import SwiftUI
import CloudKit

struct ContentView: View {
    @EnvironmentObject var userManager: UserManager

    var body: some View {
        Group {
            if userManager.isLoading {
                ProgressView("Conectando ao iCloud...")
            } else if let _ = userManager.currentUser {
                   TabBarView()
                     //   .navigationBarHidden(true)
                
            } else if let errorMessage = userManager.errorMessage {
                Text("Erro: \(errorMessage)")
            } else {
                // fallback: se não tem usuário, ainda abre o RegisterView
                NavigationStack {
                    Text("Testando")
//                    RegisterView()
//                        .navigationBarHidden(true)
                }
            }
        }
    }
}
