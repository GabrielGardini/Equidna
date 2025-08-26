//
//  CameraView.swift
//  Movies
//
//  Created by Camille Fernandes Luppi on 20/08/25.
//

import SwiftUI
import AVKit

struct CameraView: View {
    @State private var isShowingMediaPicker = false
    @State private var inputImage: UIImage?
    @State private var videoURL: URL?

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                
                if let inputImage = inputImage {
                    Image(uiImage: inputImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let videoURL = videoURL {
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 100))
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                Button {
                    self.inputImage = nil
                    self.videoURL = nil
                    self.isShowingMediaPicker = true
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Abrir Câmera")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("Camera")
            .fullScreenCover(isPresented: $isShowingMediaPicker) {
                MediaPicker(selectedImage: $inputImage, videoURL: $videoURL, sourceType: .camera)
                    .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    CameraView()
}
 
