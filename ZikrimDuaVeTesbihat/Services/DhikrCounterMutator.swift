import Foundation

struct DhikrCounterMutationResult: Sendable {
    let updatedCounter: CounterModel
    let completedCounter: CounterModel?
    let deltaCount: Int
}

@MainActor
enum DhikrCounterMutator {
    static func increment(counterID: String? = nil, storage: StorageService) -> DhikrCounterMutationResult? {
        guard var counter = resolveCounter(counterID: counterID, storage: storage) else { return nil }
        let session = storage.resolvedSession(for: counter)

        let stepTarget = counter.currentStepTarget
        let isUnlimitedCounter = !counter.isMultiStep && stepTarget <= 0
        if !isUnlimitedCounter {
            guard counter.currentCount < stepTarget else { return nil }
        }

        counter.currentCount += 1
        counter.lastUpdated = Date()

        let stepName = counter.currentStep?.name ?? counter.name
        var completedCounter: CounterModel?

        if !isUnlimitedCounter && counter.currentCount >= stepTarget {
            if counter.isMultiStep && counter.currentStepIndex < counter.steps.count - 1 {
                counter.currentStepIndex += 1
                counter.currentCount = 0
                counter.targetCount = counter.steps[counter.currentStepIndex].targetCount
            } else {
                var finishedCounter = counter
                finishedCounter.isCompleted = true

                storage.completeSession()
                DhikrStreakService.shared.recordDhikrSession()
                NotificationService().recordCompletionCelebrationNotification()
                completedCounter = finishedCounter

                counter.currentCount = 0
                counter.isCompleted = false
                if counter.isMultiStep {
                    counter.currentStepIndex = 0
                    counter.targetCount = counter.steps.first?.targetCount ?? counter.targetCount
                }
            }
        }

        storage.updateCounter(counter)
        storage.addZikirCount(1, zikirName: stepName, session: session)
        storage.selectCounter(id: counter.id)

        if completedCounter != nil {
            Task {
                await CloudSyncService.shared.saveDhikrCount(storage: storage)
            }
        }

        return DhikrCounterMutationResult(
            updatedCounter: counter,
            completedCounter: completedCounter,
            deltaCount: 1
        )
    }

    static func undo(counterID: String? = nil, storage: StorageService) -> DhikrCounterMutationResult? {
        guard var counter = resolveCounter(counterID: counterID, storage: storage) else { return nil }
        let session = storage.resolvedSession(for: counter)

        if counter.currentCount > 0 {
            counter.currentCount -= 1
            counter.isCompleted = false
            counter.lastUpdated = Date()
            let stepName = counter.currentStep?.name ?? counter.name
            storage.updateCounter(counter)
            storage.addZikirCount(-1, zikirName: stepName, session: session)
            storage.selectCounter(id: counter.id)
            return DhikrCounterMutationResult(updatedCounter: counter, completedCounter: nil, deltaCount: -1)
        }

        guard counter.isMultiStep, counter.currentStepIndex > 0 else { return nil }

        counter.currentStepIndex -= 1
        let previousStep = counter.steps[counter.currentStepIndex]
        counter.currentCount = previousStep.targetCount - 1
        counter.targetCount = previousStep.targetCount
        counter.isCompleted = false
        counter.lastUpdated = Date()
        storage.updateCounter(counter)
        storage.addZikirCount(-1, zikirName: previousStep.name, session: session)
        storage.selectCounter(id: counter.id)
        return DhikrCounterMutationResult(updatedCounter: counter, completedCounter: nil, deltaCount: -1)
    }

    static func reset(counterID: String? = nil, storage: StorageService) -> DhikrCounterMutationResult? {
        guard var counter = resolveCounter(counterID: counterID, storage: storage) else { return nil }
        let session = storage.resolvedSession(for: counter)

        let diff = counter.totalStepsCompleted
        guard diff > 0 else { return nil }

        counter.currentCount = 0
        counter.isCompleted = false
        counter.lastUpdated = Date()
        if counter.isMultiStep {
            counter.currentStepIndex = 0
            counter.targetCount = counter.steps.first?.targetCount ?? counter.targetCount
        }

        storage.updateCounter(counter)
        storage.addZikirCount(-diff, zikirName: counter.name, session: session)
        storage.selectCounter(id: counter.id)

        return DhikrCounterMutationResult(updatedCounter: counter, completedCounter: nil, deltaCount: -diff)
    }

    private static func resolveCounter(counterID: String?, storage: StorageService) -> CounterModel? {
        if let counterID {
            return storage.counters.first(where: { $0.id == counterID })
        }
        return storage.selectedCounter
    }
}
