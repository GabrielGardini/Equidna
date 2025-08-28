import SwiftUI
import CloudKit
import PhotosUI
import UIKit

// MARK: - ProfileView

struct ProfileView: View {
    @StateObject var viewModel = ProfileViewModel()
    let userID: CKRecord.ID // User recordID (do tipo `User`) ou User Record ID do iCloud

    // Sheets & nav
    @State private var showShare = false
    @State private var showAddFriend = false
    @State private var showEdit = false
    @State private var didCopyCode = false

    private var displayName: String {
        let name = viewModel.fullNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Nome desconhecido" : name
    }

    var body: some View {
            
       
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Carregando...")
                        .padding(.top, 40)
                } else if let user = viewModel.user {
                    // Avatar
                    VStack(spacing: 12) {
                        AvatarImage(user: user, selected: viewModel.selectedImage)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .shadow(radius: 5)

                        Text(displayName)
                            .font(.title2)
                            .fontWeight(.semibold)

                        // Código com copiar (ícone depois do texto)
                        Button {
                            UIPasteboard.general.string = user.inviteCode
                            withAnimation { didCopyCode = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation { didCopyCode = false }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(user.inviteCode).monospaced()
                                Image(systemName: didCopyCode ? "checkmark.circle.fill" : "doc.on.doc")
                                    .imageScale(.medium)
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)

                    // Cards: Constância / Amigos
                    HStack(spacing: 24) {
                        InfoCard(title: "Constância",
                                 systemImage: "flame",
                                 value: "\(user.streak)")
                        InfoCard(title: "Amigos",
                                 systemImage: "person.2",
                                 value: "\(viewModel.friendsCount)")
                    }
                    .padding(.horizontal)

                    // Ações
                    VStack(spacing: 10) {
                        // Compartilhar perfil
                        FullWidthAction(systemImage: "square.and.arrow.up", title: "Compartilhar perfil") {
                            showShare = true
                        }

                        // Adicionar amigo (via código)
                        FullWidthAction(systemImage: "plus", title: "Adicionar amigo") {
                            showAddFriend = true
                        }

                        // Lista de amigos
                        NavigationLink {
                            FriendsListView(viewModel: viewModel)
                        } label: {
                            RowActionLabel(systemImage: "person.2", title: "Lista de amigos")
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)

                        // Editar perfil (nome/foto) em modal
                        FullWidthAction(systemImage: "pencil", title: "Editar perfil") {
                            showEdit = true
                        }
                    }
                    .padding(.horizontal)

                } else if let errorMessage = viewModel.errorMessage {
                    Text("Erro: \(errorMessage)").foregroundColor(.red)
                } else {
                    Text("Nenhum usuário encontrado").foregroundColor(.gray)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { viewModel.fetchUser(userID: userID) }
        .onChange(of: viewModel.user?.id) { _, newValue in
            if newValue != nil { viewModel.refreshFriendsCount() }
        }
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)

        // MARK: Sheets
        .sheet(isPresented: $showShare) {
            if let user = viewModel.user {
                let text = "Me adiciona no app com meu código: \(user.inviteCode)"
                ShareSheet(activityItems: [text])
            }
        }
        .sheet(isPresented: $showAddFriend) {
            AddFriendSheet(viewModel: viewModel) { success in
                if success { viewModel.refreshFriendsCount() }
            }
            .presentationDetents([.height(230), .medium])
        }
        .sheet(isPresented: $showEdit) {
            EditProfileSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
    }
}


// MARK: - Reusable bits

private struct AvatarImage: View {
    let user: User
    let selected: UIImage?

    var body: some View {
        Group {
            if let img = selected {
                Image(uiImage: img).resizable().scaledToFill()
            } else if let asset = user.profilePhoto,
                      let url = asset.fileURL,
                      let data = try? Data(contentsOf: url),
                      let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable().scaledToFill()
                    .foregroundColor(.gray.opacity(0.6))
                    .background(.clear)
            }
        }
    }
}

private struct InfoCard: View {
    let title: String
    let systemImage: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title).font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 6) {
                Image(systemName: systemImage).imageScale(.medium)
                Text(value).font(.subheadline).monospaced()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct FullWidthAction: View {
    let systemImage: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RowActionLabel(systemImage: systemImage, title: title)
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
    }
}

