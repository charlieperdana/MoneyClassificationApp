//
//  AudioFeedbackService.swift
//  MoneyClassificationApp
//
//  Membungkus AVSpeechSynthesizer untuk umpan balik suara Bahasa Indonesia.
//

import Foundation
import AVFoundation

protocol AudioFeedbackServiceProtocol: AnyObject {
    func speak(_ text: String, interrupt: Bool)
    func stop()
}

final class AudioFeedbackService: NSObject, AudioFeedbackServiceProtocol {

    private let synthesizer = AVSpeechSynthesizer()
    private let voiceLanguage = "id-ID"

    override init() {
        super.init()
        configureAudioSession()
    }

    /// Mengonfigurasi AVAudioSession agar kompatibel dengan VoiceOver
    /// (menggunakan kategori playback dengan opsi mixWithOthers/duckOthers).
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback,
                                    mode: .spokenAudio,
                                    options: [.duckOthers, .mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            // Tidak fatal; log saja.
            print("AudioFeedbackService: gagal konfigurasi audio session: \(error)")
        }
    }

    func speak(_ text: String, interrupt: Bool = true) {
        guard !text.isEmpty else { return }

        if interrupt && synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguage)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
