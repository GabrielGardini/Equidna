import SwiftUI
import CloudKit
import Foundation

final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    // edição
    @Published var fullNameDraft: String = ""
    @Published var selectedImage: UIImage?

    private let database = CKContainer.default().publicCloudDatabase

    /// Aceita tanto o recordID do seu tipo `User` quanto o User Record ID do iCloud.
    func fetchUser(userID: CKRecord.ID) {
        isLoading = true
        errorMessage = nil

        // 1) Tenta tratar como recordID do tipo `User`
        database.fetch(withRecordID: userID) { record, fetchErr in
            DispatchQueue.main.async {
                if let rec = record, rec.recordType == "User", let u = User(record: rec) {
                    self.user = u
                    self.fullNameDraft = u.fullName
                    self.isLoading = false
                    return
                }

                // 2) Não era um `User` → trata como User Record ID (iCloud) e busca por userRef
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
                    }
                }
            }
        }
    }

    // Salva nome e (opcional) nova foto
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
}
