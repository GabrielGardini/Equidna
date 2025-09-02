//
//  RegisterView.swift
//  EquidnaApp
//
//  Created by Giovanna Spigariol on 02/09/25.
//

import SwiftUI

struct RegisterView: View {
    @State private var showCamera = false
    @State private var selectedImage: UIImage? = nil
    @State private var videoURL: URL? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Transforme o cotidiano em memórias")
                .font(.headline)
                .foregroundColor(.gray)
            
            Spacer()
            // Título
     //       Text("Registrar")
       //         .font(.largeTitle)
         //       .bold()
           //     .padding(.top, 20)
            
            // Subtítulo
//            Text("Transforme o cotidiano em memórias")
//                .font(.subheadline)
//                .foregroundColor(.gray)
            
            // Botões principais
            VStack(spacing: 16) {
                
                // Câmera
                Button {
                    showCamera = true
                } label: {
                    RegisterCardView(
                        title: "Câmera",
                        subtitle: "Faça um instante virar presença",
                        icon: "camera.fill",
                        backgroundImage: "bg_camera"
                    ).background(.white)
                }
                .fullScreenCover(isPresented: $showCamera) {
                    MediaPicker(
                        selectedImage: $selectedImage,
                        videoURL: $videoURL,
                        sourceType: .camera
                    )
                }
                
                // Áudio
                Button {
                    print("Áudio ainda não implementado")
                } label: {
                    RegisterCardView(
                        title: "Audio",
                        subtitle: "Deixe sua voz mais perto",
                        icon: "mic.fill",
                        backgroundImage: "bg_audio"
                    ).background(.white)
                }
                
                // Desenho
                Button {
                    print("Desenho ainda não implementado")
                } label: {
                    RegisterCardView(
                        title: "Desenho",
                        subtitle: "Compartilhe afeto em traços",
                        icon: "pencil.and.outline",
                        backgroundImage: "bg_desenho"
                    ).background(.white)
                }
                
                // Texto
                Button {
                    print("Texto ainda não implementado")
                } label: {
                    RegisterCardView(
                        title: "Texto",
                        subtitle: "Envie mensagens que aproximam",
                        icon: "text.bubble.fill",
                        backgroundImage: "bg_texto"
                    ).background(.white)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 60) // espaço para TabBar
        .navigationTitle("Registrar")
        //.navigationBarHidden(true)
//        .safeAreaInset(edge: .bottom) {
//            TabBarView()
//        }
    }
}
