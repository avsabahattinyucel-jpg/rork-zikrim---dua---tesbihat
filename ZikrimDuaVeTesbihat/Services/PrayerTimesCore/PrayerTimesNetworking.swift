import Foundation

protocol PrayerHTTPClient: Sendable {
    func get(url: URL, headers: [String: String]) async throws -> (Data, HTTPURLResponse)
}

struct URLSessionPrayerHTTPClient: PrayerHTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(url: URL, headers: [String: String]) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw PrayerTimesDataError.invalidResponse
            }
            return (data, http)
        } catch let error as URLError where error.code == .timedOut {
            throw PrayerTimesDataError.timeout
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw PrayerTimesDataError.networkFailure
        } catch {
            throw PrayerTimesDataError.networkFailure
        }
    }
}

struct AlAdhanTimingsEnvelope: Decodable {
    let code: Int
    let status: String
    let data: DataNode

    struct DataNode: Decodable {
        let timings: Timings
        let date: DateNode
        let meta: MetaNode

        struct Timings: Decodable {
            let fajr: String
            let sunrise: String
            let dhuhr: String
            let asr: String
            let maghrib: String
            let isha: String

            enum CodingKeys: String, CodingKey {
                case fajr = "Fajr"
                case sunrise = "Sunrise"
                case dhuhr = "Dhuhr"
                case asr = "Asr"
                case maghrib = "Maghrib"
                case isha = "Isha"
            }
        }

        struct DateNode: Decodable {
            let gregorian: GregorianNode
            let hijri: HijriNode

            struct GregorianNode: Decodable {
                let date: String
            }

            struct HijriNode: Decodable {
                let date: String
            }
        }

        struct MetaNode: Decodable {
            let timezone: String
            let method: MethodNode

            struct MethodNode: Decodable {
                let id: Int?
                let name: String
            }
        }
    }
}

struct DiyanetNormalizedDay: Sendable, Equatable {
    let gregorianDate: Date
    let hijriDateText: String
    let timezoneIdentifier: String
    let cityDisplayName: String
    let districtDisplayName: String?
    let imsak: String
    let sunrise: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
}

protocol DiyanetResponseParsing: Sendable {
    func parse(html: String, date: Date) throws -> DiyanetNormalizedDay
}

struct DiyanetSelectorStrategy: Sendable {
    let tableRowPattern: String
    let cityPattern: String
    let districtPattern: String
    let timezonePattern: String
    let hijriPattern: String

    static let `default` = DiyanetSelectorStrategy(
        tableRowPattern: #"<tr[^>]*data-gregorian="([0-9\-]+)"[^>]*>\s*<td[^>]*>[^<]*</td>\s*<td[^>]*>([^<]+)</td>\s*<td[^>]*>([^<]+)</td>\s*<td[^>]*>([^<]+)</td>\s*<td[^>]*>([^<]+)</td>\s*<td[^>]*>([^<]+)</td>\s*<td[^>]*>([^<]+)</td>"#,
        cityPattern: #"data-city-name="([^"]+)""#,
        districtPattern: #"data-district-name="([^"]+)""#,
        timezonePattern: #"data-timezone="([^"]+)""#,
        hijriPattern: #"data-hijri="([^"]+)""#
    )
}

struct DiyanetHTMLParser: DiyanetResponseParsing {
    private let strategy: DiyanetSelectorStrategy

    init(strategy: DiyanetSelectorStrategy = .default) {
        self.strategy = strategy
    }

    func parse(html: String, date: Date) throws -> DiyanetNormalizedDay {
        let city = html.firstMatch(pattern: strategy.cityPattern, captureGroup: 1) ?? ""
        let district = html.firstMatch(pattern: strategy.districtPattern, captureGroup: 1)
        let timezone = html.firstMatch(pattern: strategy.timezonePattern, captureGroup: 1) ?? "Europe/Istanbul"
        let hijri = html.firstMatch(pattern: strategy.hijriPattern, captureGroup: 1) ?? ""

        let rows = html.allMatches(pattern: strategy.tableRowPattern)
        let target = rows.first { values in
            guard values.count >= 7 else { return false }
            return values[0] == date.diyanetDateString
        }

        guard let values = target, values.count >= 7 else {
            throw PrayerTimesDataError.diyanetPageStructureChanged
        }

        guard let gregorianDate = Date.diyanetDateFormatter.date(from: values[0]) else {
            throw PrayerTimesDataError.invalidResponse
        }

        return DiyanetNormalizedDay(
            gregorianDate: gregorianDate,
            hijriDateText: hijri,
            timezoneIdentifier: timezone,
            cityDisplayName: city,
            districtDisplayName: district,
            imsak: values[1],
            sunrise: values[2],
            dhuhr: values[3],
            asr: values[4],
            maghrib: values[5],
            isha: values[6]
        )
    }
}

protocol DiyanetEndpointResolving: Sendable {
    func candidateURLs(city: String, district: String?) -> [URL]
}

struct DiyanetEndpointResolver: DiyanetEndpointResolving {
    func candidateURLs(city: String, district: String?) -> [URL] {
        let citySlug = city.diyanetSlug
        let districtSlug = district?.diyanetSlug
        let base = "https://namazvakitleri.diyanet.gov.tr"

        var urls: [URL] = []
        if let districtSlug, !districtSlug.isEmpty,
           let districtURL = URL(string: "\(base)/tr-TR/\(districtSlug)-icin-namaz-vakti") {
            urls.append(districtURL)
        }
        if let cityURL = URL(string: "\(base)/tr-TR/\(citySlug)-icin-namaz-vakti") {
            urls.append(cityURL)
        }
        if let cityFallbackURL = URL(string: "\(base)/tr-TR") {
            urls.append(cityFallbackURL)
        }
        return urls
    }
}

extension Date {
    static let diyanetDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var diyanetDateString: String {
        Self.diyanetDateFormatter.string(from: self)
    }
}

extension String {
    var diyanetSlug: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    func firstMatch(pattern: String, captureGroup: Int = 1) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }
        let range = NSRange(startIndex..<endIndex, in: self)
        guard let match = regex.firstMatch(in: self, options: [], range: range),
              captureGroup < match.numberOfRanges,
              let groupRange = Range(match.range(at: captureGroup), in: self) else {
            return nil
        }
        return String(self[groupRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func allMatches(pattern: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return []
        }
        let range = NSRange(startIndex..<endIndex, in: self)
        return regex.matches(in: self, options: [], range: range).map { match in
            var groups: [String] = []
            for idx in 1..<match.numberOfRanges {
                if let groupRange = Range(match.range(at: idx), in: self) {
                    groups.append(String(self[groupRange]).trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
            return groups
        }
    }

    var normalizedAladhanTime: String {
        components(separatedBy: " ").first?
            .replacingOccurrences(of: "[^0-9:]", with: "", options: .regularExpression) ?? self
    }
}
