//
//  RegisterView.swift
//  EquidnaApp
//
//  Created by Giovanna Spigariol on 02/09/25.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var userManager: UserManager
       
    @State private var isShowingMediaPicker = false
    @State private var showEnvio = false
    @StateObject private var viewModel: ChatViewModel
       
    init(userManager: UserManager) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(userManager: userManager))
    }

    @State private var showCamera = false
    @State private var selectedImage: UIImage? = nil
    @State private var videoURL: URL? = nil

    // --- ADD: estados para áudio ---
    @State private var showAudioRecorder = false
    @State private var recordedAudioURL: URL? = nil
    @State private var recordedAudioDuration: TimeInterval = 0
    // -------------------------------

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Transforme o cotidiano em memórias")
                .font(.headline)
                .foregroundColor(.gray)
            
            Spacer()
            // Botões principais
            VStack(spacing: 16) {
                
                // Câmera
                Button {
                    showCamera = true
                } label: {
                    RegisterCardView(
                        title: "Câmera",
                        subtitle: "Faça um instante virar presença",
                        icon: "camera",
                        backgroundImage: "bg_camera"
                    ).background(.white)
                }
                .fullScreenCover(isPresented: $showCamera) {
                    MediaPicker(
                        selectedImage: $selectedImage,
                        videoURL: $videoURL,
                        sourceType: .camera
                    )
                    .ignoresSafeArea()
                }
                .onChange(of: selectedImage) {
                    if selectedImage != nil || videoURL != nil {
                        showEnvio = true
                    }
                }
                .onChange(of: videoURL) {
                    if selectedImage != nil || videoURL != nil {
                        showEnvio = true
                    }
                }
                .sheet(isPresented: $showEnvio, onDismiss: resetMedia) {
                    if let user = userManager.currentUser {
                        FriendSelectorView(
                            viewModel: viewModel,
                            currentUser: user,
                            image: selectedImage,
                            videoURL: videoURL,
                            audioURL: recordedAudioURL,                 // ADD
                            audioDuration: recordedAudioDuration        // ADD
                        )
                        .environmentObject(userManager)
                        .onAppear() {
                            print("--- Abrindo a tela de envio ---")
                            print("A 'selectedImage' na RegisterView é nula? \(selectedImage == nil)")
                        }
                    }
                }
                .onAppear {
                    if viewModel.userManager == nil {
                        viewModel.userManager = userManager
                    }
                }
                
                // Áudio
                Button {
                    showAudioRecorder = true                      // ADD
                } label: {
                    RegisterCardView(
                        title: "Audio",
                        subtitle: "Deixe sua voz mais perto",
                        icon: "mic",
                        backgroundImage: "bg_audio"
                    ).background(.white)
                }
                .fullScreenCover(isPresented: $showAudioRecorder) { // ADD
                    AudioRecorderView { url, duration in
                        recordedAudioURL = url
                        recordedAudioDuration = duration
                        showAudioRecorder = false
                        showEnvio = true                           // abre o mesmo fluxo de envio
                    }
                    .ignoresSafeArea()
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
                        icon: "text.bubble",
                        backgroundImage: "bg_texto"
                    ).background(.white)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 60) // espaço para TabBar
        .navigationTitle("Registrar")
    }

    private func handleMediaChange() {
        if selectedImage != nil || videoURL != nil {
            showEnvio = true
        }
    }

    private func resetMedia() {
        selectedImage = nil
        videoURL = nil
        // --- ADD: limpar estados de áudio ---
        recordedAudioURL = nil
        recordedAudioDuration = 0
        // -----------------------------------
    }
}
