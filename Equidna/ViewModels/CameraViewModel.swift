//
//  CameraViewModel.swift
//  Movies
//
//  Created by Camille Fernandes Luppi on 20/08/25.
//

import SwiftUI
import UIKit
import AVKit
import UniformTypeIdentifiers

struct MediaPicker: UIViewControllerRepresentable {

    @Binding var selectedImage: UIImage?
    @Binding var videoURL: URL?
    @Environment(\.presentationMode) private var presentationMode

    var sourceType: UIImagePickerController.SourceType = .camera
    
    var videoTimeLimit: TimeInterval = 30.0

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let mediaPicker = UIImagePickerController()
        mediaPicker.sourceType = sourceType
        
        mediaPicker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]

        mediaPicker.delegate = context.coordinator
        return mediaPicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: MediaPicker

        init(_ parent: MediaPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.videoURL = nil
            }
            else if let url = info[.mediaURL] as? URL {
                parent.videoURL = url
                parent.selectedImage = nil
            }

            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
