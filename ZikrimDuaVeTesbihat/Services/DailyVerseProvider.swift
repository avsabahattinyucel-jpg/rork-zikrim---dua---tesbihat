import Foundation

final class DailyVerseProvider {
    static let shared = DailyVerseProvider()

    struct DailyVerse: Identifiable, Equatable, Sendable {
        let surahId: Int
        let ayahNumber: Int
        let surahName: String
        let translation: String
        let languageCode: String
        let translationSource: String?

        var id: String { "\(surahId):\(ayahNumber)" }

        var metadataText: String {
            L10n.format(.surahVerseFormat, surahName, Int64(ayahNumber))
        }
    }

    private struct VerseReference: Sendable {
        let surah: Int
        let ayah: Int
    }

    private let fallbackLanguages = ["tr", "en"]
    private let sourceStore = RabiaVerifiedSourceStore.shared

    private init() {}

    func verseForDate(_ date: Date = Date(), calendar: Calendar = .autoupdatingCurrent) -> DailyVerse? {
        let languageCodes = fallbackLanguageCodes(for: currentLanguageCode())
        let eligibleVerses = curatedReferences.compactMap { reference in
            buildVerse(for: reference, languageCodes: languageCodes)
        }

        guard !eligibleVerses.isEmpty else { return nil }
        let index = deterministicIndex(for: date, count: eligibleVerses.count, calendar: calendar)
        return eligibleVerses[index]
    }

    private func buildVerse(for reference: VerseReference, languageCodes: [String]) -> DailyVerse? {
        guard let translationResult = sourceStore.localizedTranslation(
                surah: reference.surah,
                ayah: reference.ayah,
                preferredLanguageCodes: languageCodes
              ),
              let surahName = sourceStore.localizedSurahName(
                for: reference.surah,
                preferredLanguageCodes: languageCodes
              ) else {
            return nil
        }

        let normalizedTranslation = normalizeVerseText(translationResult.text)
        guard isEligible(normalizedTranslation) else { return nil }

        return DailyVerse(
            surahId: reference.surah,
            ayahNumber: reference.ayah,
            surahName: surahName,
            translation: normalizedTranslation,
            languageCode: translationResult.languageCode,
            translationSource: translationSourceName(for: translationResult.languageCode)
        )
    }

    private func fallbackLanguageCodes(for activeLanguage: String) -> [String] {
        var codes: [String] = [activeLanguage]
        for fallback in fallbackLanguages where !codes.contains(fallback) {
            codes.append(fallback)
        }
        return codes
    }

    private func currentLanguageCode() -> String {
        RabiaAppLanguage.currentCode()
    }

    private func translationSourceName(for languageCode: String) -> String? {
        switch languageCode {
        case "tr": return L10n.string(.diyanetIsleriBaskanligi)
        case "en": return "Sahih International"
        case "de": return "Bubenheim ve Elyas"
        case "fr": return "Muhammad Hamidullah"
        case "es": return "Julio Cortes"
        case "ru": return "Kuliyev"
        case "ur": return "Jalandhry"
        case "fa": return "Fooladvand"
        case "id": return "Kementerian Agama RI"
        case "ms": return "Basmeih"
        case "ar": return "Arapca Mushaf"
        default: return nil
        }
    }

