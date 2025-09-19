//
//  audioView.swift
//  EquidnaApp
//
//  Created by Giovanna Spigariol on 17/09/25.
//

import SwiftUI
import AVFoundation

struct AudioRecorderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audio = AudioManager.shared

    let onFinish: (URL, TimeInterval) -> Void

    @State private var showDiscard = false
    @State private var timerText = "00:00"
    @State private var tick: Timer?

    var body: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top
            let bottomInset = geo.safeAreaInsets.bottom

            VStack(spacing: 0) {

                // CABEÇALHO — respeita o notch
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gravador").font(.largeTitle).bold()
                    Text("Grave um audio de até um minuto")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, topInset + 8)

                // MIOL0 — centralizado
                Spacer(minLength: 0)

                VStack(spacing: 24) {
                    Text(timerText)
                        .font(.title3)
                        .monospacedDigit()

                    Image(systemName: "waveform")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .foregroundColor(.primary.opacity(0.9))
                        .padding(.vertical, 8)

                    Button(action: centralAction) {
                        ZStack {
                            Circle().strokeBorder(.primary.opacity(0.15), lineWidth: 4)
                                .frame(width: 72, height: 72)
                            if audio.isRecording {
                                RoundedRectangle(cornerRadius: 6).fill(Color.red)
                                    .frame(width: 28, height: 28)
                            } else if audio.isPlaying {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(22)
                                    .background(Circle().fill(Color.blue))
                            } else if audio.lastRecordingURL != nil {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(22)
                                    .background(Circle().fill(Color.blue))
                            } else {
                                Circle().fill(Color.red).frame(width: 44, height: 44)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // RODAPÉ — ancorado acima do home indicator
            .safeAreaInset(edge: .bottom) {
                HStack {
                    if audio.lastRecordingURL == nil {
                        Button("Cancelar") { dismiss() }
                    } else {
                        Button("Repetir") { showDiscard = true }
                            .foregroundColor(.blue)
                            .alert("Deseja descartar o registro?", isPresented: $showDiscard) {
                                Button("Cancelar", role: .cancel) {}
                                Button("Descartar", role: .destructive) { discard() }
                            }
                    }
                    Spacer()
                    Button("Enviar") {
                        if let url = audio.lastRecordingURL {
                            onFinish(url, audio.lastRecordingDuration)
                        }
                    }
                    .disabled(audio.lastRecordingURL == nil)
                }
                .padding(.horizontal)
                .padding(.bottom, max(bottomInset, 12))
                // opcional: fundo leve
                // .background(.ultraThinMaterial)
            }
        }
        .ignoresSafeArea(.keyboard) // só o teclado pode “invadir”
        .onAppear { AudioManager.shared.requestMicPermission { _ in } }
    }

    private func centralAction() {
        if audio.isRecording {
            audio.stopRecording(); updateTimer(0)
        } else if audio.lastRecordingURL != nil {
            audio.isPlaying ? audio.stopPlaying() : audio.playLast()
        } else {
            audio.startRecording(maxSeconds: 60); startTick()
        }
    }

    private func discard() {
        if let url = audio.lastRecordingURL { try? FileManager.default.removeItem(at: url) }
        audio.stopPlaying(); audio.stopRecording()
        AudioManager.shared.setValue(nil, forKey: "lastRecordingURL")
        AudioManager.shared.setValue(0, forKey: "lastRecordingDuration")
        updateTimer(0)
    }

    private func startTick() {
        tick?.invalidate()
        tick = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            updateTimer(audio.lastRecordingDuration)
        }
    }
    private func updateTimer(_ seconds: TimeInterval) {
        let t = Int(seconds)
        timerText = String(format: "%02d:%02d", t/60, t%60)
        if !audio.isRecording { tick?.invalidate(); tick = nil }
    }
}
