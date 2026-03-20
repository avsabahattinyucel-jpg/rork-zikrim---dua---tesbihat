import Foundation

actor HadeethEncService {
    private static let baseURL = URL(string: "https://hadeethenc.com/api/v1/")!
    private static let pageSize = 100

    private let session: URLSession
    private let decoder: JSONDecoder

    private var supportedLanguageCodes: Set<String>?

    init(session: URLSession = HadeethEncService.makeSession()) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetchLibrary(preferredLanguageCode: String) async throws -> [Hadith] {
        let languageChain = try await fallbackLanguageCodes(for: preferredLanguageCode)
        var lastError: Error?

        for languageCode in languageChain {
            do {
                let categories = try await fetchCategories(languageCode: languageCode)
                let rootCategories = categories
                    .filter { $0.parentID == nil && $0.totalCount > 0 }
                    .sorted { lhs, rhs in
                        lhs.totalCount > rhs.totalCount
                    }

                let summaries = await fetchCategorySummaries(
                    categories: rootCategories,
                    languageCode: languageCode
                )

                if !summaries.isEmpty {
                    return deduplicatedAndSorted(summaries)
                }
            } catch {
                lastError = error
            }
        }

        throw lastError ?? HadeethEncServiceError.emptyLibrary
    }

    func fetchHadithDetail(id: Int, preferredLanguageCode: String) async throws -> Hadith {
        let languageChain = try await fallbackLanguageCodes(for: preferredLanguageCode)
        var lastError: Error?

        for languageCode in languageChain {
            do {
                let record = try await fetchHadithRecord(id: id, languageCode: languageCode)
                guard let bodyText = sanitizedText(record.hadeeth) ?? sanitizedText(record.hadeethIntro) else {
                    continue
                }

                let arabicText = try await resolveArabicText(from: record, id: id, languageCode: languageCode)

                return Hadith(
                    id: numericIdentifier(from: record.id, fallback: id),
                    language: languageCode,
                    title: sanitizedText(record.title) ?? defaultTitle,
                    fullHadith: bodyText,
                    grade: sanitizedText(record.grade),
                    attribution: sanitizedText(record.attribution),
                    explanation: sanitizedText(record.explanation),
                    hints: sanitizedHints(record.hints),
                    hadeethArabic: arabicText == bodyText ? nil : arabicText
                )
            } catch {
                lastError = error
            }
        }

        throw lastError ?? HadeethEncServiceError.missingContent
    }

    func fetchDailyHadith(
        date: Date = Date(),
        preferredLanguageCode: String,
        calendar: Calendar = .autoupdatingCurrent
    ) async throws -> Hadith {
        try await fetchDailyHadith(
            date: date,
            preferredLanguageCode: preferredLanguageCode,
            calendar: calendar,
            shortFeedOnly: false
        )
    }

    func fetchDailyShortHadith(
        date: Date = Date(),
        preferredLanguageCode: String,
        calendar: Calendar = .autoupdatingCurrent
    ) async throws -> Hadith {
        try await fetchDailyHadith(
            date: date,
            preferredLanguageCode: preferredLanguageCode,
            calendar: calendar,
            shortFeedOnly: true
        )
    }

    private func fetchDailyHadith(
        date: Date,
        preferredLanguageCode: String,
        calendar: Calendar,
        shortFeedOnly: Bool
    ) async throws -> Hadith {
        let languageChain = try await fallbackLanguageCodes(for: preferredLanguageCode)
        var lastError: Error?

        for languageCode in languageChain {
            do {
                let categories = try await fetchCategories(languageCode: languageCode)
                let rootCategories = categories
                    .filter { $0.parentID == nil && $0.totalCount > 0 }
                    .sorted { lhs, rhs in
                        lhs.numericID < rhs.numericID
                    }

                let totalCount = rootCategories.reduce(0) { partialResult, category in
                    partialResult + category.totalCount
                }

                guard totalCount > 0 else {
                    continue
                }

                let startIndex = deterministicIndex(for: date, count: totalCount, calendar: calendar)
                var pageCache: [DailyListPageCacheKey: HadeethListResponse] = [:]

                for offset in 0..<totalCount {
                    let absoluteIndex = (startIndex + offset) % totalCount
                    let listItem = try await fetchListItem(
                        at: absoluteIndex,
                        categories: rootCategories,
                        languageCode: languageCode,
                        pageCache: &pageCache
                    )
                    let hadith = try await fetchHadithDetail(
                        id: numericIdentifier(from: listItem.id),
                        preferredLanguageCode: languageCode
                    )

                    if !shortFeedOnly || hadith.isShortFeedEligible {
                        return hadith
                    }
                }
            } catch {
                lastError = error
            }
        }

        throw lastError ?? HadeethEncServiceError.emptyLibrary
    }

    private func fetchCategorySummaries(
        categories: [HadeethCategoryRecord],
        languageCode: String
    ) async -> [Hadith] {
        await withTaskGroup(of: [Hadith].self) { group in
            for category in categories {
                group.addTask { [self] in
                    (try? await fetchSummaries(for: category, languageCode: languageCode)) ?? []
                }
            }

            var combined: [Hadith] = []
            for await summaries in group {
                combined.append(contentsOf: summaries)
            }
            return combined
        }
    }

    private func fetchSummaries(
        for category: HadeethCategoryRecord,
        languageCode: String
    ) async throws -> [Hadith] {
        let pageCount = max(1, Int(ceil(Double(category.totalCount) / Double(Self.pageSize))))
        var summaries: [Hadith] = []

        for page in 1...pageCount {
            let response: HadeethListResponse = try await request(
                path: "hadeeths/list/",
                queryItems: [
                    URLQueryItem(name: "language", value: languageCode),
                    URLQueryItem(name: "category_id", value: category.id),
                    URLQueryItem(name: "page", value: String(page)),
                    URLQueryItem(name: "per_page", value: String(Self.pageSize))
                ]
            )

            let pageSummaries = response.data.map { item in
                Hadith(
                    id: numericIdentifier(from: item.id),
                    language: languageCode,
                    title: sanitizedText(item.title) ?? defaultTitle,
                    fullHadith: "",
                    grade: nil,
                    attribution: sanitizedText(category.title),
                    explanation: nil,
                    hints: [],
                    hadeethArabic: nil
                )
            }

            summaries.append(contentsOf: pageSummaries)
        }

        return summaries
    }

    private func fetchListItem(
        at absoluteIndex: Int,
        categories: [HadeethCategoryRecord],
        languageCode: String,
        pageCache: inout [DailyListPageCacheKey: HadeethListResponse]
    ) async throws -> HadeethListItemRecord {
        var runningCount = 0

        for category in categories {
            let nextCount = runningCount + category.totalCount
            guard absoluteIndex < nextCount else {
                runningCount = nextCount
                continue
            }

            let localIndex = absoluteIndex - runningCount
            let page = localIndex / Self.pageSize + 1
            let position = localIndex % Self.pageSize
            let cacheKey = DailyListPageCacheKey(categoryID: category.id, page: page)

            let response: HadeethListResponse
            if let cached = pageCache[cacheKey] {
                response = cached
            } else {
                let fetched: HadeethListResponse = try await request(
                    path: "hadeeths/list/",
                    queryItems: [
                        URLQueryItem(name: "language", value: languageCode),
                        URLQueryItem(name: "category_id", value: category.id),
                        URLQueryItem(name: "page", value: String(page)),
                        URLQueryItem(name: "per_page", value: String(Self.pageSize))
                    ]
                )
                pageCache[cacheKey] = fetched
                response = fetched
            }

            guard position < response.data.count else {
                throw HadeethEncServiceError.emptyResponse
            }

            return response.data[position]
        }

        throw HadeethEncServiceError.emptyResponse
    }

    private func fetchCategories(languageCode: String) async throws -> [HadeethCategoryRecord] {
        try await request(
            path: "categories/list/",
            queryItems: [URLQueryItem(name: "language", value: languageCode)]
        )
    }

    private func fetchHadithRecord(id: Int, languageCode: String) async throws -> HadeethDetailRecord {
        try await request(
            path: "hadeeths/one/",
            queryItems: [
                URLQueryItem(name: "language", value: languageCode),
                URLQueryItem(name: "id", value: String(id))
            ]
        )
    }

    private func resolveArabicText(
        from record: HadeethDetailRecord,
        id: Int,
        languageCode: String
    ) async throws -> String? {
        if languageCode == "ar" {
            return nil
        }

        if let inlineArabic = sanitizedText(record.hadeethArabic) {
            return inlineArabic
        }

        let arabicRecord = try? await fetchHadithRecord(id: id, languageCode: "ar")
        return sanitizedText(arabicRecord?.hadeeth)
    }

    private func fallbackLanguageCodes(for preferredLanguageCode: String) async throws -> [String] {
        let normalizedCode = RabiaAppLanguage.normalizedCode(for: preferredLanguageCode)
        let supportedCodes = try await fetchSupportedLanguageCodes()

        let ordered = [normalizedCode, "en", "ar"]
        var result: [String] = []
        var seen = Set<String>()

        for code in ordered where seen.insert(code).inserted {
            if supportedCodes.contains(code) {
                result.append(code)
            }
        }

        return result.isEmpty ? ["en", "ar"] : result
    }

    private func fetchSupportedLanguageCodes() async throws -> Set<String> {
        if let supportedLanguageCodes {
            return supportedLanguageCodes
        }

        let languages: [HadeethLanguageRecord] = try await request(path: "languages", queryItems: [])
        let codes = Set(languages.map(\.code))
        supportedLanguageCodes = codes
        return codes
    }

    private func deduplicatedAndSorted(_ hadiths: [Hadith]) -> [Hadith] {
        var seen = Set<Int>()
        let unique = hadiths.filter { hadith in
            seen.insert(hadith.id).inserted
        }

        return unique.sorted { lhs, rhs in
            let lhsCategory = lhs.attribution ?? ""
            let rhsCategory = rhs.attribution ?? ""

            if lhsCategory == rhsCategory {
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }

            return lhsCategory.localizedCaseInsensitiveCompare(rhsCategory) == .orderedAscending
        }
    }

    private func request<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem]
    ) async throws -> T {
        var components = URLComponents(url: Self.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw HadeethEncServiceError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Zikrim/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HadeethEncServiceError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw HadeethEncServiceError.httpStatus(httpResponse.statusCode)
        }

        let payload = data.trimmingLeadingAndTrailingWhitespaceAndNewlines
        guard !payload.isEmpty, payload != Data("\"\"".utf8) else {
            throw HadeethEncServiceError.emptyResponse
        }

        do {
            return try decoder.decode(T.self, from: payload)
        } catch {
            throw HadeethEncServiceError.decodingFailed
        }
    }

    private func sanitizedText(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func sanitizedHints(_ values: [String]?) -> [String] {
        (values ?? []).compactMap { value in
            sanitizedText(value)
        }
    }

    private func deterministicIndex(for date: Date, count: Int, calendar: Calendar) -> Int {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 2000
        let month = components.month ?? 1
        let day = components.day ?? 1
        let key = String(format: "%04d-%02d-%02d", year, month, day)

        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }

        return Int(hash % UInt64(count))
    }

    private func numericIdentifier(from rawValue: String, fallback: Int? = nil) -> Int {
        Int(rawValue) ?? fallback ?? abs(rawValue.hashValue)
    }

    private var defaultTitle: String {
        String(localized: "hadith_default_title", defaultValue: "Hadith")
    }

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.requestCachePolicy = .reloadRevalidatingCacheData
        return URLSession(configuration: configuration)
    }
}

