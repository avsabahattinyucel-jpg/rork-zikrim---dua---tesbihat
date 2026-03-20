import Foundation

nonisolated struct BackupPayload: Codable, Sendable {
    let counters: [CounterModel]
    let favorites: [FavoriteItem]
    let stats: [DailyStats]
    let notes: [DailyJournalEntry]
    let settings: UserProfile
    let updatedAt: Date
}

@Observable
@MainActor
class CloudBackupService {
    static let shared = CloudBackupService()

    var isSyncing: Bool = false
    var lastSyncDate: Date?
    var syncError: String?

    private init() {}

    func backupNow(userID: String, storage: StorageService) async {
        await CloudSyncService.shared.uploadToCloud(storage: storage)
    }

    func restoreIfAvailable(userID: String, storage: StorageService) async {
        await CloudSyncService.shared.syncFromCloud(storage: storage)
    }
}
