import AVFoundation
import SwiftUI

struct LoopingVideoPlayerView: UIViewRepresentable {
    let resourceName: String
    let resourceExtension: String

    func makeCoordinator() -> Coordinator {
        Coordinator(resourceName: resourceName, resourceExtension: resourceExtension)
    }

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        context.coordinator.updateAttachment(to: uiView)
    }

    static func dismantleUIView(_ uiView: PlayerContainerView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    final class Coordinator {
        private let resourceName: String
        private let resourceExtension: String
        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?

        init(resourceName: String, resourceExtension: String) {
            self.resourceName = resourceName
            self.resourceExtension = resourceExtension
        }

        func attach(to view: PlayerContainerView) {
            guard player == nil else {
                updateAttachment(to: view)
                return
            }

            guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension) else {
                return
            }

            let item = AVPlayerItem(url: url)
            let queuePlayer = AVQueuePlayer()
            queuePlayer.isMuted = true
            queuePlayer.actionAtItemEnd = .none
            queuePlayer.preventsDisplaySleepDuringVideoPlayback = false

            looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
            player = queuePlayer

            view.playerLayer.player = queuePlayer
            queuePlayer.play()
        }

        func updateAttachment(to view: PlayerContainerView) {
            view.playerLayer.player = player
            player?.isMuted = true
            player?.play()
        }

        func teardown() {
            player?.pause()
            looper?.disableLooping()
            looper = nil
            player = nil
        }
    }
}

final class PlayerContainerView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        guard let layer = layer as? AVPlayerLayer else {
            fatalError("Expected AVPlayerLayer")
        }
        return layer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        playerLayer.videoGravity = .resizeAspectFill
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