private nonisolated struct HadeethLanguageRecord: Decodable, Sendable {
    let code: String
}

private nonisolated struct HadeethCategoryRecord: Decodable, Sendable {
    let id: String
    let title: String
    let hadeethsCount: String
    let parentID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case hadeethsCount = "hadeeths_count"
        case parentID = "parent_id"
    }

    nonisolated var totalCount: Int {
        Int(hadeethsCount) ?? 0
    }

    nonisolated var numericID: Int {
        Int(id) ?? .max
    }
}

private nonisolated struct HadeethListResponse: Decodable, Sendable {
    let data: [HadeethListItemRecord]
}

private nonisolated struct HadeethListItemRecord: Decodable, Sendable {
    let id: String
    let title: String
}

private nonisolated struct DailyListPageCacheKey: Hashable, Sendable {
    let categoryID: String
    let page: Int
}

private nonisolated struct HadeethDetailRecord: Decodable, Sendable {
    let id: String
    let title: String
    let hadeeth: String?
    let attribution: String?
    let grade: String?
    let explanation: String?
    let hints: [String]?
    let hadeethIntro: String?
    let hadeethArabic: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case hadeeth
        case attribution
        case grade
        case explanation
        case hints
        case hadeethIntro = "hadeeth_intro"
        case hadeethArabic = "hadeeth_ar"
    }
}

private nonisolated enum HadeethEncServiceError: Error, Sendable {
    case invalidRequest
    case invalidResponse
    case httpStatus(Int)
    case emptyResponse
    case emptyLibrary
    case missingContent
    case decodingFailed
}

private extension Data {
    nonisolated var trimmingLeadingAndTrailingWhitespaceAndNewlines: Data {
        let string = String(decoding: self, as: UTF8.self)
        return Data(string.trimmingCharacters(in: .whitespacesAndNewlines).utf8)
    }
}
