//
//  PencilCanvasView.swift
//  Equidna
//
//  Created by Rodrigo Cont on 26/09/25.
//
import SwiftUI
import PencilKit

struct PencilCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let onReady: (PKCanvasView) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .systemBackground
        canvas.isOpaque = true
        canvas.drawing = drawing
      
        // Nao define delegate
    
        DispatchQueue.main.async { onReady(canvas) }
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }
}
