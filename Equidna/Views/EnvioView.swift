////
////  EnvioView.swift
////  EquidnaApp
////
////  Created by Camille Fernandes Luppi on 01/09/25.
////
//
//import SwiftUI
//import CloudKit
//
//struct EnvioView: View {
//    @EnvironmentObject var userManager: UserManager // Acesso ao usuário logado
//    @ObservedObject var viewModel = ChatViewModel()
//    var image: UIImage?
//    var videoURL: URL?
//    
//    @State private var showFriendSelector = false
//    
//    
//    //    init() {
//    //        _viewModel = StateObject(wrappedValue: ChatViewModel(userManager: userManager))
//    //    }
//    
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                if userManager.currentUser != nil {
//                    Text("Preparando envio...")
//                        .onAppear {
//                            viewModel.fetchFriends()
//                            showFriendSelector = true
//                        }
//                } else {
//                    ProgressView("Carregando usuário...")
//                }
//            }
//            .sheet(isPresented: $showFriendSelector) {
//                if let user = userManager.currentUser {
//                    FriendSelectorView(
//                        viewModel: viewModel,
//                        currentUser: user,
//                        image: image,
//                        videoURL: videoURL
//                    )
//                }
//            }
//        }
//        
//        //    @State private var showMediaPicker = false
//        //    @State private var capturedImage: UIImage?
//        //    @State private var capturedVideoURL: URL?
//        //    @State private var showFriendSelector = false
//        //
//        //    var body: some View {
//        //        NavigationView {
//        //            VStack {
//        //                if let user = userManager.currentUser {
//        //                    Text("Histórico de \(user.fullName)")
//        //                } else {
//        //                    ProgressView("Carregando usuário...")
//        //                }
//        //            }
//        //            .navigationTitle("Histórico")
//        //            .toolbar {
//        //                Button(action: { showMediaPicker = true }) {
//        //                    Image(systemName: "camera")
//        //                }
//        //            }
//        //            .sheet(isPresented: $showMediaPicker) {
//        //                // 1. Abre a câmera
//        //                MediaPicker(selectedImage: $capturedImage, videoURL: $capturedVideoURL)
//        //            }
//        //            .onChange(of: capturedImage) { _ in if capturedImage != nil { showFriendSelector = true } }
//        //            .onChange(of: capturedVideoURL) { _ in if capturedVideoURL != nil { showFriendSelector = true } }
//        //            .sheet(isPresented: $showFriendSelector, onDismiss: {
//        //                // Limpa a seleção caso o usuário feche o modal sem enviar
//        //                capturedImage = nil
//        //                capturedVideoURL = nil
//        //            }) {
//        //                if let user = userManager.currentUser {
//        //                    FriendSelectorView(
//        //                        viewModel: viewModel,
//        //                        currentUser: user,
//        //                        image: capturedImage,
//        //                        videoURL: capturedVideoURL
//        //                    )
//        //                }
//        //            }
//        //        }
//        //    }
//    }
//}
