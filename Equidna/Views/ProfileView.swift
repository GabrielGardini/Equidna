import SwiftUI
import CloudKit

struct ProfileView: View {
    @StateObject var viewModel = ProfileViewModel()
    let userID: CKRecord.ID // ID do usuário que você quer exibir

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView("Carregando...")
            } else if let user = viewModel.user {
                VStack(spacing: 12) {
                    if let profilePhoto = user.profilePhoto,
                       let url = profilePhoto.fileURL,
                       let imageData = try? Data(contentsOf: url),
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }
                    
                    Text(user.fullName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Streak: \(user.streak) 🔥")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Invite Code: \(user.inviteCode)")
                        .font(.footnote)
                        .foregroundColor(.blue)
                    
                    Text("Friends: \(user.friends.count)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if let errorMessage = viewModel.errorMessage {
                Text("Erro: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                Text("Nenhum usuário encontrado")
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            viewModel.fetchUser(userID: userID)
        }
    }
}
