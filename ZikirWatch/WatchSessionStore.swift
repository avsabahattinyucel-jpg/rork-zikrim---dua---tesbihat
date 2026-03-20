import Foundation
import Observation
import WatchConnectivity

@MainActor
@Observable
final class WatchSessionStore: NSObject {
    var payload = WatchSyncPayload(
        generatedAt: .now,
        isReachable: false,
        dailyCount: 0,
        dailyGoal: 0,
        streak: 0,
        counters: [],
        selectedCounter: nil
    )
    var connectionStatus = "iPhone ile baglanti bekleniyor"
    var isSyncing = false

    private let payloadKey = "watch_sync_payload"
    private let actionKey = "watch_counter_action"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    override init() {
        super.init()
        activate()
    }

    func activate() {
        guard WCSession.isSupported() else {
            connectionStatus = "WatchConnectivity desteklenmiyor"
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        applyCachedContext(from: session)
        updateConnectionStatus(isReachable: session.isReachable)
    }

    func increment() {
        send(.increment, counterID: payload.selectedCounter?.id, shouldApplyOptimisticUpdate: true)
    }

    func undo() {
        send(.undo, counterID: payload.selectedCounter?.id)
    }

    func reset() {
        send(.reset, counterID: payload.selectedCounter?.id)
    }

    func selectCounter(id: String) {
        send(.selectCounter, counterID: id)
    }

    private func send(
        _ kind: WatchCounterActionKind,
        counterID: String? = nil,
        shouldApplyOptimisticUpdate: Bool = false
    ) {
        guard WCSession.isSupported() else { return }
        let action = WatchCounterAction(kind: kind, counterID: counterID)
        guard let data = try? encoder.encode(action) else { return }

        let session = WCSession.default
        if shouldApplyOptimisticUpdate {
            applyOptimisticUpdate(for: action)
        }
        isSyncing = true

        if session.isReachable {
            session.sendMessageData(data, replyHandler: { [weak self] responseData in
                Task { @MainActor in
                    self?.isSyncing = false
                    self?.applyPayload(from: responseData)
                    self?.updateConnectionStatus(isReachable: true)
                }
            }, errorHandler: { [weak self] _ in
                Task { @MainActor in
                    self?.isSyncing = false
                    self?.queueAction(data, session: session)
                }
            })
            return
        }

        queueAction(data, session: session)
    }

    private func queueAction(_ data: Data, session: WCSession) {
        session.transferUserInfo([actionKey: data])
        isSyncing = false
        connectionStatus = "iPhone uyaninca islem siraya alinmis olacak"
    }

    private func applyCachedContext(from session: WCSession) {
        guard let data = session.receivedApplicationContext[payloadKey] as? Data else { return }
        applyPayload(from: data)
    }

    private func applyOptimisticUpdate(for action: WatchCounterAction) {
        guard action.kind == .increment,
              let counter = payload.selectedCounter,
              action.counterID == nil || action.counterID == counter.id,
              counter.currentCount < counter.targetCount else {
            return
        }

        let updatedCounter = WatchCounterSnapshot(
            id: counter.id,
            title: counter.title,
            subtitle: counter.subtitle,
            arabicText: counter.arabicText,
            transliteration: counter.transliteration,
            meaning: counter.meaning,
            currentCount: counter.currentCount + 1,
            targetCount: counter.targetCount,
            stepName: counter.stepName,
            stepProgressText: counter.stepProgressText,
            overallProgress: counter.overallProgress
        )

        payload = WatchSyncPayload(
            generatedAt: .now,
            isReachable: payload.isReachable,
            dailyCount: payload.dailyCount + 1,
            dailyGoal: payload.dailyGoal,
            streak: payload.streak,
            counters: payload.counters,
            selectedCounter: updatedCounter
        )
    }

    private func applyPayload(from data: Data) {
        guard let decoded = try? decoder.decode(WatchSyncPayload.self, from: data) else { return }
        payload = decoded
        updateConnectionStatus(isReachable: WCSession.default.isReachable || decoded.isReachable)
    }

    private func updateConnectionStatus(isReachable: Bool) {
        if payload.selectedCounter == nil {
            connectionStatus = payload.counters.isEmpty
                ? "iPhone uygulamasinda bir tesbih olustur"
                : "Saatten takip etmek icin bir sayaç sec"
        } else if isReachable {
            connectionStatus = "iPhone ile senkronize"
        } else {
            connectionStatus = "Son durum goruntuleniyor"
        }
    }
}

extension WatchSessionStore: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            updateConnectionStatus(isReachable: session.isReachable)
            applyCachedContext(from: session)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            updateConnectionStatus(isReachable: session.isReachable)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            guard let data = applicationContext[payloadKey] as? Data else { return }
            applyPayload(from: data)
        }
    }
}
