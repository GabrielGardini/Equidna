import SwiftUI
import CloudKit
import PhotosUI

struct ProfileView: View {
    @StateObject var viewModel = ProfileViewModel()
    let userID: CKRecord.ID // User RecordID (do iCloud) OU recordID do tipo `User`

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

                        // Trocar foto
                        PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                            Text("Trocar foto").font(.callout)
                        }
                        .onChange(of: photoItem) { _, newItem in
                            guard let newItem else { return }
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    await MainActor.run { viewModel.selectedImage = img }
                                }
                            }
                        }

                        // Nome (editável)
                        TextField("Nome completo", text: $viewModel.fullNameDraft)
                            .textFieldStyle(.roundedBorder)

                        // Infos
                        Text("Streak: \(user.streak) 🔥")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Invite Code: \(user.inviteCode)")
                            .font(.footnote)
                            .foregroundColor(.blue)

                        // ✅ contador vindo de Friendship
                        Text("Friends: \(viewModel.friendsCount)")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        // Salvar alterações
                        Button {
                            viewModel.saveChanges()
                        } label: {
                            if viewModel.isSaving {
                                ProgressView().frame(maxWidth: .infinity)
                            } else {
                                Text("Salvar alterações").frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isSaving)

                        Divider().padding(.vertical, 6)

                        // Botão de teste para fetchFriends (não depende do invite code)
                        Button {
                            print("➡️ Clicou em Testar fetchFriends")
                            viewModel.fetchFriends { list in
                                print(list)
                                print("🔢 amigos:", list.count)
                                for item in list {
                                    print("• \(item.user.fullName) ID: \(item.friendUserID.recordName)")
                                }
                            }
                        } label: {
                            Text("Testar fetchFriends")
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isLinking)

                        // === Vincular amigo por código ===
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Adicionar amigo por código")
                                .font(.headline)

                            HStack {
                                TextField("Código de convite (6 letras/números)", text: $viewModel.inviteCodeInput)
                                    .textFieldStyle(.roundedBorder)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled(true)
                                    .submitLabel(.go)
                                    .onSubmit { viewModel.addFriendByInviteCode() }

                                Button {
                                    viewModel.addFriendByInviteCode()
                                } label: {
                                    if viewModel.isLinking {
                                        ProgressView()
                                    } else {
                                        Text("Adicionar")
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(
                                    viewModel.isLinking ||
                                    viewModel.inviteCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                )
                            }

                            Text("Compartilhe seu código com amigos para se conectarem.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()

                } else if let errorMessage = viewModel.errorMessage {
                    Text("Erro: \(errorMessage)").foregroundColor(.red)
                } else {
                    Text("Nenhum usuário encontrado").foregroundColor(.gray)
                }
            }
            .padding()
        }
        .onAppear { viewModel.fetchUser(userID: userID) }
        // Recarrega contador quando o perfil carregar
        .onChange(of: viewModel.user?.id) { _, newValue in
            if newValue != nil { viewModel.refreshFriendsCount() }
        }
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
    }
}
