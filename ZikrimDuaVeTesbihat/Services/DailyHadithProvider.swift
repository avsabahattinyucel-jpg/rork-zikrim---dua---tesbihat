import Foundation

final class DailyHadithProvider {
    static let shared = DailyHadithProvider()

    private let service: HadeethEncService
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        service: HadeethEncService = HadeethEncService(),
        userDefaults: UserDefaults = .standard
    ) {
        self.service = service
        self.userDefaults = userDefaults
    }

    func hadithForDate(
        _ date: Date = Date(),
        languageCode: String = RabiaAppLanguage.currentCode(),
        calendar: Calendar = .autoupdatingCurrent
    ) async throws -> Hadith {
        let normalizedLanguageCode = RabiaAppLanguage.normalizedCode(for: languageCode)
        let cacheKey = cacheKey(
            for: date,
            languageCode: normalizedLanguageCode,
            calendar: calendar,
            variant: "full_v2"
        )

        if let cached = loadCachedHadith(for: cacheKey) {
            return cached
        }

        let hadith = try await service.fetchDailyHadith(
            date: date,
            preferredLanguageCode: normalizedLanguageCode,
            calendar: calendar
        )
        cache(hadith, for: cacheKey)
        return hadith
    }

    func shortHadithForDate(
        _ date: Date = Date(),
        languageCode: String = RabiaAppLanguage.currentCode(),
        calendar: Calendar = .autoupdatingCurrent
    ) async throws -> Hadith {
        let normalizedLanguageCode = RabiaAppLanguage.normalizedCode(for: languageCode)
        let cacheKey = cacheKey(
            for: date,
            languageCode: normalizedLanguageCode,
            calendar: calendar,
            variant: "short_v2"
        )

        if let cached = loadCachedHadith(for: cacheKey), cached.isShortFeedEligible {
            return cached
        }

        let hadith = try await service.fetchDailyShortHadith(
            date: date,
            preferredLanguageCode: normalizedLanguageCode,
            calendar: calendar
        )
        cache(hadith, for: cacheKey)
        return hadith
    }

    private func cacheKey(
        for date: Date,
        languageCode: String,
        calendar: Calendar,
        variant: String
    ) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 2000
        let month = components.month ?? 1
        let day = components.day ?? 1
        return String(format: "daily_hadith_%@_%04d_%02d_%02d_%@", languageCode, year, month, day, variant)
    }

    private func loadCachedHadith(for key: String) -> Hadith? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }

        return try? decoder.decode(Hadith.self, from: data)
    }

    private func cache(_ hadith: Hadith, for key: String) {
        guard let data = try? encoder.encode(hadith) else {
            return
        }

        userDefaults.set(data, forKey: key)
    }
}
