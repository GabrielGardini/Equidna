//
//  FriendSelectorView.swift
//  EquidnaApp
//
//  Created by Camille Fernandes Luppi on 01/09/25.
//

import SwiftUI
import CloudKit

struct FriendSelectorView: View {
    @ObservedObject var viewModel: ChatViewModel
    let currentUser: User
    let image: UIImage?
    let videoURL: URL?
    
    @State private var selectedFriends: Set<CKRecord.Reference> = []
   // @State private var selectedFriends: Set<String> = []
    @Environment(\.presentationMode) var presentationMode
    

    
    init(viewModel: ChatViewModel, currentUser: User, image: UIImage?, videoURL: URL?) {
        print("Cheguei aqui com \(image)")
        self.viewModel = viewModel
        self.currentUser = currentUser
        self.image = image
        self.videoURL = videoURL
    }
    
    
    private func toggleSelection(_ friend: User) {
        
        guard let friendRef = friend.userRef else { return }
        
        if selectedFriends.contains(friendRef) {
            selectedFriends.remove(friendRef)
        } else {
            selectedFriends.insert(friendRef)
        }
    }
    
    var body: some View {
        NavigationView {
            List(viewModel.friendList, id: \User.id) { friend in
                Button(action: {
                    toggleSelection(friend)
                }) {
                    HStack {
                        Text(friend.fullName)
                        Spacer()
                        if selectedFriends.contains(friend.userRef!) {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                }
            }  .onAppear {
                viewModel.fetchFriends()
            }.navigationTitle("Enviar Para")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancelar") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Enviar") {
                            print("Tentando enviar. A imagem é nula? \(self.image == nil)")
                            guard let senderRef = currentUser.userRef else {
                                print("Erro: A referência do usuário não foi encontrada. Impossível enviar.")
                                presentationMode.wrappedValue.dismiss()
                                return
                            }
                            viewModel.sendMedia(
                                image: image,
                                videoURL: videoURL,
                                to: Array(selectedFriends)
                            )
                            
                            presentationMode.wrappedValue.dismiss()
                        }
                        .disabled(selectedFriends.isEmpty)
                    }
                }
        }
        
        //            List(viewModel.friendList, id: \User.id) { friend in
        //                Button(action: {
        //                    if let ref = friend.userRef {
        //                        toggleSelection(for: ref)
        //                    }
        //                }) {
        //                HStack {
        //                    Text(friend.fullName)
        //                    Spacer()
        //                    if selectedFriends.contains(friend.userReference) {
        //                        Image(systemName: "checkmark.circle.fill")
        //                        }
        //                    }
        //                }
        //            }
        //            .navigationTitle("Enviar Para")
        //            .toolbar
        //                ToolbarItem(placement: .navigationBarLeading) {
        //                    Button("Cancelar") {
        //                        presentationMode.wrappedValue.dismiss()
        //                    }
        //                }
        //                ToolbarItem(placement: .navigationBarTrailing) {
        //                    Button("Enviar") {
        //                        guard let senderRef = currentUser.userRef else {
        //                            print("Erro: A referência do usuário não foi encontrada. Impossível enviar.")
        //                            presentationMode.wrappedValue.dismiss()
        //                            return
        //                        }
        //                        viewModel.sendMedia(
        //                            from: senderRef,
        //                            image: image,
        //                            videoURL: videoURL,
        //                            to: Array(selectedFriends)
        //                        )
        //
        //                        presentationMode.wrappedValue.dismiss()
        //                    }
        //                    .disabled(selectedFriends.isEmpty)
        //                }
        //            }
        //            .onAppear {
        //                viewModel.fetchFriends()
        //            }
        
    }
}
//
//func toggleSelection(for friendReference: CKRecord.Reference) {
//    if selectedFriends.contains(friendReference) {
//        selectedFriends.remove(friendReference)
//    } else {
//        selectedFriends.insert(friendReference)
//    }
//}


