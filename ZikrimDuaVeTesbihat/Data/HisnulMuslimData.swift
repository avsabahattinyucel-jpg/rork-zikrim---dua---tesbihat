import Foundation

enum HisnulMuslimData {
    static let entries: [RehberEntry] = {
        var seenArabicTexts = Set(existingArabicTexts().map(normalizeArabic))

        return GuideContentStore.hisnulMuslimEntries().filter { entry in
            let normalizedArabic = normalizeArabic(entry.arabicText)
            guard !normalizedArabic.isEmpty else { return true }
            return seenArabicTexts.insert(normalizedArabic).inserted
        }
    }()

    private static func existingArabicTexts() -> [String] {
        var texts: [String] = []

        texts.append(contentsOf: guideArabicTexts())
        texts.append(contentsOf: zikirArabicTexts())
        texts.append(contentsOf: ZikirData.dailyDuas.map(\.arabicText))

        return texts
    }

    private static func guideArabicTexts() -> [String] {
        let guideEntries = ZikirRehberiData.gunlukRutinler +
            ZikirRehberiData.duygusalDurumlar +
            ZikirRehberiData.hayatDurumlari +
            ZikirRehberiData.kisaTesbihatlar +
            ZikirRehberiData.kuranDualari +
            ZikirRehberiData.rabbenaDualari +
            EsmaUlHusnaData.entries +
            CevsenData.entries

        return guideEntries.map(\.arabicText)
    }

    private static func zikirArabicTexts() -> [String] {
        ZikirData.categories.flatMap(\.items).map(\.arabicText)
    }

    nonisolated private static func normalizeArabic(_ text: String) -> String {
        let stripped = text
            .applyingTransform(.stripCombiningMarks, reverse: false)?
            .replacingOccurrences(of: "آ", with: "ا")
            .replacingOccurrences(of: "أ", with: "ا")
            .replacingOccurrences(of: "إ", with: "ا")
            .replacingOccurrences(of: "ٱ", with: "ا")
            .replacingOccurrences(of: "ى", with: "ي")
            .replacingOccurrences(of: "ة", with: "ه") ?? text

        return stripped.unicodeScalars
            .filter { (0x0600...0x06FF).contains($0.value) }
            .map(String.init)
            .joined()
    }
}
