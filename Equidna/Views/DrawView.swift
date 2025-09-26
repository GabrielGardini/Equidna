//
//  DrawView.swift
//  Equidna
//
//  Created by Rodrigo Cont on 18/09/25.
//
//  DrawView.swift
//
//  DrawView.swift
//  EquidnaApp
//

import SwiftUI
import PencilKit
import AVKit

struct DrawView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var vm = DrawViewModel()
    @StateObject private var chatVM: ChatViewModel

    // envio
    @State private var showFriendSelector = false
    @State private var exportedImage: UIImage?
    @State private var sendUser: User?

    init(userManager: UserManager) {
        _chatVM = StateObject(wrappedValue: ChatViewModel(userManager: userManager))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Canvas PencilKit
                PencilCanvasView(drawing: $vm.drawing) { canvas in
                    vm.attach(canvas: canvas)   // garante picker quando tiver window
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)

                // Dica quando vazio
                if vm.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "applepencil")
                            .font(.system(size: 44, weight: .regular))
                            .foregroundStyle(.secondary)
                        Text("Comece a desenhar…")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Desenho")
            .navigationBarTitleDisplayMode(.inline)

            // Toolbar (layout da 1ª versão)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        vm.ensureToolPicker() // abre/mostra o picker
                    } label: {
                        Image(systemName: "scribble.variable")
                    }

                    Button(role: .destructive) {
                        vm.clear()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(vm.isEmpty)
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { vm.undo() } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(!vm.canUndo)

                    Button { vm.redo() } label: {
                        Image(systemName: "arrow.uturn.forward")
                    }
                    .disabled(!vm.canRedo)

                    Button {
                        triggerSend()
                    } label: {
                        Label("Enviar", systemImage: "paperplane.fill").labelStyle(.iconOnly)
                    }
                    .disabled(vm.isEmpty)
                }
            }

            // Botão de envio fixo no rodapé (redundância confiável)
            .safeAreaInset(edge: .bottom) {
                if !vm.isEmpty {
                    VStack {
                        Button(action: triggerSend) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Enviar")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                    }
                    .background(.ultraThinMaterial)
                }
            }

            // Sheet: seleção de amigos (com usuário + imagem "congelados")
            .sheet(isPresented: $showFriendSelector, onDismiss: {
                exportedImage = nil
                sendUser = nil
            }) {
                if let user = sendUser, let image = exportedImage {
                    FriendSelectorView(
                        viewModel: chatVM,
                        currentUser: user,
                        image: image,
                        videoURL: nil
                    )
                    .environmentObject(userManager)
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Preparando envio…")
                        Button("Fechar") { showFriendSelector = false }
                    }
                    .padding()
                }
            }

            // Garantias de inicialização
            .onAppear {
                if chatVM.userManager == nil { chatVM.userManager = userManager }
                vm.ensureToolPicker()
            }
            .onChange(of: scenePhase) { _ in
                // recupera picker ao voltar do background
                vm.ensureToolPicker()
            }
        }
    }

    // MARK: - Ações

    private func triggerSend() {
        guard let img = vm.renderImage() else { return }
        guard let user = userManager.currentUser else {
            print("Erro: currentUser indisponível no envio.")
            return
        }
        exportedImage = img   // congela a imagem
        sendUser = user       // congela o usuário
        showFriendSelector = true
    }
}
