//
//  AudioManager.swift
//  EquidnaApp
//
//  Created by Giovanna Spigariol on 19/09/25.
//

import Foundation
import AVFoundation

final class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    @Published private(set) var isRecording = false
    @Published private(set) var isPlaying = false
    @Published private(set) var lastRecordingURL: URL?
    @Published private(set) var lastRecordingDuration: TimeInterval = 0
    
    private var audioSession: AVAudioSession = .sharedInstance()
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var recordStartDate: Date?
    
    // MARK: - Permissão
    func requestMicPermission(_ completion: @escaping (Bool) -> Void) {
        switch audioSession.recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            audioSession.requestRecordPermission { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        @unknown default:
            completion(false)
        }
    }
    
    // MARK: - Gravação
    func startRecording(maxSeconds: TimeInterval = 60) {
        guard !isRecording else { return }
        requestMicPermission { [weak self] granted in
            guard let self = self, granted else { return }
            do {
                try self.audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                try self.audioSession.setActive(true)
                
                let url = try self.makeNewRecordingURL()
                let settings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 44_100,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                self.recorder = try AVAudioRecorder(url: url, settings: settings)
                self.recorder?.delegate = self
                self.recorder?.isMeteringEnabled = true
                self.recorder?.prepareToRecord()
                
                self.recordStartDate = Date()
                self.recorder?.record(forDuration: maxSeconds) // para sozinho depois de 1 min
                self.isRecording = true
                self.lastRecordingURL = url
            } catch {
                print("Erro ao iniciar gravação:", error)
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        recorder?.stop()
        if let start = recordStartDate {
            lastRecordingDuration = Date().timeIntervalSince(start)
        }
        isRecording = false
        recordStartDate = nil
        deactivateSessionIfNeeded()
    }
    
    // MARK: - Reprodução
    func playLast() {
        guard let url = lastRecordingURL else { return }
        play(url: url)
    }
    
    func play(url: URL) {
        guard !isPlaying else { return }
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
        } catch {
            print("Erro ao tocar:", error)
        }
    }
    
    func stopPlaying() {
        player?.stop()
        isPlaying = false
        deactivateSessionIfNeeded()
    }
    
    // MARK: - Helpers
    private func makeNewRecordingURL() throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let folder = base.appendingPathComponent("Recordings", isDirectory: true)
        if !fm.fileExists(atPath: folder.path) {
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        let filename = "rec_\(ISO8601DateFormatter().string(from: Date())).m4a"
        return folder.appendingPathComponent(filename)
    }
    
    private func deactivateSessionIfNeeded() {
        if !isRecording && !isPlaying {
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}

// MARK: - Delegates
extension AudioManager: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        if flag, let start = recordStartDate {
            lastRecordingDuration = Date().timeIntervalSince(start)
        }
        recordStartDate = nil
        deactivateSessionIfNeeded()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        deactivateSessionIfNeeded()
    }
}
