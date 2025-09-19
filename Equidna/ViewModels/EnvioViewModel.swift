//
//  EnvioViewModel.swift
//  EquidnaApp
//
//  Created by Camille Fernandes Luppi on 01/09/25.
//
import SwiftUI
import CloudKit

@MainActor
class ChatViewModel: ObservableObject {
    @Published var friendList: [User] = []
    
    private let friendshipService = FriendshipService()
    private let mediaService = MediaService()
    var userManager: UserManager?
    
    init(userManager: UserManager? = nil) {
        self.userManager = userManager
    }
    
    func fetchFriends() {
        guard let me = userManager?.currentUser else { return }

        Task {
            do {
                let friendships = try await withCheckedThrowingContinuation { continuation in
                    friendshipService.fetchFriendships(of: me.id) { result in
                        continuation.resume(with: result)
                    }
                }

                let otherIDs = friendships.map { pair in
                    pair.userA.recordID == me.id ? pair.userB.recordID : pair.userA.recordID
                }

                var friends: [User] = []

                for friendID in otherIDs {
                    let userDetails = try await withCheckedThrowingContinuation { continuation in
                        userManager?.fetchUserDetails(for: CKRecord.Reference(recordID: friendID, action: .none)) { result in
                            continuation.resume(with: result)
                        }
                    }
                    let friendUser = User(
                        id: userDetails.id,
                        fullName: userDetails.fullName,
                        userID: userDetails.userID,
                        profilePhoto: userDetails.profilePhoto,
                        inviteCode: userDetails.inviteCode,
                        friends: userDetails.friends,
                        streak: userDetails.streak,
                        predefinedMessages: userDetails.predefinedMessages,
                        userRef: userDetails.userRef ?? CKRecord.Reference(recordID: friendID, action: .none)
                    )
                    friends.append(friendUser)
                }

                self.friendList = friends.sorted { $0.fullName < $1.fullName }
            } catch {
                print("Erro ao buscar amigos: \(error)")
            }
        }
    }
    
    func getUserIDs(receivers:[CKRecord.Reference],
                    completion:@escaping (Result<[CKRecord.ID], Error>) -> Void)  {
        let userIds = receivers.map { $0.recordID.recordName }
        let predicate = NSPredicate(format: "userID in %@", userIds )
        let query = CKQuery(recordType: "User", predicate: predicate)
        let db = CKContainer.default().publicCloudDatabase
        
        db.fetch(withQuery: query) { result in
            switch result {
            case .success(let records):
                let recordIds = records.matchResults.map { $0.0 }
                completion(.success(recordIds))
            case .failure(let error):
                print("Error fetching records: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    // (+audioURL, +audioDuration) 
    func sendMedia(image: UIImage?,
                   videoURL: URL?,
                   audioURL: URL? = nil,
                   audioDuration: TimeInterval? = nil,
                   to receivers: [CKRecord.Reference]) {
        Task {
            guard let senderId = userManager?.currentUser?.userRef else {
                print("Error: No sender ID found")
                return
            }
            
            getUserIDs(receivers: [senderId]) { result in
                switch result {
                case .success(let senders):
                    let senderId  = senders[0]
                    self.getUserIDs(receivers: receivers) { result in
                        Task {
                            print("Completou getFriendIds")
                            switch result {
                            case .success(let receivers):
                                print("A logica vai aqui para \(receivers)")
                                do {
                                    let record = CKRecord(recordType: "Media")
                                    
                                    record["sender"] = CKRecord.Reference(recordID: senderId, action: .none)
                                    let references = receivers.map { CKRecord.Reference(recordID: $0, action: .none) }
                                    record["receiver"] = references
                                    
                                    if let aURL = audioURL {
                                        // ---- CASO ÁUDIO (NOVO) ----
                                        record["type"] = "audio"
                                        record["file"] = CKAsset(fileURL: aURL)
                                        if let dur = audioDuration {
                                            record["duration"] = dur as CKRecordValue
                                        }
                                        record["createdAt"] = Date() as CKRecordValue
                                    } else {
                                        // ---- FOTO/VÍDEO (EXISTENTE) ----
                                        let (fileURL, mediaType) = try self.prepareMediaForUpload(image: image, videoURL: videoURL)
                                        record["type"] = mediaType
                                        record["file"] = CKAsset(fileURL: fileURL)
                                        record["createdAt"] = Date() as CKRecordValue
                                    }
                                    
                                    _ = try await self.mediaService.save(record: record)
                                    print("midia enviada com sucesso!")
                                } catch {
                                    print("Erro ao enviar mídia: \(error)")
                                }
                            case .failure(let error):
                                print("Erro \(error)")
                            }
                        }
                    }
                case .failure(let error):
                    print("Erro \(error)")
                }
            }
        }
    }
    // ====== FIM DA ALTERAÇÃO ======
    
    private func prepareMediaForUpload(image: UIImage?, videoURL: URL?) throws -> (url: URL, type: String) {
        if let imageToSave = image {
            guard let data = imageToSave.jpegData(compressionQuality: 0.8) else {
                throw NSError(domain: "MediaError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Não foi possível converter a imagem."])
            }
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
            try data.write(to: fileURL)
            return (fileURL, "photo")
        }
        if let videoURL = videoURL {
            return (videoURL, "video")
        }
        throw NSError(domain: "MediaError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Nenhuma mídia válida"])
    }
}
