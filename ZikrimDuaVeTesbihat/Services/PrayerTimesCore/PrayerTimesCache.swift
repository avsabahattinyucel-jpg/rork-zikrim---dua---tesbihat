import Foundation
import CoreLocation

struct PrayerTimesCacheKey: Hashable, Codable, Sendable {
    let source: PrayerSourceType
    let countryCode: String
    let city: String?
    let district: String?
    let coordinateBucket: String?
    let dateKey: String
    let method: String

    init(
        source: PrayerSourceType,
        countryCode: String,
        city: String?,
        district: String?,
        coordinate: CLLocationCoordinate2D?,
        date: Date,
        method: String,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) {
        self.source = source
        self.countryCode = countryCode
        self.city = city?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.district = district?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.coordinateBucket = coordinate?.bucketedKey

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateKey = formatter.string(from: date)
        self.method = method
    }
}

struct PrayerTimesCacheRecord: Codable, Sendable {
    let key: PrayerTimesCacheKey
    let snapshot: PrayerTimesSnapshot
    let expiresAt: Date
}

protocol PrayerTimesCacheStore: Sendable {
    func read(key: PrayerTimesCacheKey, now: Date) async -> PrayerTimesSnapshot?
    func write(snapshot: PrayerTimesSnapshot, key: PrayerTimesCacheKey, now: Date) async
}

final class PrayerTimesMemoryCacheStore: PrayerTimesCacheStore, @unchecked Sendable {
    private var store: [PrayerTimesCacheKey: PrayerTimesCacheRecord] = [:]
    private let lock = NSLock()

    func read(key: PrayerTimesCacheKey, now: Date) async -> PrayerTimesSnapshot? {
        let record = withLock { store[key] }
        guard let record, record.expiresAt >= now else { return nil }
        return record.snapshot.markCache(isFromCache: true, sourceType: .cache)
    }

    func write(snapshot: PrayerTimesSnapshot, key: PrayerTimesCacheKey, now: Date) async {
        let record = PrayerTimesCacheRecord(
            key: key,
            snapshot: snapshot,
            expiresAt: snapshot.date.endOfDay(in: TimeZone(identifier: snapshot.timezoneIdentifier) ?? .current)
        )

        withLock {
            store[key] = record
        }
    }

    private func withLock<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}

final class PrayerTimesDiskCacheStore: PrayerTimesCacheStore, @unchecked Sendable {
    private let fileURL: URL
    private var loaded = false
    private var records: [PrayerTimesCacheKey: PrayerTimesCacheRecord] = [:]
    private let lock = NSLock()

    init(fileManager: FileManager = .default) {
        let root = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        fileURL = root.appendingPathComponent("prayer_times_cache_v2.json")
    }

    func read(key: PrayerTimesCacheKey, now: Date) async -> PrayerTimesSnapshot? {
        ensureLoaded()

        let record = withLock { records[key] }
        guard let record, record.expiresAt >= now else { return nil }
        return record.snapshot.markCache(isFromCache: true, sourceType: .cache)
    }

    func write(snapshot: PrayerTimesSnapshot, key: PrayerTimesCacheKey, now: Date) async {
        ensureLoaded()

        let record = PrayerTimesCacheRecord(
            key: key,
            snapshot: snapshot,
            expiresAt: snapshot.date.endOfDay(in: TimeZone(identifier: snapshot.timezoneIdentifier) ?? .current)
        )

        withLock {
            records[key] = record
        }

        persist()
    }

    private func ensureLoaded() {
        withLock {
            guard !loaded else { return }
            loaded = true

            guard let data = try? Data(contentsOf: fileURL),
                  let decoded = try? JSONDecoder().decode([PrayerTimesCacheKey: PrayerTimesCacheRecord].self, from: data) else {
                return
            }
            records = decoded
        }
    }

    private func persist() {
        let current = withLock { records }
        guard let data = try? JSONEncoder().encode(current) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func withLock<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}

final class PrayerTimesHybridCacheStore: PrayerTimesCacheStore, @unchecked Sendable {
    private let memory: PrayerTimesMemoryCacheStore
    private let disk: PrayerTimesDiskCacheStore

    init(
        memory: PrayerTimesMemoryCacheStore = PrayerTimesMemoryCacheStore(),
        disk: PrayerTimesDiskCacheStore = PrayerTimesDiskCacheStore()
    ) {
        self.memory = memory
        self.disk = disk
    }

    func read(key: PrayerTimesCacheKey, now: Date) async -> PrayerTimesSnapshot? {
        if let inMemory = await memory.read(key: key, now: now) {
            return inMemory
        }

        if let fromDisk = await disk.read(key: key, now: now) {
            await memory.write(snapshot: fromDisk, key: key, now: now)
            return fromDisk
        }

        return nil
    }

    func write(snapshot: PrayerTimesSnapshot, key: PrayerTimesCacheKey, now: Date) async {
        await memory.write(snapshot: snapshot, key: key, now: now)
        await disk.write(snapshot: snapshot, key: key, now: now)
    }
}

private extension CLLocationCoordinate2D {
    var bucketedKey: String {
        let lat = (latitude * 20).rounded() / 20
        let lon = (longitude * 20).rounded() / 20
        return "\(lat),\(lon)"
    }
}

private extension Date {
    func endOfDay(in timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let dayStart = calendar.startOfDay(for: self)
        return calendar.date(byAdding: DateComponents(day: 1, second: -1), to: dayStart) ?? self
    }
}
