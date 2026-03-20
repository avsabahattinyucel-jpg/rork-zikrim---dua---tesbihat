import SwiftUI
import AudioToolbox
import UIKit

@Observable
@MainActor
class CounterViewModel {
    let storage: StorageService
    var selectedCounter: CounterModel?
    var showNewCounterSheet: Bool = false
    var showTargetPicker: Bool = false
    var showCompletionCard: Bool = false
    var completedCounter: CounterModel?
    var milestoneTrigger: Int = 0
    var lastMilestoneValue: Int?
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let successNotification = UINotificationFeedbackGenerator()

    init(storage: StorageService) {
        self.storage = storage
        self.selectedCounter = storage.selectedCounter
        prepareFeedbackGenerators()
    }

    func createCounter(
        name: String,
        target: Int,
        zikirItemId: String? = nil,
        sessionSnapshot: ZikrSession? = nil
    ) {
        let counter = CounterModel(
            name: name,
            targetCount: target,
            zikirItemId: zikirItemId,
            sessionSnapshot: sessionSnapshot
        )
        storage.addCounter(counter)
        storage.selectCounter(id: counter.id)
        selectedCounter = storage.selectedCounter
    }

    func createMultiStepCounter(name: String, steps: [DhikrStep], zikirItemId: String? = nil) {
        let firstTarget = steps.first?.targetCount ?? 33
        let counter = CounterModel(name: name, targetCount: firstTarget, zikirItemId: zikirItemId, steps: steps, currentStepIndex: 0)
        storage.addCounter(counter)
        storage.selectCounter(id: counter.id)
        selectedCounter = storage.selectedCounter
    }

    func increment() {
        guard let result = DhikrCounterMutator.increment(storage: storage) else { return }
        let counter = result.updatedCounter
        selectedCounter = counter

        let milestoneValue = result.completedCounter?.totalStepsCompleted ?? counter.totalStepsCompleted
        if [33, 99, 100].contains(milestoneValue) {
            lastMilestoneValue = milestoneValue
            milestoneTrigger += 1
        }

        if storage.profile.vibrationEnabled {
            let progress = counter.isFreeMode ? 0.55 : (counter.isMultiStep ? counter.overallProgress : counter.progress)
            let impact = progress > 0.9 ? rigidImpact : (progress > 0.6 ? mediumImpact : lightImpact)
            impact.impactOccurred(intensity: CGFloat(min(max(progress, 0.25), 1.0)))
            impact.prepare()

            if result.completedCounter != nil || lastMilestoneValue == milestoneValue {
                successNotification.notificationOccurred(.success)
                successNotification.prepare()
            }
        }
        if storage.profile.soundEnabled {
            AudioServicesPlaySystemSound(1104)
        }

        if let completed = result.completedCounter {
            completedCounter = completed
            showCompletionCard = true
        }
    }

    func undo() {
        guard let result = DhikrCounterMutator.undo(storage: storage) else { return }
        selectedCounter = result.updatedCounter
    }

    func reset() {
        guard let result = DhikrCounterMutator.reset(storage: storage) else { return }
        selectedCounter = result.updatedCounter
    }

    func deleteSelected() {
        guard let counter = selectedCounter else { return }
        storage.deleteCounter(counter)
        selectedCounter = storage.selectedCounter
    }

    func selectCounter(_ counter: CounterModel) {
        storage.selectCounter(id: counter.id)
        selectedCounter = storage.selectedCounter
    }

    func refreshSelected() {
        selectedCounter = storage.selectedCounter
    }

    func dismissCompletion() {
        completedCounter = nil
        showCompletionCard = false
        refreshSelected()
    }

    private func prepareFeedbackGenerators() {
        lightImpact.prepare()
        mediumImpact.prepare()
        rigidImpact.prepare()
        successNotification.prepare()
    }
}
