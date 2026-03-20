import AVFoundation
import Foundation

@Observable
@MainActor
final class KhutbahSummaryNarrationService: NSObject, AVSpeechSynthesizerDelegate {
    var isSpeaking: Bool = false
    var lastErrorMessage: String?

    private let synthesizer = AVSpeechSynthesizer()
    private let audioSessionManager = AudioSessionManager()
    private var activeText: String?
    private var shouldSkipAudioSessionPreparation = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func togglePlayback(text: String, languageCode: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if isSpeaking, activeText == trimmed {
            stop()
            return
        }

        stop()
        lastErrorMessage = nil
        prepareAudioSessionIfPossible()

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = preferredVoice(for: languageCode)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.88
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.08
        utterance.postUtteranceDelay = 0.05
        utterance.volume = 1.0

        activeText = trimmed
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        activeText = nil
        isSpeaking = false
        audioSessionManager.deactivate()
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.lastErrorMessage = nil
            self.isSpeaking = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.activeText = nil
            self.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.activeText = nil
            self.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }

    private func preferredVoice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        let normalized = RabiaAppLanguage.normalizedCode(for: languageCode)
        let identifier = switch normalized {
        case "tr": "tr-TR"
        case "ar": "ar-SA"
        case "de": "de-DE"
        case "fr": "fr-FR"
        case "es": "es-ES"
        case "id": "id-ID"
        case "ms": "ms-MY"
        case "ru": "ru-RU"
        case "fa": "fa-IR"
        case "ur": "ur-PK"
        default: "en-US"
        }

        return AVSpeechSynthesisVoice(language: identifier)
            ?? AVSpeechSynthesisVoice(language: normalized)
            ?? AVSpeechSynthesisVoice(language: "tr-TR")
            ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    private func prepareAudioSessionIfPossible() {
        guard !shouldSkipAudioSessionPreparation else { return }

        do {
            try audioSessionManager.configureForPlayback(allowsBackgroundPlayback: true)
            try audioSessionManager.activate()
        } catch {
            shouldSkipAudioSessionPreparation = true
            lastErrorMessage = error.localizedDescription
#if DEBUG
            print("[KhutbahTTS] session_warning error=\(error.localizedDescription)")
#endif
        }
    }
}
