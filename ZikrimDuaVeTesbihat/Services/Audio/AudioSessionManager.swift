import AVFoundation
import Foundation

nonisolated final class AudioSessionManager {
    typealias InterruptionHandler = (_ type: AVAudioSession.InterruptionType, _ shouldResume: Bool) -> Void
    typealias RouteChangeHandler = (_ reason: AVAudioSession.RouteChangeReason) -> Void

    private let session: AVAudioSession
    private var observerTokens: [NSObjectProtocol] = []

    init(session: AVAudioSession = .sharedInstance()) {
        self.session = session
    }

    func configureForPlayback(allowsBackgroundPlayback: Bool) throws {
        try session.setCategory(
            allowsBackgroundPlayback ? .playback : .ambient,
            mode: .default,
            options: [.allowAirPlay]
        )
    }

    func activate() throws {
        try session.setActive(true)
    }

    func deactivate() {
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
    }

    func startObserving(
        onInterruption: @escaping InterruptionHandler,
        onRouteChange: @escaping RouteChangeHandler
    ) {
        stopObserving()

        let center = NotificationCenter.default

        let interruptionToken = center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: .main
        ) { notification in
            guard
                let userInfo = notification.userInfo,
                let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                let type = AVAudioSession.InterruptionType(rawValue: rawType)
            else {
                return
            }

            let rawOptions = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            onInterruption(type, options.contains(.shouldResume))
        }

        let routeChangeToken = center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: session,
            queue: .main
        ) { notification in
            guard
                let userInfo = notification.userInfo,
                let rawReason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason)
            else {
                return
            }

            onRouteChange(reason)
        }

        observerTokens = [interruptionToken, routeChangeToken]
    }

    func stopObserving() {
        observerTokens.forEach(NotificationCenter.default.removeObserver)
        observerTokens.removeAll()
    }

    deinit {
        stopObserving()
    }
}
