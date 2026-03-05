import Foundation

nonisolated struct KhutbahContent: Codable, Sendable {
    let title: String
    let date: String
    let content: String
}

nonisolated struct KhutbahInsightCache: Codable, Sendable {
    let theme: String
    let practicalPoints: [String]
    let weeklyTask: String
}

nonisolated enum KhutbahError: LocalizedError, Sendable {
    case invalidURL
    case networkError(Int)
    case parsingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Geçersiz URL adresi."
        case .networkError(let code): return "Ağ hatası (\(code)). Bağlantınızı kontrol edin."
        case .parsingError: return "Hutbe içeriği okunamadı. Lütfen siteyi ziyaret edin."
        }
    }
}

@Observable
@MainActor
final class KhutbahService {
    var content: KhutbahContent? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var summary: [String] = []
    var insight: KhutbahInsight? = nil
    var isSummarizing: Bool = false
    var summarizeError: String? = nil

    private let rssURL = "https://www.diyanethaber.com.tr/rss/hutbeler"
    private let gemini = GroqService()
    private let cachedWeekKey = "khutbah_cached_week_v1"
    private let cachedContentKey = "khutbah_cached_content_v1"
    private let cachedInsightKey = "khutbah_cached_insight_v1"

    func fetch() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if loadWeeklyCacheIfAvailable() {
            return
        }

        do {
            let fetched = try await fetchFromRSS()
            content = fetched
            if !fetched.content.isEmpty {
                await summarize(text: fetched.content)
            }
        } catch let error as KhutbahError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Bağlantı hatası: \(error.localizedDescription)"
        }
    }

    private func fetchFromRSS() async throws -> KhutbahContent {
        guard let url = URL(string: rssURL) else { throw KhutbahError.invalidURL }

        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("tr-TR,tr;q=0.9", forHTTPHeaderField: "Accept-Language")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw KhutbahError.networkError(http.statusCode)
        }

        let rssParser = RSSFeedParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = rssParser
        xmlParser.parse()

        guard let item = rssParser.items.first else {
            throw KhutbahError.parsingError
        }

        let rawContent = item.contentEncoded.isEmpty ? item.description : item.contentEncoded
        let plainText = stripHTML(rawContent)
        let finalContent = plainText.isEmpty ? stripHTML(item.description) : plainText

        return KhutbahContent(
            title: item.title.isEmpty ? "Haftanın Hutbesi" : item.title,
            date: item.pubDate,
            content: finalContent
        )
    }

    private func stripHTML(_ input: String) -> String {
        var text = input
        while let range = text.range(of: "<[^>]+>", options: .regularExpression) {
            text.replaceSubrange(range, with: "")
        }
        return text
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "\n\n\n", with: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - AI Summarize via Gemini

    func summarize(text: String) async {
        isSummarizing = true
        summarizeError = nil
        defer { isSummarizing = false }
        do {
            let result = try await gemini.summarizeKhutbah(text)
            insight = result
            summary = result.practicalPoints
            saveWeeklyCache(content: content, insight: result)
            print("[KhutbahService] ✅ AI özeti başarılı")
        } catch {
            summarizeError = error.localizedDescription
            print("[KhutbahService] ❌ AI özet hatası: \(error)")
            summary = makeFallbackSummary(from: text)
        }
    }

    private func loadWeeklyCacheIfAvailable() -> Bool {
        let weekId = currentWeekIdentifier()
        guard UserDefaults.standard.string(forKey: cachedWeekKey) == weekId else {
            return false
        }
        guard
            let contentData = UserDefaults.standard.data(forKey: cachedContentKey),
            let cachedContent = try? JSONDecoder().decode(KhutbahContent.self, from: contentData)
        else {
            return false
        }

        content = cachedContent
        if let insightData = UserDefaults.standard.data(forKey: cachedInsightKey),
           let cachedInsight = try? JSONDecoder().decode(KhutbahInsightCache.self, from: insightData) {
            let mapped = KhutbahInsight(theme: cachedInsight.theme, practicalPoints: cachedInsight.practicalPoints, weeklyTask: cachedInsight.weeklyTask)
            insight = mapped
            summary = mapped.practicalPoints
        }
        return true
    }

    private func saveWeeklyCache(content: KhutbahContent?, insight: KhutbahInsight) {
        guard let content else { return }
        UserDefaults.standard.set(currentWeekIdentifier(), forKey: cachedWeekKey)
        if let contentData = try? JSONEncoder().encode(content) {
            UserDefaults.standard.set(contentData, forKey: cachedContentKey)
        }
        let cachedInsight = KhutbahInsightCache(theme: insight.theme, practicalPoints: insight.practicalPoints, weeklyTask: insight.weeklyTask)
        if let insightData = try? JSONEncoder().encode(cachedInsight) {
            UserDefaults.standard.set(insightData, forKey: cachedInsightKey)
        }
    }

    private func currentWeekIdentifier() -> String {
        let calendar = Calendar.current
        let year = calendar.component(.yearForWeekOfYear, from: Date())
        let week = calendar.component(.weekOfYear, from: Date())
        return "\(year)-\(week)"
    }

    private func makeFallbackSummary(from text: String) -> [String] {
        let sentences = text
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 50 }

        guard sentences.count >= 3 else {
            return sentences.prefix(3).map { $0 + "." }
        }

        let step = max(1, sentences.count / 3)
        return [
            sentences[0] + ".",
            sentences[min(step, sentences.count - 1)] + ".",
            sentences[min(step * 2, sentences.count - 1)] + "."
        ]
    }
}

// MARK: - RSS Feed Parser

private final class RSSFeedItem {
    var title: String = ""
    var link: String = ""
    var description: String = ""
    var pubDate: String = ""
    var contentEncoded: String = ""
}

private final class RSSFeedParser: NSObject, XMLParserDelegate {
    var items: [RSSFeedItem] = []
    private var currentItem: RSSFeedItem? = nil
    private var currentQName: String = ""
    private var currentText: String = ""
    private var inItem: Bool = false

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes: [String: String] = [:]
    ) {
        currentQName = qName?.isEmpty == false ? qName! : elementName
        currentText = ""
        if elementName == "item" {
            currentItem = RSSFeedItem()
            inItem = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if let str = String(data: CDATABlock, encoding: .utf8) {
            currentText += str
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        guard inItem, let item = currentItem else { return }
        let resolvedName = qName?.isEmpty == false ? qName! : elementName
        let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch resolvedName {
        case "title":
            item.title = trimmed
        case "link":
            if item.link.isEmpty { item.link = trimmed }
        case "description":
            item.description = trimmed
        case "pubDate":
            item.pubDate = formatRSSDate(trimmed)
        case "content:encoded", "encoded":
            item.contentEncoded = trimmed
        case "item":
            items.append(item)
            currentItem = nil
            inItem = false
        default:
            break
        }
        currentText = ""
    }

    private func formatRSSDate(_ raw: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        if let date = formatter.date(from: raw) {
            let output = DateFormatter()
            output.locale = Locale(identifier: "tr_TR")
            output.dateFormat = "dd MMMM yyyy"
            return output.string(from: date)
        }
        if let range = raw.range(of: "\\d{1,2} \\w+ \\d{4}", options: .regularExpression) {
            return String(raw[range])
        }
        return raw
    }
}
