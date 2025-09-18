import SwiftUI
import CloudKit
import Photos
import AVKit
import UIKit

struct HistoryView: View {
    @StateObject private var vm = HistoryViewModel()
    let meUserID: CKRecord.ID
    @State private var showFilter = false
    @State private var friendSearch = ""

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    Text("Onde suas memórias vivem")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    // Grade
                    LazyVGrid(columns: cols, spacing: 12) {
                        ForEach(vm.filteredItems, id: \.id) { item in
                            NavigationLink {
                                HistoryMediaDetail(item: item)
                                    .onAppear { vm.markSeen(mediaID: item.id) } // segurança extra
                            } label: {
                                HistoryTile(item: item, isUnread: vm.unread.contains(item.id))
                            }
                            .simultaneousGesture(TapGesture().onEnded { vm.markSeen(mediaID: item.id) })
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("Mural")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilter = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            Text(filterLabel).fontWeight(.semibold)
                        }
                    }
                }
            }
            .onAppear { vm.loadUsingCurrentiCloudUser() }
            .sheet(isPresented: $showFilter) {
                FilterSheet(
                    friends: vm.friends,
                    currentFilter: vm.filter,
                    searchText: $friendSearch
                ) { newFilter in
                    vm.setFilter(newFilter)
                    friendSearch = ""
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private var filterLabel: String {
        switch vm.filter {
        case .all: return "Filtrar"
        case .meOnly: return "Eu (enviadas)"
        case .byFriend(let fid):
            if let f = vm.friends.first(where: { $0.id == fid }) { return f.name }
            return "Amigo"
        }
    }
}

// MARK: - Filter Sheet

private struct FilterSheet: View {
    let friends: [Friend]
    let currentFilter: HistoryFilter
    @Binding var searchText: String
    let onSelect: (HistoryFilter) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Opções") {
                    row(isSelected: currentFilter == .all, label: "Mostrar todos") {
                        onSelect(.all); dismiss()
                    }
                    row(isSelected: currentFilter == .meOnly, label: "Eu (enviadas)") {
                        onSelect(.meOnly); dismiss()
                    }
                }

                Section("Amigos") {
                    ForEach(filteredFriends) { f in
                        row(isSelected: isSelected(friend: f), label: f.name) {
                            onSelect(.byFriend(f.id)); dismiss()
                        }
                    }
                    if filteredFriends.isEmpty {
                        Text("Nenhum amigo encontrado").foregroundColor(.secondary)
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Buscar amigo")
            .navigationTitle("Filtrar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Limpar") { onSelect(.all); dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }

    private var filteredFriends: [Friend] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return friends }
        return friends.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    private func isSelected(friend: Friend) -> Bool {
        if case .byFriend(let fid) = currentFilter { return fid == friend.id }
        return false
    }

    @ViewBuilder
    private func row(isSelected: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                Spacer()
                if isSelected { Image(systemName: "checkmark") }
            }
        }
    }
}

// MARK: - Tiles / Detalhe (iguais ao que você já tinha)

private struct HistoryTile: View {
    let item: HistoryItem
    let isUnread: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))

            if let url = item.asset?.fileURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    case .empty:
                        ProgressView()
                    case .failure(_):
                        fallbackIcon
                    @unknown default:
                        fallbackIcon
                    }
                }
            } else {
                fallbackIcon
            }

            VStack {
                HStack {
                    InitialsBadge(initials: item.friend.initials).padding(6)
                    Spacer()
                }
                Spacer()
            }

            if isUnread {
                VStack {
                    HStack {
                        Spacer()
                        Circle().fill(Color.red).frame(width: 10, height: 10).padding(8)
                    }
                    Spacer()
                }
            }
        }
//        .frame(height: 100)
    }

    private var fallbackIcon: some View {
        Group {
            switch item.type {
            case .photo: Image(systemName: "photo")
            case .video: Image(systemName: "play.circle.fill")
            case .audio: Image(systemName: "waveform")
            case .text:  Image(systemName: "text.alignleft")
            }
        }
        .font(.system(size: 26))
        .foregroundColor(.secondary)
    }
}

private struct InitialsBadge: View {
    let initials: String
    var body: some View {
        Text(initials)
            .font(.caption).bold()
            .foregroundColor(.white)
            .frame(width: 24, height: 24)
            .background(Circle().fill(Color.gray))
    }
}

private struct HistoryMediaDetail: View {
    let item: HistoryItem
    @Environment(\.dismiss) private var dismiss

    @State private var showShare = false
    @State private var isSaving = false
    @State private var showSaveAlert = false
    @State private var saveAlertMessage = ""

