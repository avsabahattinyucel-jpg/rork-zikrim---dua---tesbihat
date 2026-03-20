import Foundation
import WatchConnectivity

@MainActor
final class WatchConnectivityService: NSObject {
    static let shared = WatchConnectivityService()

    private let payloadKey = "watch_sync_payload"
    private let actionKey = "watch_counter_action"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private weak var storage: StorageService?

    private override init() {
        super.init()
    }

    func connect(storage: StorageService) {
        self.storage = storage
        activateSessionIfNeeded()
        syncNow()
    }

    func syncNow() {
        guard WCSession.isSupported(), let payloadData = makePayloadData() else { return }

        let session = WCSession.default
        do {
            try session.updateApplicationContext([payloadKey: payloadData])
        } catch {
            #if DEBUG
            print("[WatchSync] Failed to update application context: \(error.localizedDescription)")
            #endif
        }
    }

    private func activateSessionIfNeeded() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        session.delegate = self
        if session.activationState == .notActivated {
            session.activate()
        }
    }

    private func makePayloadData() -> Data? {
        guard let payload = buildPayload() else { return nil }
        return try? encoder.encode(payload)
    }

    private func buildPayload() -> WatchSyncPayload? {
        guard let storage else { return nil }

        let selectedCounter = storage.selectedCounter
        let selectedSession = selectedCounter.map { storage.resolvedSession(for: $0) }
        let options = storage.counters.map { counter in
            let optionSession = storage.session(for: counter)
            let subtitle = optionSession?.zikrTitle ?? counter.name
            return WatchCounterOption(id: counter.id, title: counter.name, subtitle: subtitle)
        }

        let selectedSnapshot = selectedCounter.map { counter in
            WatchCounterSnapshot(
                id: counter.id,
                title: selectedSession?.zikrTitle ?? counter.name,
                subtitle: counter.isMultiStep
                    ? (counter.currentStep?.name ?? counter.name)
                    : (selectedSession?.meaning ?? ""),
                arabicText: selectedSession?.arabicText ?? "",
                transliteration: selectedSession?.transliteration ?? "",
                meaning: selectedSession?.meaning ?? "",
                currentCount: counter.currentCount,
                targetCount: counter.currentStepTarget,
                stepName: counter.currentStep?.name,
                stepProgressText: counter.isMultiStep
                    ? L10n.format(.counterStepProgressFormat, counter.currentStepIndex + 1, counter.steps.count, counter.currentCount, counter.currentStepTarget)
                    : L10n.format(.countFractionFormat, Int64(counter.currentCount), Int64(counter.targetCount)),
                overallProgress: counter.isMultiStep ? counter.overallProgress : counter.progress
            )
        }

        return WatchSyncPayload(
            generatedAt: Date(),
            isReachable: WCSession.default.isReachable,
            dailyCount: storage.todayStats().totalCount,
            dailyGoal: storage.profile.dailyGoal,
            streak: storage.profile.currentStreak,
            counters: options,
            selectedCounter: selectedSnapshot
        )
    }

    private func handleAction(_ action: WatchCounterAction) -> Data? {
        guard let storage else { return makePayloadData() }

        switch action.kind {
        case .increment:
            if let result = DhikrCounterMutator.increment(counterID: action.counterID, storage: storage) {
                storage.setActiveSession(from: result.updatedCounter)
            }
        case .undo:
            if let result = DhikrCounterMutator.undo(counterID: action.counterID, storage: storage) {
                storage.setActiveSession(from: result.updatedCounter)
            }
        case .reset:
            if let result = DhikrCounterMutator.reset(counterID: action.counterID, storage: storage) {
                storage.setActiveSession(from: result.updatedCounter)
            }
        case .selectCounter:
            storage.selectCounter(id: action.counterID)
            if let selectedCounter = storage.selectedCounter {
                storage.setActiveSession(from: selectedCounter)
            } else {
                storage.setActiveZikrSession(nil)
            }
        }

        syncNow()
        return makePayloadData()
    }
}

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error {
                #if DEBUG
                print("[WatchSync] Activation failed: \(error.localizedDescription)")
                #endif
            } else {
                syncNow()
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        Task { @MainActor in
            guard let action = try? decoder.decode(WatchCounterAction.self, from: messageData) else { return }
            _ = handleAction(action)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        Task { @MainActor in
            guard let action = try? decoder.decode(WatchCounterAction.self, from: messageData) else {
                replyHandler(Data())
                return
            }
            replyHandler(handleAction(action) ?? Data())
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        Task { @MainActor in
            guard let data = userInfo[actionKey] as? Data,
                  let action = try? decoder.decode(WatchCounterAction.self, from: data) else { return }
            _ = handleAction(action)
        }
    }
}
