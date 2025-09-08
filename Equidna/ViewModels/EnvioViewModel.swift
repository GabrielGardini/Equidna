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
                       // self.friendList.append(friendUser)

                      //  friends.append(Friend(name: userDetails.name, userReference: CKRecord.Reference(recordID: friendID, action: .none)))
                    }

                    self.friendList = friends.sorted { $0.fullName < $1.fullName }
                } catch {
                    print("Erro ao buscar amigos: \(error)")
                }
            }
        }
    
    func sendMedia(image: UIImage?, videoURL: URL?, to receivers: [String]) {
           Task {
               
               guard let senderId = userManager?.currentUser?.userRef else {
                   //Handle error -> No user ref
                   return
               }
               
               let receiverList:[CKRecord.Reference] = friendList.filter { friend in
                   receivers.contains(friend.userID)
               }.compactMap { friend in
                   friend.userRef
               }
               
               do {
                   let (fileURL, mediaType) = try prepareMediaForUpload(image: image, videoURL: videoURL)
                   let mediaObject = Media(
                       type: mediaType,
                       file: CKAsset(fileURL: fileURL),
                       sender: senderId,
                       receiver: receiverList
                   )
                   _ = try await mediaService.save(media: mediaObject)
               } catch {
                   print("Erro ao enviar mídia: \(error)")
               }
           }
       }
    
    private func prepareMediaForUpload(image: UIImage?, videoURL: URL?) throws -> (url: URL, type: String) {
           if let imageToSave = image {
               guard let data = imageToSave.jpegData(compressionQuality: 0.8) else {
                   throw NSError(domain: "MediaError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Não foi possível converter a imagem."])
               }
               let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
               try data.write(to: fileURL)
               return (fileURL, "image")
           }
           if let videoURL = videoURL {
               return (videoURL, "video")
           }
           throw NSError(domain: "MediaError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Nenhuma mídia válida"])
       }
}
