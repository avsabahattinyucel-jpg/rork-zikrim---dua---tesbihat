import AVFoundation
import AudioToolbox
import Combine
import Foundation

@MainActor
final class NotificationSoundPreviewPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isPlaying = false

    private var player: AVAudioPlayer?

    func togglePreview(for selection: NotificationSoundSelection) {
        if isPlaying {
            stop()
        } else {
            play(selection: selection)
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func play(selection: NotificationSoundSelection) {
        stop()

        guard let fileName = NotificationSoundCatalog.previewFileName(for: selection) else {
            AudioServicesPlaySystemSound(1007)
            return
        }

        guard let fileURL = NotificationSoundCatalog.resourceURL(for: fileName) else {
            AudioServicesPlaySystemSound(1007)
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.delegate = self
            player.volume = 1
            player.numberOfLoops = 0
            player.prepareToPlay()
            player.play()

            self.player = player
            isPlaying = true
        } catch {
            AudioServicesPlaySystemSound(1007)
        }
    }
}
