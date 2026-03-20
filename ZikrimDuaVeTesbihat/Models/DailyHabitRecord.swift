import Foundation

nonisolated struct DailyHabitRecord: Codable, Sendable {
    let dateString: String
    var prayerStatus: [String: Bool]
    var prayerStates: [String: PrayerCompletionStatus]
    var qadaLinkedPrayerKeys: [String]
    var completedHabits: [String]
    var shukurNote: String
    var isAchievementShared: Bool

    static let prayerNames: [String] = ["Sabah", "Öğle", "İkindi", "Akşam", "Yatsı"]
    static let prayerIcons: [String: String] = [
        "Sabah": "moon.stars.fill",
        "Öğle": "sun.max.fill",
        "İkindi": "sun.haze.fill",
        "Akşam": "sunset.fill",
        "Yatsı": "moon.fill"
    ]
    static let defaultHabits: [String] = ["Kur'an Oku", "Günlük Zikir", "Dua Et", "Sadaka Ver", "İstiğfar"]

    init(dateString: String) {
        self.dateString = dateString
        self.prayerStatus = [:]
        self.prayerStates = [:]
        self.qadaLinkedPrayerKeys = []
        self.completedHabits = []
        self.shukurNote = ""
        self.isAchievementShared = false
    }

    var completedPrayerCount: Int {
        PrayerName.obligatoryCases.filter { prayerCompletionStatus(for: $0) == .prayed }.count
    }

    var progress: Double {
        let prayerFraction = Double(completedPrayerCount) / 5.0 * 0.6
        let noteFraction: Double = shukurNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.0 : 0.2
        let habitFraction = min(Double(completedHabits.count) / Double(max(Self.defaultHabits.count, 1)), 1.0) * 0.2
        return min(prayerFraction + noteFraction + habitFraction, 1.0)
    }

    var isFullyComplete: Bool {
        completedPrayerCount == 5 && !shukurNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func prayerCompletionStatus(for prayer: PrayerName) -> PrayerCompletionStatus {
        if let state = prayerStates[prayer.rawValue] {
            return state
        }
        if prayerStatus[prayer.legacyTrackingKey] == true {
            return .prayed
        }
        return .unknown
    }

    func isLinkedToQada(_ prayer: PrayerName) -> Bool {
        qadaLinkedPrayerKeys.contains(prayer.rawValue)
    }

    mutating func setPrayerCompletionStatus(_ status: PrayerCompletionStatus, for prayer: PrayerName) {
        prayerStates[prayer.rawValue] = status

        switch status {
        case .prayed:
            prayerStatus[prayer.legacyTrackingKey] = true
            qadaLinkedPrayerKeys.removeAll { $0 == prayer.rawValue }
        case .missed:
            prayerStatus.removeValue(forKey: prayer.legacyTrackingKey)
        case .unknown:
            prayerStatus.removeValue(forKey: prayer.legacyTrackingKey)
            qadaLinkedPrayerKeys.removeAll { $0 == prayer.rawValue }
        }
    }

    mutating func markLinkedToQada(_ prayer: PrayerName) {
        guard !qadaLinkedPrayerKeys.contains(prayer.rawValue) else { return }
        qadaLinkedPrayerKeys.append(prayer.rawValue)
    }

    private enum CodingKeys: String, CodingKey {
        case dateString
        case prayerStatus
        case prayerStates
        case qadaLinkedPrayerKeys
        case completedHabits
        case shukurNote
        case isAchievementShared
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dateString = try container.decode(String.self, forKey: .dateString)
        prayerStatus = try container.decodeIfPresent([String: Bool].self, forKey: .prayerStatus) ?? [:]
        qadaLinkedPrayerKeys = try container.decodeIfPresent([String].self, forKey: .qadaLinkedPrayerKeys) ?? []
        completedHabits = try container.decodeIfPresent([String].self, forKey: .completedHabits) ?? []
        shukurNote = try container.decodeIfPresent(String.self, forKey: .shukurNote) ?? ""
        isAchievementShared = try container.decodeIfPresent(Bool.self, forKey: .isAchievementShared) ?? false

        let decodedStates = try container.decodeIfPresent([String: PrayerCompletionStatus].self, forKey: .prayerStates) ?? [:]
        prayerStates = Self.migratedPrayerStates(from: decodedStates, legacyStatus: prayerStatus)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dateString, forKey: .dateString)
        try container.encode(prayerStatus, forKey: .prayerStatus)
        try container.encode(prayerStates, forKey: .prayerStates)
        try container.encode(qadaLinkedPrayerKeys, forKey: .qadaLinkedPrayerKeys)
        try container.encode(completedHabits, forKey: .completedHabits)
        try container.encode(shukurNote, forKey: .shukurNote)
        try container.encode(isAchievementShared, forKey: .isAchievementShared)
    }

    private static func migratedPrayerStates(
        from decodedStates: [String: PrayerCompletionStatus],
        legacyStatus: [String: Bool]
    ) -> [String: PrayerCompletionStatus] {
        var migrated = decodedStates

        for prayer in PrayerName.obligatoryCases {
            guard migrated[prayer.rawValue] == nil else { continue }
            if legacyStatus[prayer.legacyTrackingKey] == true {
                migrated[prayer.rawValue] = .prayed
            }
        }

        return migrated
    }
}

private extension PrayerName {
    nonisolated var legacyTrackingKey: String {
        switch self {
        case .fajr:
            return "Sabah"
        case .sunrise:
            return "Güneş"
        case .dhuhr:
            return "Öğle"
        case .asr:
            return "İkindi"
        case .maghrib:
            return "Akşam"
        case .isha:
            return "Yatsı"
        }
    }
}