private struct RowActionLabel: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack {
            Image(systemName: systemImage).imageScale(.medium)
            Text(title)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

// MARK: - Add Friend Sheet

struct AddFriendSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    var completion: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var localCode: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Adicionar amigo")
                    .font(.headline)

                TextField("Código de convite (6 letras/números)", text: $localCode)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)

                Button {
                    viewModel.inviteCodeInput = localCode
                    viewModel.addFriendByInviteCode()
                } label: {
                    if viewModel.isLinking {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Adicionar")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLinking || localCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if let err = viewModel.errorMessage, !err.isEmpty {
                    Text(err).foregroundColor(.red).font(.footnote)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
        .onChange(of: viewModel.isLinking) { _, linking in
            // quando terminar e não tiver erro, fecha
            if !linking, (viewModel.errorMessage ?? "").isEmpty {
                completion(true)
                dismiss()
            }
        }
    }
}

// MARK: - Edit Profile Sheet (nome + foto)
struct EditProfileSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 16) {
            // Handle do sheet
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 36, height: 5)
                .padding(.top, 6)

            // Título + fechar
            HStack {
                Text("Editar")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Circle().fill(Color(.systemGray5)))
                }
                .buttonStyle(.plain)
            }

            // Avatar
            if let user = viewModel.user {
                AvatarImage(user: user, selected: viewModel.selectedImage)
                    .frame(width: 88, height: 88)
                    .clipShape(Circle())
            }

            // Link para trocar foto
            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                Text("Editar foto de perfil")
                    .font(.callout)
                    .foregroundColor(.blue)
                    .underline(false)
            }

            // Nome
            VStack(alignment: .leading, spacing: 6) {
                Text("Nome")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                TextField("Seu nome", text: $viewModel.fullNameDraft)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
            }

            // Salvar alterações
            Button {
                viewModel.saveChanges()
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                    Text("Salvar alterações")
                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
//            .tint(.purple)
            .disabled(viewModel.isSaving)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        // Atualiza foto selecionada
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    await MainActor.run { viewModel.selectedImage = img }
                }
            }
        }
        // Fecha após salvar com sucesso
        .onChange(of: viewModel.isSaving) { _, saving in
            if !saving, (viewModel.errorMessage ?? "").isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { dismiss() }
            }
        }
    }
}
// MARK: - Friends List

struct FriendsListView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var rows: [(friendUserID: CKRecord.ID, user: User)] = []
    @State private var isLoading = true

    var body: some View {
        List {
            if isLoading {
                ProgressView("Carregando amigos…")
            } else if rows.isEmpty {
                Text("Você ainda não tem amigos.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(rows, id: \.friendUserID) { item in
                    HStack(spacing: 12) {
                        AvatarThumb(user: item.user)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.user.fullName).font(.subheadline).bold()
                            Text(item.user.inviteCode).font(.caption).foregroundColor(.secondary).monospaced()
                        }
                        Spacer()
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            viewModel.unfriend(friendUserID: item.friendUserID) { _ in
                                load()
                            }
                        } label: { Label("Remover", systemImage: "person.fill.xmark") }
                    }
                }
            }
        }
        .navigationTitle("Amigos")
        .onAppear { load() }
    }

    private func load() {
        isLoading = true
        viewModel.fetchFriends { list in
            self.rows = list.sorted { $0.user.fullName.localizedCaseInsensitiveCompare($1.user.fullName) == .orderedAscending }
            self.isLoading = false
        }
    }
}

private struct AvatarThumb: View {
    let user: User
    var body: some View {
        Group {
            if let asset = user.profilePhoto,
               let url = asset.fileURL,
               let data = try? Data(contentsOf: url),
               let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill").resizable().scaledToFill().foregroundColor(.gray)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }
}

// MARK: - ShareSheet (UIActivityViewController)

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
