import SwiftUI
import CloudKit

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let database = CKContainer.default().publicCloudDatabase
    
    func fetchUser(userID: CKRecord.ID) {
        isLoading = true
        errorMessage = nil
        
        database.fetch(withRecordID: userID) { record, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                if let record = record, let user = User(record: record) {
                    self.user = user
                }
            }
        }
    }
}
