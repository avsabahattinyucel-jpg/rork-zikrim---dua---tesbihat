import Foundation

nonisolated struct CounterModel: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var targetCount: Int
    var currentCount: Int
    var zikirItemId: String?
    var sessionSnapshot: ZikrSession?
    var createdAt: Date
    var lastUpdated: Date
    var isCompleted: Bool
    var steps: [DhikrStep]
    var currentStepIndex: Int

    var isMultiStep: Bool {
        steps.count > 1
    }

    var isFreeMode: Bool {
        !isMultiStep && targetCount <= 0
    }

    var currentStep: DhikrStep? {
        guard isMultiStep, currentStepIndex >= 0, currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    var currentStepTarget: Int {
        currentStep?.targetCount ?? targetCount
    }

    var progress: Double {
        guard currentStepTarget > 0 else { return 0 }
        return min(Double(currentCount) / Double(currentStepTarget), 1.0)
    }

    var totalStepsTarget: Int {
        guard isMultiStep else { return targetCount }
        return steps.reduce(0) { $0 + $1.targetCount }
    }

    var totalStepsCompleted: Int {
        guard isMultiStep else { return currentCount }
        var total = 0
        for i in 0..<currentStepIndex {
            total += steps[i].targetCount
        }
        total += currentCount
        return total
    }

    var overallProgress: Double {
        guard totalStepsTarget > 0 else { return 0 }
        return min(Double(totalStepsCompleted) / Double(totalStepsTarget), 1.0)
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        targetCount: Int = 33,
        currentCount: Int = 0,
        zikirItemId: String? = nil,
        sessionSnapshot: ZikrSession? = nil,
        steps: [DhikrStep] = [],
        currentStepIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.targetCount = targetCount
        self.currentCount = currentCount
        self.zikirItemId = zikirItemId
        self.sessionSnapshot = sessionSnapshot
        self.createdAt = Date()
        self.lastUpdated = Date()
        self.isCompleted = false
        self.steps = steps
        self.currentStepIndex = currentStepIndex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        targetCount = try container.decode(Int.self, forKey: .targetCount)
        currentCount = try container.decode(Int.self, forKey: .currentCount)
        zikirItemId = try container.decodeIfPresent(String.self, forKey: .zikirItemId)
        sessionSnapshot = try container.decodeIfPresent(ZikrSession.self, forKey: .sessionSnapshot)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        steps = try container.decodeIfPresent([DhikrStep].self, forKey: .steps) ?? []
        currentStepIndex = try container.decodeIfPresent(Int.self, forKey: .currentStepIndex) ?? 0
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, targetCount, currentCount, zikirItemId, sessionSnapshot, createdAt, lastUpdated, isCompleted, steps, currentStepIndex
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CounterModel, rhs: CounterModel) -> Bool {
        lhs.id == rhs.id
    }
}
