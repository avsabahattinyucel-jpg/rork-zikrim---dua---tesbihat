import Foundation
import CloudKit

nonisolated struct CloudBackupPayload: Codable, Sendable {
    let counters: [CounterModel]
    let favorites: [FavoriteItem]
    let stats: [DailyStats]
    let notes: [DailyJournalEntry]
    let profile: UserProfile
    let habitRecords: [DailyHabitRecord]
    let faithLogs: [DailyFaithLogEntry]
    let customZikirs: [ZikirItem]
    let updatedAt: Date
}

@Observable
@MainActor
class CloudSyncService {
    static let shared = CloudSyncService()

    var isSyncing: Bool = false
    var isUploading: Bool = false
    var isDownloading: Bool = false
    var lastSyncDate: Date?
    var syncError: String?
    var iCloudAvailable: Bool = false

    private let containerID = "iCloud.app.rork.pu2jopnhgtfk3o9m6amda.2de8110f"
    private let recordType = "UserBackup"
    private let backupRecordName = "mainBackup"

    private init() {
        if let saved = UserDefaults.standard.object(forKey: "lastCloudSyncDate") as? Date {
            lastSyncDate = saved
        }
    }

    func checkiCloudStatus() async {
        do {
            let status = try await CKContainer(identifier: containerID).accountStatus()
            iCloudAvailable = (status == .available)
        } catch {
            iCloudAvailable = false
        }
    }

    func uploadToCloud(storage: StorageService) async {
        guard RevenueCatService.shared.isPremium else { return }
        guard !isUploading else { return }
        isUploading = true
        isSyncing = true
        syncError = nil

        let cID = containerID
        let rType = recordType
        let rName = backupRecordName

        do {
            let container = CKContainer(identifier: cID)
            let status = try await container.accountStatus()
            guard status == .available else {
                throw CloudSyncError.iCloudUnavailable
            }
            iCloudAvailable = true

            let payload = CloudBackupPayload(
                counters: storage.counters,
                favorites: storage.profile.favorites,
                stats: storage.allStats,
                notes: storage.journalEntries,
                profile: storage.profile,
                habitRecords: storage.habitRecords,
                faithLogs: storage.faithLogs,
                customZikirs: storage.customZikirs,
                updatedAt: Date()
            )

            let data = try JSONEncoder().encode(payload)
            let database = container.privateCloudDatabase
            let recordID = CKRecord.ID(recordName: rName)

            let record: CKRecord
            do {
                record = try await database.record(for: recordID)
            } catch {
                record = CKRecord(recordType: rType, recordID: recordID)
            }
            record["backupData"] = data as NSData
            record["updatedAt"] = Date() as NSDate
            try await database.save(record)

            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastCloudSyncDate")
        } catch {
            syncError = Self.mapError(error)
        }

        isUploading = false
        isSyncing = false
    }

    func syncFromCloud(storage: StorageService) async {
        guard RevenueCatService.shared.isPremium else { return }
        guard !isDownloading else { return }
        isDownloading = true
        isSyncing = true
        syncError = nil

        let cID = containerID
        let rName = backupRecordName

        do {
            let container = CKContainer(identifier: cID)
            let status = try await container.accountStatus()
            guard status == .available else {
                throw CloudSyncError.iCloudUnavailable
            }
            iCloudAvailable = true

            let database = container.privateCloudDatabase
            let recordID = CKRecord.ID(recordName: rName)
            let record = try await database.record(for: recordID)

            guard let data = record["backupData"] as? Data else {
                syncError = "Bulutta yedek bulunamadi."
                isDownloading = false
                isSyncing = false
                return
            }

            let payload = try JSONDecoder().decode(CloudBackupPayload.self, from: data)

            storage.counters = payload.counters
            storage.profile = payload.profile
            storage.profile.favorites = payload.favorites
            storage.profile.favoriteZikirIds = payload.favorites.map(\.id)
            storage.allStats = payload.stats
            storage.journalEntries = payload.notes
            storage.habitRecords = payload.habitRecords
            storage.faithLogs = payload.faithLogs
            storage.customZikirs = payload.customZikirs
            storage.saveCounters()
            storage.saveProfile()
            storage.saveStats()
            storage.saveJournalEntries()
            storage.saveHabitRecords()
            storage.saveFaithLogs()
            storage.saveCustomZikirs()

            lastSyncDate = payload.updatedAt
            UserDefaults.standard.set(lastSyncDate, forKey: "lastCloudSyncDate")
        } catch let ckError as CKError where ckError.code == .unknownItem {
            syncError = "Bulutta henuz yedek bulunamadi."
        } catch {
            syncError = Self.mapError(error)
        }

        isDownloading = false
        isSyncing = false
    }

    func saveDhikrCount(storage: StorageService) async {
        guard RevenueCatService.shared.isPremium, storage.profile.cloudSyncEnabled else { return }
        await uploadToCloud(storage: storage)
    }

    func deleteBackupIfExists() async throws {
        let container = CKContainer(identifier: containerID)
        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: backupRecordName)

        do {
            _ = try await database.deleteRecord(withID: recordID)
        } catch let error as CKError where error.code == .unknownItem {
        }
    }

    func clearLocalSyncState() {
        lastSyncDate = nil
        syncError = nil
        UserDefaults.standard.removeObject(forKey: "lastCloudSyncDate")
    }

    private nonisolated static func mapError(_ error: Error) -> String {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkUnavailable, .networkFailure:
                return L10n.string(.errorInternetConnectionMissing)
            case .notAuthenticated:
                return L10n.string(.errorIcloudSignInRequired)
            case .quotaExceeded:
                return L10n.string(.errorIcloudStorageFull)
            case .serviceUnavailable:
                return L10n.string(.errorIcloudServiceUnavailable)
            default:
                return L10n.format(.errorCloudSyncFailedCode, ckError.code.rawValue)
            }
        }
        if error is CloudSyncError {
            return L10n.string(.errorIcloudSignInRequired)
        }
        return L10n.string(.errorUnexpectedTryAgain)
    }
}

nonisolated enum CloudSyncError: Error, Sendable {
    case iCloudUnavailable
}
