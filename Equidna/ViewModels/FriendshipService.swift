import CloudKit

final class FriendshipService {
    private let db = CKContainer.default().publicCloudDatabase

    // MARK: - Criar amizade a partir de inviteCode
    func addFriend(meUserID: CKRecord.ID, inviteCode rawCode: String,
                   completion: @escaping (Result<Friendship, Error>) -> Void) {
        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else {
            completion(.failure(NSError(domain: "Friendship", code: 1,
                                        userInfo: [NSLocalizedDescriptionKey: "Digite um código válido."])))
            return
        }

        // 1) Busca o amigo pelo inviteCode
        let p = NSPredicate(format: "inviteCode == %@", code)
        let q = CKQuery(recordType: "User", predicate: p)
        db.perform(q, inZoneWith: nil) { [weak self] results, err in
            if let err = err { completion(.failure(err)); return }
            guard let self = self, let friendRec = results?.first else {
                completion(.failure(NSError(domain: "Friendship", code: 2,
                                            userInfo: [NSLocalizedDescriptionKey: "Código inválido ou usuário não encontrado."])))
                return
            }
            if friendRec.recordID == meUserID {
                completion(.failure(NSError(domain: "Friendship", code: 3,
                                            userInfo: [NSLocalizedDescriptionKey: "Você não pode usar seu próprio código."])))
                return
            }

            self.upsertFriendship(aID: meUserID, bID: friendRec.recordID, completion: completion)
        }
    }

    
    // Em algum lugar dentro da classe FriendshipService

    func fetchUser(byInviteCode code: String,
                   completion: @escaping (Result<User, Error>) -> Void) {
        
        // 1) Lógica de validação inicial do código
        let sanitizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !sanitizedCode.isEmpty else {
            completion(.failure(NSError(domain: "Friendship", code: 1,
                                         userInfo: [NSLocalizedDescriptionKey: "Digite um código válido."])))
            return
        }
        
        // 2) Cria a query para buscar o usuário pelo inviteCode
        let predicate = NSPredicate(format: "inviteCode == %@", sanitizedCode)
        let query = CKQuery(recordType: "User", predicate: predicate)
        
        // 3) Executa a busca no CloudKit
        db.perform(query, inZoneWith: nil) { results, err in
            
            // Assegura que o retorno ocorra na thread principal
            DispatchQueue.main.async {
                // A) Lida com erros da busca (CloudKit)
                if let err = err {
                    completion(.failure(err))
                    return
                }
                
                // B) Verifica se um usuário foi encontrado
                guard let record = results?.first,
                      let foundUser = User(record: record) else {
                    completion(.failure(NSError(domain: "Friendship", code: 2,
                                                 userInfo: [NSLocalizedDescriptionKey: "Usuário não encontrado."])))
                    return
                }
                
                // C) Sucesso: retorna o usuário encontrado
                completion(.success(foundUser))
            }
        }
    }
    
    // MARK: - Upsert (idempotente) entre dois Users
    func upsertFriendship(aID: CKRecord.ID, bID: CKRecord.ID,
                          completion: @escaping (Result<Friendship, Error>) -> Void) {
        let name = Friendship.deterministicRecordName(for: aID, and: bID)
        let fid = CKRecord.ID(recordName: name)

        db.fetch(withRecordID: fid) { [weak self] rec, _ in
            if let rec = rec, let friendship = Friendship(record: rec) {
                completion(.success(friendship))
                return
            }
            // criar
            let refA = CKRecord.Reference(recordID: aID, action: .none)
            let refB = CKRecord.Reference(recordID: bID, action: .none)
            let friendship = Friendship(id: fid, userA: refA, userB: refB, createdAt: Date())
            let record = friendship.toRecord()

            self?.db.save(record) { saved, saveErr in
                if let saveErr = saveErr as? CKError, saveErr.code == .serverRecordChanged {
                    self?.db.fetch(withRecordID: fid) { rec2, _ in
                        if let rec2 = rec2, let f2 = Friendship(record: rec2) {
                            completion(.success(f2))
                        } else {
                            completion(.failure(saveErr))
                        }
                    }
                    return
                }
                if let saveErr = saveErr { completion(.failure(saveErr)); return }
                guard let saved = saved, let f = Friendship(record: saved) else {
                    completion(.failure(NSError(domain: "Friendship", code: 4,
                                                userInfo: [NSLocalizedDescriptionKey: "Falha ao salvar amizade."])))
                    return
                }
                completion(.success(f))
            }
        }
    }

    // MARK: - Listar/contar amizades (duas queries, sem OR)
    func fetchFriendships(of meUserID: CKRecord.ID,
                          completion: @escaping (Result<[Friendship], Error>) -> Void) {
        let meRef = CKRecord.Reference(recordID: meUserID, action: .none)
        let fields = ["userA", "userB"]

        var bag: [CKRecord.ID: Friendship] = [:]
        var firstError: Error?
        let group = DispatchGroup()

        for field in fields {
            group.enter()
            let p = NSPredicate(format: "%K == %@", field, meRef) // %K = keyPath
            let q = CKQuery(recordType: "Friendship", predicate: p)
            db.perform(q, inZoneWith: nil) { results, err in
                if let err = err, firstError == nil { firstError = err }
                (results ?? []).forEach { rec in
                    if let f = Friendship(record: rec) { bag[rec.recordID] = f }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if bag.isEmpty, let err = firstError {
                completion(.failure(err))
            } else {
                completion(.success(Array(bag.values)))
            }
        }
    }

    func countFriendships(of meUserID: CKRecord.ID, completion: @escaping (Int) -> Void) {
        fetchFriendships(of: meUserID) { result in
            switch result {
            case .success(let list): completion(list.count)
            case .failure: completion(0)
            }
        }
    }

    // MARK: - Remover amizade
    func removeFriendship(between aID: CKRecord.ID, and bID: CKRecord.ID,
                          completion: @escaping (Result<Void, Error>) -> Void) {
        let name = Friendship.deterministicRecordName(for: aID, and: bID)
        let fid = CKRecord.ID(recordName: name)
        db.delete(withRecordID: fid) { _, err in
            if let err = err { completion(.failure(err)) } else { completion(.success(())) }
        }
    }
}