    // usado pelo share sheet
    private var shareItems: [Any] {
        guard let url = item.asset?.fileURL else { return [] }

        switch item.type {
        case .photo:
            // 👇 Envie a imagem real, não um URL
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                return [image]
            } else {
                return [url] // fallback
            }

        case .video:
            // 👇 Garante extensão ".mp4" para os apps reconhecerem como vídeo
            if let tmp = tempCopy(url, withExtension: "mp4") {
                return [tmp]
            } else {
                return [url]
            }

        case .audio:
            // 👇 Extensão “.m4a” ajuda apps a tratarem como áudio
            if let tmp = tempCopy(url, withExtension: "m4a") {
                return [tmp]
            } else {
                return [url]
            }

        case .text:
            // Se no futuro você tiver o conteúdo de texto, compartilhe a String
            // Aqui mantemos o URL como fallback.
            return [url]
        }
    }

    // Copia o arquivo para /tmp com a extensão sugerida (melhora compatibilidade no share)
    private func tempCopy(_ source: URL, withExtension ext: String) -> URL? {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
        do {
            // Remove se já existir, por segurança
            if FileManager.default.fileExists(atPath: tmp.path) {
                try FileManager.default.removeItem(at: tmp)
            }
            try FileManager.default.copyItem(at: source, to: tmp)
            return tmp
        } catch {
            print("Falha ao copiar para tmp:", error.localizedDescription)
            return nil
        }
    }
    var body: some View {
        // ✅ NÃO escondemos a Navigation Bar — assim o back "Histórico" aparece
        // ❗️Mas escondemos a Tab Bar no detalhe
        content
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button { saveMedia() } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Label("Salvar", systemImage: "square.and.arrow.down")
                        }
                    }.labelStyle(.titleAndIcon)

                    Spacer()

                    Button {
                        // reproduzir vídeo/áudio se quiser
                    } label: {
                        Label("Reproduzir", systemImage: "play.fill")
                    }
                    .labelStyle(.titleAndIcon)
                    .disabled(item.type == .photo) // não reproduz foto

                    Spacer()

                    Button { showShare = true } label: {
                        Label("Compartilhar", systemImage: "square.and.arrow.up")
                    }.labelStyle(.titleAndIcon)
                }
            }
            .sheet(isPresented: $showShare) {
                ShareSheet(activityItems: shareItems)
            }
            .alert("Salvar mídia", isPresented: $showSaveAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(saveAlertMessage)
            })
    }

    // MARK: - Conteúdo

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // título grande no corpo; o título da barra de navegação será herdado da tela anterior ("Histórico")
                Text(item.friend.name)
                    .font(.largeTitle).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)

//                RoundedRectangle(cornerRadius: 18, style: .continuous)
//                    .fill(Color(.systemGray6))
//                    .frame(height: 360)
//                    .overlay(
                        VStack {
                            if let url = item.asset?.fileURL {
                                AsyncImage(url: url) { img in
                                    img
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(16)
                                } placeholder: {
                                    ProgressView()
                                }
                            } else {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                    .cornerRadius(16)
                            }
                        }
                        .cornerRadius(16)
//                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text("Enviado em \(dateString(item.date)) às \(timeString(item.date))")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        Image(systemName: iconName(for: item.type))
                        Text(label(for: item.type))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }

    // MARK: - Salvar

    private func saveMedia() {
        guard let url = item.asset?.fileURL else {
            saveAlert("Arquivo indisponível.")
            return
        }

        switch item.type {
        case .photo:
            savePhoto(url: url)
        case .video:
            saveVideo(url: url)
        case .audio, .text:
            // para outros tipos, usa ShareSheet → usuário escolhe “Salvar em Arquivos”
            showShare = true
        }
    }

    private func savePhoto(url: URL) {
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            saveAlert("Não foi possível ler a imagem.")
            return
        }

        requestPhotoWriteAccess { granted in
            guard granted else { saveAlert("Permissão negada para salvar no Fotos."); return }
            isSaving = true
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    self.isSaving = false
                    if success {
                        self.saveAlert("Imagem salva no Fotos.")
                    } else {
                        self.saveAlert("Falha ao salvar a imagem. \(error?.localizedDescription ?? "")")
                    }
                }
            }
        }
    }

    private func saveVideo(url: URL) {
        requestPhotoWriteAccess { granted in
            guard granted else { saveAlert("Permissão negada para salvar no Fotos."); return }
            isSaving = true
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                DispatchQueue.main.async {
                    self.isSaving = false
                    if success {
                        self.saveAlert("Vídeo salvo no Fotos.")
                    } else {
                        self.saveAlert("Falha ao salvar o vídeo. \(error?.localizedDescription ?? "")")
                    }
                }
            }
        }
    }

    private func requestPhotoWriteAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 14, *) {
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            switch status {
            case .authorized, .limited: completion(true)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                    DispatchQueue.main.async {
                        completion(newStatus == .authorized || newStatus == .limited)
                    }
                }
            default:
                completion(false)
            }
        } else {
            let status = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .authorized: completion(true)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { newStatus in
                    DispatchQueue.main.async { completion(newStatus == .authorized) }
                }
            default:
                completion(false)
            }
        }
    }

    private func saveAlert(_ message: String) {
        saveAlertMessage = message
        showSaveAlert = true
    }

    // MARK: - Helpers

    private func iconName(for type: MediaType) -> String {
        switch type {
        case .photo: return "photo"
        case .video: return "video"
        case .audio: return "waveform"
        case .text:  return "text.alignleft"
        }
    }
    private func label(for type: MediaType) -> String {
        type == .text ? "Texto" : type.rawValue.capitalized
    }
    private func dateString(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateStyle = .short
        return f.string(from: d)
    }
    private func timeString(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.timeStyle = .short
        return f.string(from: d)
    }
}


// ShareSheet wrapper (se já existir no projeto, remova esta versão)
//private struct ShareSheet: UIViewControllerRepresentable {
//    let items: [Any]
//    let activities: [UIActivity]? = nil
//
//    func makeUIViewController(context: Context) -> UIActivityViewController {
//        UIActivityViewController(activityItems: items, applicationActivities: activities)
//    }
//    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
//}
