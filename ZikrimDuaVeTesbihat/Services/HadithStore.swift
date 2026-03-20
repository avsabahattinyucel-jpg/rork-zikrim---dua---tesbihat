import Combine
import Foundation

@MainActor
final class HadithStore: ObservableObject {
    @Published private(set) var hadiths: [Hadith] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: HadeethEncService

    private var loadedLanguageCode: String?
    private var summaryCache: [String: [Hadith]] = [:]
    private var detailCache: [HadithDetailCacheKey: Hadith] = [:]

    init(service: HadeethEncService = HadeethEncService()) {
        self.service = service
    }

    func loadIfNeeded(languageCode: String = RabiaAppLanguage.currentCode()) async {
        let normalizedLanguage = RabiaAppLanguage.normalizedCode(for: languageCode)
        guard summaryCache[normalizedLanguage] == nil else {
            hadiths = summaryCache[normalizedLanguage] ?? []
            loadedLanguageCode = normalizedLanguage
            errorMessage = nil
            return
        }

        await load(languageCode: normalizedLanguage)
    }

    func reload(languageCode: String = RabiaAppLanguage.currentCode()) async {
        let normalizedLanguage = RabiaAppLanguage.normalizedCode(for: languageCode)
        summaryCache[normalizedLanguage] = nil
        await load(languageCode: normalizedLanguage)
    }

    func filteredHadiths(
        searchText: String,
        limit: Int? = nil,
        languageCode: String = RabiaAppLanguage.currentCode()
    ) -> [Hadith] {
        let items = hadithsForCurrentLanguage(languageCode)
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            return limit.map { Array(items.prefix($0)) } ?? items
        }

        let normalizedQuery = normalized(trimmedQuery)
        let filtered = items.filter { hadith in
            normalized(hadith.title).contains(normalizedQuery)
                || normalized(hadith.hadeeth).contains(normalizedQuery)
                || normalized(hadith.attribution ?? "").contains(normalizedQuery)
                || normalized(hadith.hadeethArabic ?? "").contains(normalizedQuery)
        }

        return limit.map { Array(filtered.prefix($0)) } ?? filtered
    }

    func filteredShortFeedHadiths(
        searchText: String,
        limit: Int? = nil,
        languageCode: String = RabiaAppLanguage.currentCode()
    ) -> [Hadith] {
        let items = filteredHadiths(searchText: searchText, limit: nil, languageCode: languageCode)
            .filter(\.isShortFeedEligible)

        return limit.map { Array(items.prefix($0)) } ?? items
    }

    func hadithDetail(
        for hadith: Hadith,
        languageCode: String = RabiaAppLanguage.currentCode()
    ) async throws -> Hadith {
        let normalizedLanguage = RabiaAppLanguage.normalizedCode(for: languageCode)
        let cacheKey = HadithDetailCacheKey(id: hadith.id, languageCode: normalizedLanguage)

        if let cached = detailCache[cacheKey] {
            return cached
        }

        let detail = try await service.fetchHadithDetail(
            id: hadith.id,
            preferredLanguageCode: normalizedLanguage
        )

        detailCache[cacheKey] = detail
        replaceCachedHadith(detail, requestedLanguageCode: normalizedLanguage)

        return detail
    }

    func hydrateShortFeed(
        languageCode: String = RabiaAppLanguage.currentCode(),
        minimumEligibleCount: Int = 24,
        scanLimit: Int = 120
    ) async {
        let normalizedLanguage = RabiaAppLanguage.normalizedCode(for: languageCode)
        guard let items = summaryCache[normalizedLanguage] else { return }

        let currentEligibleCount = items.filter(\.isShortFeedEligible).count
        guard currentEligibleCount < minimumEligibleCount else { return }

        let candidates = items
            .filter { !$0.isShortFeedEligible && $0.fullHadith.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .prefix(scanLimit)

        for candidate in candidates {
            guard let latest = summaryCache[normalizedLanguage]?.first(where: { $0.id == candidate.id }) else {
                continue
            }
            guard !latest.isShortFeedEligible,
                  latest.fullHadith.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                continue
            }

            do {
                _ = try await hadithDetail(for: latest, languageCode: normalizedLanguage)
            } catch {
                continue
            }

            let refreshedEligibleCount = summaryCache[normalizedLanguage]?.filter(\.isShortFeedEligible).count ?? 0
            if refreshedEligibleCount >= minimumEligibleCount {
                break
            }
        }
    }

    private func load(languageCode: String) async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let summaries = try await service.fetchLibrary(preferredLanguageCode: languageCode)
            summaryCache[languageCode] = summaries
            hadiths = summaries
            loadedLanguageCode = languageCode
        } catch {
            hadiths = []
            loadedLanguageCode = nil
            errorMessage = String(
                localized: "hadith_store_error_message",
                defaultValue: "Hadis içerikleri şu anda yüklenemedi."
            )
        }
    }

    private func hadithsForCurrentLanguage(_ languageCode: String) -> [Hadith] {
        let normalizedLanguage = RabiaAppLanguage.normalizedCode(for: languageCode)
        if loadedLanguageCode == normalizedLanguage, !hadiths.isEmpty {
            return hadiths
        }

        return summaryCache[normalizedLanguage] ?? []
    }

    private func replaceCachedHadith(_ detail: Hadith, requestedLanguageCode: String) {
        guard var items = summaryCache[requestedLanguageCode] else { return }

        guard let index = items.firstIndex(where: { $0.id == detail.id }) else { return }

        items[index] = detail
        summaryCache[requestedLanguageCode] = items

        if loadedLanguageCode == requestedLanguageCode {
            hadiths = items
        }
    }

    private func normalized(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct HadithDetailCacheKey: Hashable {
    let id: Int
    let languageCode: String
}
