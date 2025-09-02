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
            Tab("Registrar", systemImage: "plus.square.on.square") {
                CameraView(userManager: userManager)
                    .environmentObject(userManager)
            }

            Tab("Histórico", systemImage: "photo.on.rectangle.angled") {
                
                Text("View do histórico")
            }
            Tab("Perfil", systemImage: "person.crop.circle") {
                ContentView()
            }
        }
    }
}
