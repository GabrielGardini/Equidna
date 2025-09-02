import SwiftUI
import CloudKit
import Foundation

class UserManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let database = CKContainer.default().publicCloudDatabase

    // MARK: - Public API

    func setupCurrentUser() {
        isLoading = true
        errorMessage = nil

        CKContainer.default().fetchUserRecordID { recordID, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = "iCloud Error: \(error.localizedDescription)"
                    return
                }
                guard let recordID = recordID else {
                    self.isLoading = false
                    self.errorMessage = "Não foi possível obter o ID do usuário do iCloud"
                    return
                }
                self.fetchUser(by: recordID)
            }
        }
    }

    // MARK: - Fetch

    private func fetchUser(by userRecordID: CKRecord.ID) {
        print("🔎 Buscando usuário (User Record): \(userRecordID.recordName)")

        let userRef = CKRecord.Reference(recordID: userRecordID, action: .none)
        let predicate = NSPredicate(format: "userRef == %@", userRef)
        let query = CKQuery(recordType: "User", predicate: predicate)

        database.perform(query, inZoneWith: nil) { results, error in
            DispatchQueue.main.async {
                if let error = error as? CKError {
                    print("❌ Query 'User' falhou: \(error.code) – \(error.localizedDescription)")
                    print("ℹ️ userInfo:", error.userInfo)

                    // Tratar como “não achou” quando for erro de schema/índice ausente etc.
                    let msg = error.localizedDescription.lowercased()
                    let treatAsNotFound =
                        msg.contains("did not find record type") ||
                        msg.contains("unknown record type")      ||
                        msg.contains("not queryable")            ||
                        error.code == .unknownItem               ||
                        error.code == .serverRejectedRequest     ||
                        error.code == .invalidArguments

                    if treatAsNotFound {
                        print("➡️ createUser() por erro tratável")
                        self.createUser(userRecordID: userRecordID)
                        return
                    }

                    self.isLoading = false
                    self.errorMessage = "Erro ao buscar usuário: \(error.localizedDescription)"
                    return
                }

                let count = results?.count ?? 0
                print("✅ Query OK, registros retornados: \(count)")

                if let record = results?.first, let user = User(record: record) {
                    print("🙋‍♂️ Usuário existente: \(record.recordID.recordName)")
                    self.currentUser = user
                    self.isLoading = false
                } else {
                    print("🆕 Nenhum registro encontrado → createUser()")
                    self.createUser(userRecordID: userRecordID)
                }
            }
        }
    }

    // MARK: - Create

    private func createUser(userRecordID: CKRecord.ID) {
        print("🧩 Criando User para: \(userRecordID.recordName)")

        // 1) Buscar nome do iCloud (se autorizado). Se não vier, usamos fallback.
        fetchICloudFullName(for: userRecordID) { fullName in
            let newUserID = CKRecord.ID(recordName: UUID().uuidString)
            let userRef = CKRecord.Reference(recordID: userRecordID, action: .none)

            // 2) Montar o record SEM listas vazias
            let record = CKRecord(recordType: "User", recordID: newUserID)
            record["fullName"] = (fullName ?? "Nome do Usuário") as CKRecordValue
            record["userID"] = userRecordID.recordName as CKRecordValue
            record["inviteCode"] = String(UUID().uuidString.prefix(6)).uppercased() as CKRecordValue
            record["streak"] = 0 as CKRecordValue
            record["userRef"] = userRef as CKRecordValue
            // NÃO enviar friends/predefinedMessages quando vazios

            self.database.save(record) { savedRecord, error in
                DispatchQueue.main.async {
                    if let ckErr = error as? CKError {
                        print("❌ Save falhou: \(ckErr.code) – \(ckErr.localizedDescription)")
                        print("ℹ️ userInfo:", ckErr.userInfo)
                        self.isLoading = false
                        self.errorMessage = "Erro ao criar usuário: \(ckErr.localizedDescription)"
                        return
                    }
                    guard let saved = savedRecord else {
                        self.isLoading = false
                        self.errorMessage = "Erro ao criar usuário: resposta sem record"
                        return
                    }

                    print("✅ SALVO: \(saved.recordID.recordName) zone=\(saved.recordID.zoneID.zoneName) db=PUBLIC")

                    // 3) Read-back para confirmar e popular currentUser
                    self.database.fetch(withRecordID: saved.recordID) { fetched, fetchErr in
                        DispatchQueue.main.async {
                            if let fetchErr = fetchErr {
                                print("❌ Fetch pós-save falhou:", fetchErr.localizedDescription)
                            } else {
                                print("🔁 Fetch pós-save OK. Campos:", fetched?.allKeys() ?? [])
                            }
                            if let user = fetched.flatMap(User.init(record:)) {
                                self.currentUser = user
                            }
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }

    // MARK: - iCloud Full Name

    /// Pede permissão de User Discoverability e tenta obter o nome do iCloud.
    /// Retorna `nil` se a permissão for negada/indisponível ou se não houver nome.
    private func fetchICloudFullName(for userRecordID: CKRecord.ID,
                                     completion: @escaping (String?) -> Void) {
        let container = CKContainer.default()

        container.requestApplicationPermission(.userDiscoverability) { status, err in
            if let err = err { print("⚠️ userDiscoverability erro:", err.localizedDescription) }
            guard status == .granted else {
                completion(nil)   // sem permissão → segue com fallback
                return
            }

            container.discoverUserIdentity(withUserRecordID: userRecordID) { identity, _ in
                if let comps = identity?.nameComponents {
                    let formatter = PersonNameComponentsFormatter()
                    let name = formatter.string(from: comps).trimmingCharacters(in: .whitespacesAndNewlines)
                    completion(name.isEmpty ? nil : name)
                } else {
                    completion(nil)
                }
            }
        }
        
    }
}

extension UserManager {
    // Busca os detalhes de um usuário a partir de sua referência.
    func fetchUserDetails(for userRef: CKRecord.Reference, completion: @escaping (Result<(name: String, id: CKRecord.ID), Error>) -> Void) {
        database.fetch(withRecordID: userRef.recordID) { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let record = record, let name = record["fullName"] as? String else {
                    let notFoundError = NSError(domain: "UserManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Usuário ou nome não encontrado."])
                    completion(.failure(notFoundError))
                    return
                }
                completion(.success((name: name, id: record.recordID)))
            }
        }
    }
}
