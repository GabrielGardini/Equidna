import SwiftUI
import CloudKit
import PhotosUI

struct ProfileView: View {
    @StateObject var viewModel = ProfileViewModel()
    let userID: CKRecord.ID // User RecordID (do iCloud) do usuário exibido

    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                if viewModel.isLoading {
                    ProgressView("Carregando...")
                } else if let user = viewModel.user {
                    VStack(spacing: 12) {

                        // Foto atual OU selecionada
                        Group {
                            if let img = viewModel.selectedImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            } else if let asset = user.profilePhoto,
                                      let url = asset.fileURL,
                                      let data = try? Data(contentsOf: url),
                                      let ui = UIImage(data: data) {
                                Image(uiImage: ui)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .foregroundColor(.gray)
                            }
                        }

                        // Botão para selecionar nova foto
                        PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                            Text("Trocar foto")
                                .font(.callout)
                        }
                        .onChange(of: photoItem) { _, newItem in
                            guard let newItem else { return }
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    await MainActor.run {
                                        viewModel.selectedImage = img
                                    }
                                }
                            }
                        }

                        // Nome (editável)
                        TextField("Nome completo", text: $viewModel.fullNameDraft)
                            .textFieldStyle(.roundedBorder)

                        // Informações extras (somente leitura aqui)
                        Text("Streak: \(user.streak) 🔥")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Invite Code: \(user.inviteCode)")
                            .font(.footnote)
                            .foregroundColor(.blue)

                        Text("Friends: \(user.friends.count)")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        // Botão salvar
                        Button {
                            viewModel.saveChanges()
                        } label: {
                            if viewModel.isSaving {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Salvar alterações")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isSaving)
                    }
                    .padding()

                } else if let errorMessage = viewModel.errorMessage {
                    Text("Erro: \(errorMessage)")
                        .foregroundColor(.red)
                } else {
                    Text("Nenhum usuário encontrado")
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.fetchUser(userID: userID)
        }
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
    }
}
