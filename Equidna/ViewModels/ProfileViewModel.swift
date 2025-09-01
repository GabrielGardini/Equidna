import SwiftUI
import CloudKit
import Foundation
import UIKit // necessário para UIImage

final class ProfileViewModel: ObservableObject {
    // Estado principal
    @Published var user: User?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    // Edição de perfil
    @Published var fullNameDraft: String = ""
    @Published var selectedImage: UIImage?

    // Convite / amizade
    @Published var inviteCodeInput: String = ""
    @Published var isLinking = false
    @Published var friendsCount: Int = 0
    
    // Usuário estrangeiro
    @Published var foundUser: User?

    private let database = CKContainer.default().publicCloudDatabase
    private let friendshipService = FriendshipService()

    // MARK: - Carregar usuário
    /// Aceita tanto o recordID do seu tipo `User` quanto o User Record ID do iCloud.
    func fetchUser(userID: CKRecord.ID) {
        isLoading = true
        errorMessage = nil

        // 1) Tenta tratar como recordID do tipo `User`
        database.fetch(withRecordID: userID) { record, _ in
            DispatchQueue.main.async {
                if let rec = record, rec.recordType == "User", let u = User(record: rec) {
                    self.user = u
                    self.fullNameDraft = u.fullName
                    self.isLoading = false
                    self.refreshFriendsCount()
                    return
                }

                // 2) Não era um `User` → trata como User Record ID do iCloud (userRef)
                let ref = CKRecord.Reference(recordID: userID, action: .none)
                let predicate = NSPredicate(format: "userRef == %@", ref)
                let query = CKQuery(recordType: "User", predicate: predicate)

                self.database.perform(query, inZoneWith: nil) { results, qErr in
                    DispatchQueue.main.async {
                        if let qErr = qErr {
                            self.isLoading = false
                            self.errorMessage = "Erro ao carregar perfil: \(qErr.localizedDescription)"
                            return
                        }
                        guard let rec = results?.first, let u = User(record: rec) else {
                            self.isLoading = false
                            self.errorMessage = "Usuário não encontrado."
                            return
                        }
                        self.user = u
                        self.fullNameDraft = u.fullName
                        self.isLoading = false
                        self.refreshFriendsCount()
                    }
                }
            }
        }
    }
    
    func fetchUser(byInviteCode code: String) {
        isLoading = true
        errorMessage = nil
        foundUser = nil

        // Chama o novo método do FriendshipService
        friendshipService.fetchUser(byInviteCode: code) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let user):
                    self?.foundUser = user
                    self?.errorMessage = nil // Limpa qualquer erro anterior
                case .failure(let error):
                    // Trata o erro e atualiza o estado
                    self?.errorMessage = error.localizedDescription
                    self?.foundUser = nil
                }
            }
        }
    }

    // MARK: - Salvar nome/foto
    func saveChanges() {
        guard let user = user else { return }
        isSaving = true
        errorMessage = nil

        database.fetch(withRecordID: user.id) { record, fetchErr in
            if let fetchErr = fetchErr {
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.errorMessage = "Erro ao abrir o registro: \(fetchErr.localizedDescription)"
                }
                return
            }
            guard let record = record else {
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.errorMessage = "Registro não encontrado para salvar."
                }
                return
            }

            record["fullName"] = self.fullNameDraft as CKRecordValue

            if let image = self.selectedImage,
               let url = self.writeTempJPEG(image: image, quality: 0.9) {
                record["profilePhoto"] = CKAsset(fileURL: url)
            }

            self.database.save(record) { saved, saveErr in
                DispatchQueue.main.async {
                    self.isSaving = false
                    if let saveErr = saveErr {
                        self.errorMessage = "Erro ao salvar: \(saveErr.localizedDescription)"
                        return
                    }
                    if let saved = saved, let updated = User(record: saved) {
                        self.user = updated
                        self.fullNameDraft = updated.fullName
                        self.selectedImage = nil
                    }
                }
            }
        }
    }

    // MARK: - Adicionar amigo por código (Friendship-only)
    func addFriendByInviteCode() {
        guard let me = user else { return }
        let code = inviteCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else {
            self.errorMessage = "Digite um código de convite."
            return
        }
        guard code != me.inviteCode else {
            self.errorMessage = "Você não pode usar seu próprio código."
            return
        }

        isLinking = true
        errorMessage = nil

        friendshipService.addFriend(meUserID: me.id, inviteCode: code) { result in
            DispatchQueue.main.async {
                self.isLinking = false
                switch result {
                case .success:
                    self.inviteCodeInput = ""
                    self.refreshFriendsCount()
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                }
            }
        }
    }

    // MARK: - Contar amizades
    func refreshFriendsCount() {
        guard let me = user else { return }
        friendshipService.countFriendships(of: me.id) { count in
            DispatchQueue.main.async { self.friendsCount = count }
        }
    }

    // MARK: - Listar amigos resolvendo Users
    func fetchFriends(completion: @escaping ([(friendUserID: CKRecord.ID, user: User)]) -> Void) {
        guard let me = user else { completion([]); return }
        friendshipService.fetchFriendships(of: me.id) { [weak self] result in
            switch result {
            case .failure:
                DispatchQueue.main.async { completion([]) }
            case .success(let pairs):
                // IDs dos amigos (o "outro" lado de cada par)
                let otherIDs: [CKRecord.ID] = pairs.map { pair in
                    pair.userA.recordID == me.id ? pair.userB.recordID : pair.userA.recordID
                }
                self?.fetchUsers(with: otherIDs, completion: completion)
            }
        }
    }

    // MARK: - Remover amizade
    func unfriend(friendUserID: CKRecord.ID, completion: @escaping (Bool) -> Void) {
        guard let me = user else { completion(false); return }
        friendshipService.removeFriendship(between: me.id, and: friendUserID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.refreshFriendsCount()
                    completion(true)
                case .failure(let e):
                    self.errorMessage = e.localizedDescription
                    completion(false)
                }
            }
        }
    }

    // MARK: - Utils

    private func writeTempJPEG(image: UIImage, quality: CGFloat) -> URL? {
        guard let data = image.jpegData(compressionQuality: quality) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            print("Falha ao escrever JPEG temporário:", error.localizedDescription)
            return nil
        }
    }

    private func fetchUsers(with ids: [CKRecord.ID],
                            completion: @escaping ([(friendUserID: CKRecord.ID, user: User)]) -> Void) {
        guard !ids.isEmpty else { completion([]); return }
        let op = CKFetchRecordsOperation(recordIDs: ids)
        var out: [(CKRecord.ID, User)] = []
        op.perRecordResultBlock = { id, res in
            if case .success(let rec) = res, let u = User(record: rec) {
                out.append((id, u))
            }
        }
        op.fetchRecordsResultBlock = { _ in
            DispatchQueue.main.async { completion(out) }
        }
        database.add(op)
    }
}
