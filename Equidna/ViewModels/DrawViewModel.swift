import SwiftUI
import PencilKit

@MainActor
final class DrawViewModel: NSObject, ObservableObject, PKCanvasViewDelegate {
    @Published var drawing = PKDrawing()
    @Published var canUndo = false
    @Published var canRedo = false
    @Published var isEmpty = true

    private(set) var canvas: PKCanvasView?
    private var toolPicker: PKToolPicker?

    let defaultTool: PKInkingTool = PKInkingTool(.pen, color: .black, width: 6)

    func attach(canvas: PKCanvasView) {
        self.canvas = canvas
        canvas.drawing = drawing
        canvas.alwaysBounceVertical = false
        canvas.tool = defaultTool
        canvas.delegate = self

        ensureToolPicker()
        updateFlags()
    }

    func ensureToolPicker() {
        guard let canvas else { return }
        UserDefaults.standard.register(defaults: ["PKPaletteNamedDefaults": [:]])

        guard let _ = canvas.window ?? canvas.superview?.window else {
            DispatchQueue.main.async { [weak self] in self?.ensureToolPicker() }
            return
        }

        let picker = toolPicker ?? PKToolPicker()
        toolPicker = picker
        picker.setVisible(true, forFirstResponder: canvas)
        picker.addObserver(canvas)
        canvas.becomeFirstResponder()
    }

    func setToolPickerVisible(_ visible: Bool) {
        guard let canvas, let picker = toolPicker else {
            ensureToolPicker()
            return
        }
        picker.setVisible(visible, forFirstResponder: canvas)
        if visible { canvas.becomeFirstResponder() }
    }

    func clear() {
        drawing = PKDrawing()
        canvas?.drawing = drawing
        updateFlags()
    }

    func undo() { canvas?.undoManager?.undo(); syncFromCanvas() }
    func redo() { canvas?.undoManager?.redo(); syncFromCanvas() }

    func renderImage(scale: CGFloat = UIScreen.main.scale,
                     background: UIColor = .systemBackground) -> UIImage? {
        guard let canvas else { return nil }
        let bounds = canvas.bounds
        let image = drawing.image(from: bounds, scale: scale)
        let renderer = UIGraphicsImageRenderer(size: image.size)
        let final = renderer.image { ctx in
            background.setFill()
            ctx.fill(CGRect(origin: .zero, size: image.size))
            image.draw(at: .zero)
        }
        return final
    }

    // PKCanvasViewDelegate
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        syncFromCanvas()
    }

    // MARK: - Helpers
    private func syncFromCanvas() {
        guard let canvas else { return }
        drawing = canvas.drawing
        updateFlags()
    }

    private func updateFlags() {
        canUndo = canvas?.undoManager?.canUndo ?? false
        canRedo = canvas?.undoManager?.canRedo ?? false
        isEmpty = drawing.strokes.isEmpty
    }
}

