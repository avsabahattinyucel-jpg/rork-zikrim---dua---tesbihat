import AVFoundation
import Foundation
import UserNotifications
import AudioToolbox

@Observable
@MainActor
class AdhanPlayerService {
    static let shared = AdhanPlayerService()

    var adhanEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "adhan_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "adhan_enabled") }
    }

    var volume: Float {
        get {
            let v = UserDefaults.standard.float(forKey: "adhan_volume")
            return v.isZero ? 0.8 : v
        }
        set { UserDefaults.standard.set(newValue, forKey: "adhan_volume") }
    }

    var isPlaying: Bool = false

    private var player: AVAudioPlayer?

    private init() {}

    private static let soundFileName = "ezan"
    private static let soundFileExtension = "wav"

    func play() {
        guard let url = Bundle.main.url(forResource: Self.soundFileName, withExtension: Self.soundFileExtension) else {
            AudioServicesPlaySystemSound(1007)
            return
        }
        do {
            let playInSilent = UserDefaults.standard.bool(forKey: "notification_play_in_silent")
            let category: AVAudioSession.Category = playInSilent ? .playback : .ambient
            try AVAudioSession.sharedInstance().setCategory(category, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            player?.stop()
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = volume
            player?.numberOfLoops = 0
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
        } catch {
            AudioServicesPlaySystemSound(1007)
        }
    }

    func preview() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func preload() {
        guard let url = Bundle.main.url(forResource: Self.soundFileName, withExtension: Self.soundFileExtension) else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
    }

    var notificationSoundName: UNNotificationSoundName {
        UNNotificationSoundName("\(Self.soundFileName).\(Self.soundFileExtension)")
    }
}
