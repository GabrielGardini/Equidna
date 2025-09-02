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
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(viewModel.friendList, id: \.userReference) { friend in
                Button(action: { toggleSelection(for: friend.userReference) }) {
                    HStack {
                        Text(friend.name)
                        Spacer()
                        if selectedFriends.contains(friend.userReference) {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                }
            }
            .navigationTitle("Enviar Para")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enviar") {
                        guard let senderRef = currentUser.userRef else {
                            print("Erro: A referência do usuário não foi encontrada. Impossível enviar.")
                            presentationMode.wrappedValue.dismiss()
                            return
                        }
                        viewModel.sendMedia(
                            from: senderRef,
                            image: image,
                            videoURL: videoURL,
                            to: Array(selectedFriends)
                        )
                        
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(selectedFriends.isEmpty)
                }
            }
            .onAppear {
                viewModel.fetchFriends()

            }
        }
    }
    func toggleSelection(for friendReference: CKRecord.Reference) {
        if selectedFriends.contains(friendReference) {
                selectedFriends.remove(friendReference)
            } else {
                selectedFriends.insert(friendReference)
            }
    }
}
