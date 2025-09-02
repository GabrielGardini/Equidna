//
//  TabBarView.swift
//  EquidnaApp
//
//  Created by Camille Fernandes Luppi on 26/08/25.
//
import SwiftUI

struct TabBarView: View {
    
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        TabView {
            Tab("Menu", systemImage: "plus.square.on.square") {
                CameraView()
            }
            Tab("Histórico", systemImage: "photo.on.rectangle.angled") {
                if let user = userManager.currentUser {
                    HistoryView(meUserID: user.id)
                } else {
                    ProgressView("Carregando usuário...")
                }
            }
            Tab("Perfil", systemImage: "person.crop.circle") {
                ContentView()
            }
        }
    }
}
