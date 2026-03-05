import Foundation
import AVFoundation

nonisolated struct GroqTTSRequest: Encodable, Sendable {
    let model: String
    let input: String
    let voice: String
    let response_format: String
}

@Observable
@MainActor
final class GroqTTSService {
    var isLoading: Bool = false
    var isPlaying: Bool = false
    var errorMessage: String? = nil

    private var audioPlayer: AVAudioPlayer? = nil
    private var currentTask: Task<Void, Never>? = nil

    private let apiKey = Config.GROQ_API_KEY
    private let endpoint = "https://api.groq.com/openai/v1/audio/speech"
    private let model = "playai-tts"
    private let voice = "Fritz-PlayAI"
    private let maxInputLength = 4000

    func toggle(text: String) {
        if isPlaying {
            stop()
            return
        }

        if isLoading {
            currentTask?.cancel()
            currentTask = nil
            isLoading = false
            return
        }

        currentTask = Task {
            await generateAndPlay(text: text)
        }
    }

    func stop() {
        currentTask?.cancel()
        currentTask = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        isLoading = false
    }

    private func generateAndPlay(text: String) async {
        isLoading = true
        errorMessage = nil
        defer {
            if !isPlaying {
                isLoading = false
            }
        }

        let truncated = String(text.prefix(maxInputLength))

        guard let url = URL(string: endpoint) else {
            errorMessage = "Geçersiz URL"
            return
        }

        let body = GroqTTSRequest(
            model: model,
            input: truncated,
            voice: voice,
            response_format: "wav"
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            errorMessage = "İstek oluşturulamadı"
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if Task.isCancelled { return }

            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let bodyStr = String(data: data, encoding: .utf8) ?? ""
                print("[GroqTTS] HTTP \(http.statusCode): \(bodyStr.prefix(300))")
                errorMessage = "Ses oluşturulamadı (HTTP \(http.statusCode))"
                return
            }

            guard !data.isEmpty else {
                errorMessage = "Boş ses verisi"
                return
            }

            try configureAudioSession()

            let player = try AVAudioPlayer(data: data)
            player.prepareToPlay()
            audioPlayer = player
            isLoading = false
            isPlaying = true
            player.play()

            await waitForPlaybackEnd(player: player)

        } catch is CancellationError {
            return
        } catch {
            if !Task.isCancelled {
                errorMessage = "Ses yüklenemedi: \(error.localizedDescription)"
                print("[GroqTTS] Error: \(error)")
            }
        }
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
    }

    private func waitForPlaybackEnd(player: AVAudioPlayer) async {
        while player.isPlaying && !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(300))
        }
        if !Task.isCancelled {
            isPlaying = false
            audioPlayer = nil
        }
    }
}
