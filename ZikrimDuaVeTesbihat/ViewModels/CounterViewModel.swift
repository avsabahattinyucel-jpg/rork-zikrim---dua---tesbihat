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
    var hapticTrigger: Int = 0
    var showCompletionCard: Bool = false
    var completedCounter: CounterModel?

    init(storage: StorageService) {
        self.storage = storage
        if let first = storage.counters.first {
            self.selectedCounter = first
        }
    }

    func createCounter(name: String, target: Int, zikirItemId: String? = nil) {
        let counter = CounterModel(name: name, targetCount: target, zikirItemId: zikirItemId)
        storage.addCounter(counter)
        selectedCounter = counter
    }

    func increment() {
        guard var counter = selectedCounter else { return }
        guard counter.currentCount < counter.targetCount else { return }
        counter.currentCount += 1
        counter.lastUpdated = Date()
        if counter.currentCount >= counter.targetCount {
            counter.isCompleted = true
            storage.completeSession()
            completedCounter = counter
            showCompletionCard = true
        }
        storage.updateCounter(counter)
        storage.addZikirCount(1, zikirName: counter.name)
        selectedCounter = counter

        if storage.profile.vibrationEnabled {
            hapticTrigger += 1
            let impact = UIImpactFeedbackGenerator(style: counter.progress > 0.9 ? .rigid : (counter.progress > 0.6 ? .medium : .light))
            impact.prepare()
            impact.impactOccurred(intensity: CGFloat(min(max(counter.progress, 0.25), 1.0)))
        }
        if storage.profile.soundEnabled {
            AudioServicesPlaySystemSound(1104)
        }
    }

    func undo() {
        guard var counter = selectedCounter, counter.currentCount > 0 else { return }
        counter.currentCount -= 1
        counter.isCompleted = false
        counter.lastUpdated = Date()
        storage.updateCounter(counter)
        storage.addZikirCount(-1, zikirName: counter.name)
        selectedCounter = counter
    }

    func reset() {
        guard var counter = selectedCounter else { return }
        let diff = counter.currentCount
        counter.currentCount = 0
        counter.isCompleted = false
        counter.lastUpdated = Date()
        storage.updateCounter(counter)
        if diff > 0 {
            storage.addZikirCount(-diff, zikirName: counter.name)
        }
        selectedCounter = counter
    }

    func deleteSelected() {
        guard let counter = selectedCounter else { return }
        storage.deleteCounter(counter)
        selectedCounter = storage.counters.first
    }

    func selectCounter(_ counter: CounterModel) {
        selectedCounter = counter
    }

    func refreshSelected() {
        guard let id = selectedCounter?.id else { return }
        selectedCounter = storage.counters.first(where: { $0.id == id })
    }

    func repeatCounter() {
        guard var counter = selectedCounter else { return }
        counter.currentCount = 0
        counter.isCompleted = false
        counter.lastUpdated = Date()
        storage.updateCounter(counter)
        selectedCounter = counter
        showCompletionCard = false
    }

    func nextCounter() {
        guard let current = selectedCounter,
              let index = storage.counters.firstIndex(where: { $0.id == current.id }) else {
            showCompletionCard = false
            return
        }
        let nextIndex = (index + 1) % storage.counters.count
        selectedCounter = storage.counters[nextIndex]
        showCompletionCard = false
    }

    func dismissCompletion() {
        showCompletionCard = false
    }
}
