import Foundation

struct PrayerNotificationTextVariant: Sendable {
    let id: String
    let text: String
}

private struct PrayerContentPayload: Decodable, Sendable {
    let version: Int
    let language: String
    let notes: [String]
    let categories: [String: [PrayerContentItem]]
}

private struct PrayerContentItem: Decodable, Sendable {
    let id: Int
    let type: String
    let text: String
}

enum PrayerNotificationTextCatalog {
    private static let decoder = JSONDecoder()
    private static let resourceCache = PrayerNotificationResourceCache()

    static func variants(for prayer: PrayerName, language: AppLanguage) -> [PrayerNotificationTextVariant] {
        guard let categoryKey = categoryKey(for: prayer) else { return [] }
        guard let payload = loadPayload(for: language) ?? fallbackPayload(for: language) else { return [] }

        return (payload.categories[categoryKey] ?? []).map {
            PrayerNotificationTextVariant(id: "\(categoryKey)_\($0.id)", text: $0.text)
        }
    }

    static func rotatingVariant(
        for prayer: PrayerName,
        language: AppLanguage,
        date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> PrayerNotificationTextVariant? {
        let variants = variants(for: prayer, language: language)
        guard !variants.isEmpty else { return nil }

        let dayIndex = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        let prayerIndex = PrayerName.allCases.firstIndex(of: prayer) ?? 0
        let index = (dayIndex + (prayerIndex * 7)) % variants.count
        return variants[index]
    }

    static func localizedBody(
        prayerName: String,
        language: AppLanguage,
        offsetMinutes: Int?,
        spiritualText: String?
    ) -> String? {
        guard let spiritualText, !spiritualText.isEmpty else {
            return nil
        }

        if let offsetMinutes, offsetMinutes > 0 {
            switch language {
            case .tr:
                return "\(offsetMinutes) dakika sonra \(prayerName) vakti girecek. \(spiritualText)"
            case .ar:
                return "يتبقى \(offsetMinutes) دقيقة على \(prayerName). \(spiritualText)"
            case .fr:
                return "Il reste \(offsetMinutes) min avant \(prayerName). \(spiritualText)"
            case .de:
                return "Noch \(offsetMinutes) Min bis \(prayerName). \(spiritualText)"
            case .id:
                return "\(offsetMinutes) menit lagi menuju \(prayerName). \(spiritualText)"
            case .ms:
                return "Tinggal \(offsetMinutes) minit lagi sebelum \(prayerName). \(spiritualText)"
            case .fa:
                return "\(offsetMinutes) دقیقه تا \(prayerName) باقی مانده است. \(spiritualText)"
            case .ru:
                return "До \(prayerName) осталось \(offsetMinutes) мин. \(spiritualText)"
            case .es:
                return "Faltan \(offsetMinutes) min para \(prayerName). \(spiritualText)"
            case .ur:
                return "\(prayerName) میں \(offsetMinutes) منٹ باقی ہیں۔ \(spiritualText)"
            case .en:
                return "\(offsetMinutes) min left until \(prayerName). \(spiritualText)"
            }
        }

        switch language {
        case .tr:
            return "\(prayerName) vakti girdi. \(spiritualText)"
        case .ar:
            return "حان وقت \(prayerName). \(spiritualText)"
        case .fr:
            return "C'est l'heure de \(prayerName). \(spiritualText)"
        case .de:
            return "Es ist Zeit fuer \(prayerName). \(spiritualText)"
        case .id:
            return "Waktu \(prayerName) telah masuk. \(spiritualText)"
        case .ms:
            return "Waktu \(prayerName) telah masuk. \(spiritualText)"
        case .fa:
            return "وقت \(prayerName) فرا رسيد. \(spiritualText)"
        case .ru:
            return "Наступило время \(prayerName). \(spiritualText)"
        case .es:
            return "Es la hora de \(prayerName). \(spiritualText)"
        case .ur:
            return "\(prayerName) کا وقت ہو گیا ہے۔ \(spiritualText)"
        case .en:
            return "It is time for \(prayerName). \(spiritualText)"
        }
    }

    private static func categoryKey(for prayer: PrayerName) -> String? {
        switch prayer {
        case .fajr:
            return "sabah"
        case .dhuhr:
            return "ogle"
        case .asr:
            return "ikindi"
        case .maghrib:
            return "aksam"
        case .isha:
            return "yatsi"
        case .sunrise:
            return nil
        }
    }

    private static func fallbackPayload(for language: AppLanguage) -> PrayerContentPayload? {
        if language != .tr, let localized = loadPayload(for: .tr) {
            return localized
        }

        if language != .en, let english = loadPayload(for: .en) {
            return english
        }

        return nil
    }

    private static func loadPayload(for language: AppLanguage) -> PrayerContentPayload? {
        resourceCache.payload(for: language.rawValue) {
            guard let url = resourceURL(for: language.rawValue),
                  let data = try? Data(contentsOf: url),
                  let payload = try? decoder.decode(PrayerContentPayload.self, from: data) else {
                return nil
            }

            return payload
        }
    }

    private static func resourceURL(for languageCode: String) -> URL? {
        let resourceName = "prayer_content_\(languageCode)"
        let subdirectories: [String?] = [nil, "PrayerContent", "Data", "Data/PrayerContent"]

        for subdirectory in subdirectories {
            if let url = Bundle.main.url(forResource: resourceName, withExtension: "json", subdirectory: subdirectory) {
                return url
            }
        }

        #if DEBUG
        let sourceDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let developmentURL = sourceDirectory
            .appendingPathComponent("Data", isDirectory: true)
            .appendingPathComponent("PrayerContent", isDirectory: true)
            .appendingPathComponent("\(resourceName).json", isDirectory: false)

        if FileManager.default.fileExists(atPath: developmentURL.path) {
            return developmentURL
        }
        #endif

        return nil
    }
}

private final class PrayerNotificationResourceCache: @unchecked Sendable {
    private let lock = NSLock()
    private var payloads: [String: PrayerContentPayload] = [:]

    func payload(for languageCode: String, loader: () -> PrayerContentPayload?) -> PrayerContentPayload? {
        lock.lock()
        if let cached = payloads[languageCode] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        guard let loaded = loader() else { return nil }

        lock.lock()
        payloads[languageCode] = loaded
        lock.unlock()
        return loaded
    }
}
