import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

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
        isSyncing = true
        syncError = nil

        let payload = BackupPayload(
            counters: storage.counters,
            favorites: storage.profile.favorites,
            stats: storage.allStats,
            notes: storage.journalEntries,
            settings: storage.profile,
            updatedAt: Date()
        )

        do {
            #if canImport(FirebaseFirestore)
            let data = try Firestore.Encoder().encode(payload)
            try await Firestore.firestore()
                .collection("user_backups")
                .document(userID)
                .setData(data, merge: true)
            lastSyncDate = Date()
            #else
            throw NSError(domain: "CloudBackup", code: -1)
            #endif
        } catch {
            syncError = "Bulut yedekleme başarısız oldu. Tekrar deneyin."
        }

        isSyncing = false
    }

    func restoreIfAvailable(userID: String, storage: StorageService) async {
        do {
            #if canImport(FirebaseFirestore)
            let snapshot = try await Firestore.firestore()
                .collection("user_backups")
                .document(userID)
                .getDocument()

            guard let data = snapshot.data() else { return }
            let payload = try Firestore.Decoder().decode(BackupPayload.self, from: data)
            storage.counters = payload.counters
            storage.profile = payload.settings
            storage.profile.favorites = payload.favorites
            storage.profile.favoriteZikirIds = payload.favorites.map(\.id)
            storage.allStats = payload.stats
            storage.journalEntries = payload.notes
            storage.saveCounters()
            storage.saveProfile()
            storage.saveStats()
            storage.saveJournalEntries()
            lastSyncDate = payload.updatedAt
            #endif
        } catch {
            syncError = "Bulut verisi geri yüklenemedi."
        }
    }
}