    private func normalizeVerseText(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isEligible(_ text: String) -> Bool {
        let length = text.count
        return length >= 22 && length <= 260
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

    private let curatedReferences: [VerseReference] = [
        VerseReference(surah: 1, ayah: 2),
        VerseReference(surah: 1, ayah: 5),
        VerseReference(surah: 1, ayah: 6),
        VerseReference(surah: 2, ayah: 2),
        VerseReference(surah: 2, ayah: 21),
        VerseReference(surah: 2, ayah: 45),
        VerseReference(surah: 2, ayah: 152),
        VerseReference(surah: 2, ayah: 153),
        VerseReference(surah: 2, ayah: 186),
        VerseReference(surah: 2, ayah: 201),
        VerseReference(surah: 2, ayah: 255),
        VerseReference(surah: 2, ayah: 286),
        VerseReference(surah: 3, ayah: 8),
        VerseReference(surah: 3, ayah: 26),
        VerseReference(surah: 3, ayah: 92),
        VerseReference(surah: 3, ayah: 139),
        VerseReference(surah: 3, ayah: 159),
        VerseReference(surah: 4, ayah: 36),
        VerseReference(surah: 5, ayah: 8),
        VerseReference(surah: 5, ayah: 16),
        VerseReference(surah: 6, ayah: 17),
        VerseReference(surah: 7, ayah: 23),
        VerseReference(surah: 8, ayah: 2),
        VerseReference(surah: 8, ayah: 46),
        VerseReference(surah: 9, ayah: 51),
        VerseReference(surah: 10, ayah: 57),
        VerseReference(surah: 11, ayah: 6),
        VerseReference(surah: 11, ayah: 88),
        VerseReference(surah: 12, ayah: 64),
        VerseReference(surah: 12, ayah: 87),
        VerseReference(surah: 12, ayah: 92),
        VerseReference(surah: 13, ayah: 11),
        VerseReference(surah: 13, ayah: 28),
        VerseReference(surah: 13, ayah: 29),
        VerseReference(surah: 14, ayah: 7),
        VerseReference(surah: 16, ayah: 18),
        VerseReference(surah: 16, ayah: 53),
        VerseReference(surah: 16, ayah: 97),
        VerseReference(surah: 17, ayah: 9),
        VerseReference(surah: 17, ayah: 24),
        VerseReference(surah: 17, ayah: 80),
        VerseReference(surah: 18, ayah: 10),
        VerseReference(surah: 18, ayah: 46),
        VerseReference(surah: 19, ayah: 96),
        VerseReference(surah: 20, ayah: 114),
        VerseReference(surah: 21, ayah: 83),
        VerseReference(surah: 21, ayah: 87),
        VerseReference(surah: 21, ayah: 88),
        VerseReference(surah: 21, ayah: 107),
        VerseReference(surah: 24, ayah: 35),
        VerseReference(surah: 25, ayah: 63),
        VerseReference(surah: 29, ayah: 69),
        VerseReference(surah: 30, ayah: 21),
        VerseReference(surah: 31, ayah: 17),
        VerseReference(surah: 33, ayah: 41),
        VerseReference(surah: 33, ayah: 43),
        VerseReference(surah: 33, ayah: 56),
        VerseReference(surah: 35, ayah: 29),
        VerseReference(surah: 39, ayah: 53),
        VerseReference(surah: 40, ayah: 44),
        VerseReference(surah: 41, ayah: 30),
        VerseReference(surah: 42, ayah: 30),
        VerseReference(surah: 42, ayah: 43),
        VerseReference(surah: 47, ayah: 7),
        VerseReference(surah: 48, ayah: 4),
        VerseReference(surah: 49, ayah: 10),
        VerseReference(surah: 49, ayah: 13),
        VerseReference(surah: 50, ayah: 16),
        VerseReference(surah: 51, ayah: 56),
        VerseReference(surah: 53, ayah: 39),
        VerseReference(surah: 57, ayah: 4),
        VerseReference(surah: 57, ayah: 20),
        VerseReference(surah: 57, ayah: 28),
        VerseReference(surah: 58, ayah: 11),
        VerseReference(surah: 59, ayah: 21),
        VerseReference(surah: 64, ayah: 11),
        VerseReference(surah: 65, ayah: 3),
        VerseReference(surah: 67, ayah: 15),
        VerseReference(surah: 73, ayah: 8),
        VerseReference(surah: 76, ayah: 8),
        VerseReference(surah: 76, ayah: 9),
        VerseReference(surah: 87, ayah: 14),
        VerseReference(surah: 87, ayah: 15),
        VerseReference(surah: 89, ayah: 27),
        VerseReference(surah: 89, ayah: 28),
        VerseReference(surah: 89, ayah: 30),
        VerseReference(surah: 93, ayah: 3),
        VerseReference(surah: 93, ayah: 4),
        VerseReference(surah: 93, ayah: 5),
        VerseReference(surah: 93, ayah: 6),
        VerseReference(surah: 93, ayah: 7),
        VerseReference(surah: 93, ayah: 8),
        VerseReference(surah: 93, ayah: 9),
        VerseReference(surah: 93, ayah: 10),
        VerseReference(surah: 93, ayah: 11),
        VerseReference(surah: 94, ayah: 5),
        VerseReference(surah: 94, ayah: 6),
        VerseReference(surah: 94, ayah: 7),
        VerseReference(surah: 94, ayah: 8),
        VerseReference(surah: 95, ayah: 4),
        VerseReference(surah: 95, ayah: 6),
        VerseReference(surah: 96, ayah: 1),
        VerseReference(surah: 96, ayah: 5),
        VerseReference(surah: 96, ayah: 19),
        VerseReference(surah: 97, ayah: 3),
        VerseReference(surah: 97, ayah: 5),
        VerseReference(surah: 99, ayah: 7),
        VerseReference(surah: 99, ayah: 8),
        VerseReference(surah: 103, ayah: 2),
        VerseReference(surah: 103, ayah: 3),
        VerseReference(surah: 108, ayah: 1),
        VerseReference(surah: 108, ayah: 2),
        VerseReference(surah: 112, ayah: 1),
        VerseReference(surah: 112, ayah: 2),
        VerseReference(surah: 112, ayah: 3),
        VerseReference(surah: 112, ayah: 4),
        VerseReference(surah: 113, ayah: 1),
        VerseReference(surah: 113, ayah: 5),
        VerseReference(surah: 114, ayah: 1),
        VerseReference(surah: 114, ayah: 6)
    ]
}

#if DEBUG
extension DailyVerseProvider.DailyVerse {
    static let preview = DailyVerseProvider.DailyVerse(
        surahId: 13,
        ayahNumber: 28,
        surahName: "Ra'd",
        translation: "Bilesiniz ki kalpler ancak Allah'ı anmakla huzur bulur.",
        languageCode: "tr",
        translationSource: L10n.string(.diyanetIsleriBaskanligi)
    )
}
#endif
