//
//  UserManager.swift
//  Movies
//
//  Created by Gabriel Gardini on 20/08/25.
//

import CloudKit
import SwiftUI

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
                
                // Tenta buscar usuário existente
                self.fetchUser(by: recordID)
            }
        }
    }
    
    private func fetchUser(by recordID: CKRecord.ID) {
        let predicate = NSPredicate(format: "recordID == %@", recordID)
        let query = CKQuery(recordType: "User", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = "Erro ao buscar usuário: \(error.localizedDescription)"
                    return
                }
                
                if let record = records?.first, let user = User(record: record) {
                    self.currentUser = user
                    self.isLoading = false
                } else {
                    // Se não existe, cria um novo usuário
                    self.createUser(recordID: recordID)
                }
            }
        }
    }
    
    private func createUser(recordID: CKRecord.ID) {
        let newUser = User(
            id: recordID,
            fullName: "Nome do Usuário", // aqui você pode colocar um nome padrão ou pedir para o usuário digitar
            inviteCode: UUID().uuidString.prefix(6).uppercased() // exemplo de código de convite
        )
        
        let record = newUser.toRecord()
        database.save(record) { savedRecord, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Erro ao criar usuário: \(error.localizedDescription)"
                    return
                }
                
                if let savedRecord = savedRecord, let user = User(record: savedRecord) {
                    self.currentUser = user
                }
            }
        }
    }
}
