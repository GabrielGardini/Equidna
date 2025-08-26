import CloudKit


class UserManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let database = CKContainer.default().publicCloudDatabase

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

                    // 1) Tipos de erro que tratamos como "não achou" → criar
                    let msg = error.localizedDescription.lowercased()
                    let treatAsNotFound =
                        msg.contains("did not find record type") ||   // schema ausente
                        msg.contains("unknown record type")      ||
                        msg.contains("not queryable")            ||   // falta query index
                        error.code == .unknownItem               ||
                        error.code == .serverRejectedRequest     ||
                        error.code == .invalidArguments

                    if treatAsNotFound {
                        print("➡️ caindo para createUser() por erro tratável")
                        self.createUser(userRecordID: userRecordID)
                        return
                    }

                    // 2) Erros realmente críticos: exibe e sai
                    self.isLoading = false
                    self.errorMessage = "Erro ao buscar usuário: \(error.localizedDescription)"
                    return
                }

                let count = results?.count ?? 0
                print("✅ Query OK, registros retornados: \(count)")

                if let record = results?.first, let user = User(record: record) {
                    print("🙋‍♂️ Usuário existente encontrado: \(record.recordID.recordName)")
                    self.currentUser = user
                    self.isLoading = false
                } else {
                    print("🆕 Nenhum registro encontrado → createUser()")
                    self.createUser(userRecordID: userRecordID)
                }
            }
        }
    }


    
    
    private func createUser(userRecordID: CKRecord.ID) {
        print("🧩 Criando User para: \(userRecordID.recordName)")

        let newUserID = CKRecord.ID(recordName: UUID().uuidString)
        let userRef = CKRecord.Reference(recordID: userRecordID, action: .none)

        let record = CKRecord(recordType: "User", recordID: newUserID)
        record["fullName"] = "Nome do Usuário" as CKRecordValue
        record["userID"] = userRecordID.recordName as CKRecordValue
        record["inviteCode"] = String(UUID().uuidString.prefix(6)).uppercased() as CKRecordValue
        record["streak"] = 0 as CKRecordValue
        record["userRef"] = userRef as CKRecordValue

        database.save(record) { savedRecord, error in
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

                // read-back para confirmar
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
