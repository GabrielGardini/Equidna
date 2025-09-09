//
//  CameraView.swift
//  Movies
//
//  Created by Camille Fernandes Luppi on 20/08/25.
//

import SwiftUI
import AVKit

struct CameraView: View {
    
    @EnvironmentObject var userManager: UserManager
    
    @State private var isShowingMediaPicker = false
    @State private var selectedImage: UIImage?
    @State private var videoURL: URL?
    @State private var showEnvio = false
    @StateObject private var viewModel: ChatViewModel
    
    init(userManager: UserManager) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(userManager: userManager))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                
                if let inputImage = selectedImage {
                    Image(uiImage: inputImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let videoURL = videoURL {
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 100))
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                Button {
                    self.selectedImage = nil
                    self.videoURL = nil
                    self.isShowingMediaPicker = true
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Câmera")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("Registrar")
            .fullScreenCover(isPresented: $isShowingMediaPicker) {
                MediaPicker(selectedImage: $selectedImage, videoURL: $videoURL, sourceType: .camera)
                    .ignoresSafeArea()
            }
            .onChange(of: selectedImage) { _ in handleMediaChange() }
            .onChange(of: videoURL) { _ in handleMediaChange() }
            .sheet(isPresented: $showEnvio, onDismiss: resetMedia) {
                if let user = userManager.currentUser {
                    FriendSelectorView(
                        viewModel: viewModel,
                        currentUser: user,
                        image: selectedImage,
                        videoURL: videoURL
                    )
                    .environmentObject(userManager)
                }
            }
        }
            .onAppear {
                if viewModel.userManager == nil {
                    viewModel.userManager = userManager
                }
            }
        }
        
        
        private func handleMediaChange() {
            if selectedImage != nil || videoURL != nil {
                showEnvio = true
            }
        }
        
        private func resetMedia() {
            selectedImage = nil
            videoURL = nil
        }
    }
    

