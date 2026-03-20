import Foundation
import SwiftUI

struct PrayerSpiritualContentRoute: Identifiable, Hashable, Sendable {
    let prayer: PrayerName
    let prayerName: String
    let formattedTime: String
    let date: Date

    var id: String {
        "\(prayer.rawValue)-\(Int(date.timeIntervalSince1970))-\(formattedTime)"
    }

    init(item: PrayerDisplayItem, date: Date) {
        self.prayer = item.id
        self.prayerName = item.localizedName
        self.formattedTime = item.formattedTime
        self.date = date
    }
}

enum SpiritualContentType: String, CaseIterable, Sendable {
    case ayah
    case hadith
    case dua
    case dhikr
    case reflection

    var localizedName: String {
        switch self {
        case .ayah:
            return String(localized: "spiritual_content_type_ayah", defaultValue: "Ayet")
        case .hadith:
            return String(localized: "spiritual_content_type_hadith", defaultValue: "Hadis")
        case .dua:
            return String(localized: "spiritual_content_type_dua", defaultValue: "Dua")
        case .dhikr:
            return String(localized: "spiritual_content_type_dhikr", defaultValue: "Zikir")
        case .reflection:
            return String(localized: "spiritual_content_type_reflection", defaultValue: "Düşünce")
        }
    }
}

struct SpiritualContentText: Hashable, Sendable {
    let title: String?
    let text: String
    let source: String?
    let arabicText: String?
    let repeatSuggestion: String?
}

struct SpiritualContentItem: Identifiable, Hashable, Sendable {
    let id: String
    let type: SpiritualContentType
    let prayerTargets: [PrayerName]
    let tags: [String]
    let localizations: [String: SpiritualContentText]
}

struct ResolvedSpiritualContentItem: Identifiable, Hashable, Sendable {
    let id: String
    let type: SpiritualContentType
    let prayer: PrayerName
    let title: String?
    let text: String
    let source: String?
    let arabicText: String?
    let repeatSuggestion: String?
    let languageCode: String
    let tags: [String]

    var shareText: String {
        [
            title,
            text,
            source
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
    }
}

enum SpiritualContentProvider {
    static func dailyItem(
        for prayer: PrayerName,
        date: Date,
        languageCode: String = RabiaAppLanguage.currentCode()
    ) -> ResolvedSpiritualContentItem? {
        let candidates = candidates(for: prayer, languageCode: languageCode)
        guard !candidates.isEmpty else { return fallbackItem(for: prayer, languageCode: languageCode) }
        let seed = dailySeed(for: prayer, date: date, languageCode: languageCode)
        return candidates[seed % candidates.count]
    }

    static func nextItem(
        after currentID: String?,
        for prayer: PrayerName,
        date: Date,
        languageCode: String = RabiaAppLanguage.currentCode()
    ) -> ResolvedSpiritualContentItem? {
        let candidates = candidates(for: prayer, languageCode: languageCode)
        guard !candidates.isEmpty else { return fallbackItem(for: prayer, languageCode: languageCode) }

        if let currentID,
           let currentIndex = candidates.firstIndex(where: { $0.id == currentID }) {
            return candidates[(currentIndex + 1) % candidates.count]
        }

        return dailyItem(for: prayer, date: date, languageCode: languageCode)
    }

    static func prefetchDailyContent(
        for prayers: [PrayerName],
        date: Date,
        languageCode: String = RabiaAppLanguage.currentCode()
    ) -> [PrayerName: ResolvedSpiritualContentItem] {
        Dictionary(uniqueKeysWithValues: prayers.compactMap { prayer in
            dailyItem(for: prayer, date: date, languageCode: languageCode).map { (prayer, $0) }
        })
    }

    private static func candidates(for prayer: PrayerName, languageCode: String) -> [ResolvedSpiritualContentItem] {
        let tags = prayerTags(for: prayer)
        let preferredLanguages = preferredLanguageCodes(for: languageCode)

        return items
            .compactMap { item -> (resolved: ResolvedSpiritualContentItem, score: Int)? in
                guard item.prayerTargets.contains(prayer) else { return nil }
                let intersection = Set(item.tags).intersection(tags)
                guard !intersection.isEmpty else { return nil }
                guard let resolved = resolve(item, for: prayer, preferredLanguages: preferredLanguages) else { return nil }
                return (resolved, intersection.count)
            }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.resolved.id < rhs.resolved.id
            }
            .map(\.resolved)
    }

    private static func resolve(
        _ item: SpiritualContentItem,
        for prayer: PrayerName,
        preferredLanguages: [String]
    ) -> ResolvedSpiritualContentItem? {
        for code in preferredLanguages {
            if let text = item.localizations[code] {
                return ResolvedSpiritualContentItem(
                    id: item.id,
                    type: item.type,
                    prayer: prayer,
                    title: text.title,
                    text: text.text,
                    source: text.source,
                    arabicText: text.arabicText,
                    repeatSuggestion: text.repeatSuggestion,
                    languageCode: code,
                    tags: item.tags
                )
            }
        }

        return nil
    }

    private static func preferredLanguageCodes(for languageCode: String) -> [String] {
        let primary = RabiaAppLanguage.normalizedCode(for: languageCode)
        return Array(NSOrderedSet(array: [primary, "en", "ar"]).compactMap { $0 as? String }) as? [String] ?? [primary, "en", "ar"]
    }

    private static func prayerTags(for prayer: PrayerName) -> Set<String> {
        switch prayer {
        case .fajr:
            return ["fajr", "sabah", "baslangic", "niyet", "sukur", "dua"]
        case .sunrise:
            return ["sunrise", "sabah", "isik", "sukur", "reflection"]
        case .dhuhr:
            return ["dhuhr", "ogle", "farkindalik", "denge", "dua"]
        case .asr:
            return ["asr", "ikindi", "sabir", "istikrar", "dhikr"]
        case .maghrib:
            return ["maghrib", "aksam", "birakma", "sukur", "teslimiyet", "dhikr"]
        case .isha:
            return ["isha", "yatsi", "huzur", "sukunet", "gece", "dua"]
        }
    }

    private static func dailySeed(for prayer: PrayerName, date: Date, languageCode: String) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let daySeed = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        let prayerSeed = PrayerName.allCases.firstIndex(of: prayer) ?? 0
        let languageSeed = RabiaAppLanguage.normalizedCode(for: languageCode).unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return abs(daySeed * 37 + prayerSeed * 17 + languageSeed)
    }

    private static func fallbackItem(
        for prayer: PrayerName,
        languageCode: String
    ) -> ResolvedSpiritualContentItem? {
        let preferredLanguages = preferredLanguageCodes(for: languageCode)
        guard let code = preferredLanguages.first else { return nil }
        let text = SpiritualContentText(
            title: nil,
            text: PrayerMicroMessageCatalog.messages(for: prayer).first ?? "",
            source: String(localized: "spiritual_content_fallback_source", defaultValue: "Günün kısa düşüncesi"),
            arabicText: nil,
            repeatSuggestion: nil
        )
        return ResolvedSpiritualContentItem(
            id: "fallback_\(prayer.rawValue)",
            type: .reflection,
            prayer: prayer,
            title: text.title,
            text: text.text,
            source: text.source,
            arabicText: text.arabicText,
            repeatSuggestion: text.repeatSuggestion,
            languageCode: code,
            tags: Array(prayerTags(for: prayer))
        )
    }

    private static let items: [SpiritualContentItem] = [
        SpiritualContentItem(
            id: "fajr_breath_of_dawn",
            type: .ayah,
            prayerTargets: [.fajr],
            tags: ["fajr", "sabah", "baslangic", "niyet"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Nefes aldığı an sabaha andolsun.",
                    source: "Tekvir 18",
                    arabicText: "وَالصُّبْحِ إِذَا تَنَفَّسَ",
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "By the dawn as it breathes.",
                    source: "At-Takwir 81:18",
                    arabicText: "وَالصُّبْحِ إِذَا تَنَفَّسَ",
                    repeatSuggestion: nil
                ),
                "ar": SpiritualContentText(
                    title: nil,
                    text: "By the dawn as it breathes.",
                    source: "التكوير ١٨",
                    arabicText: "وَالصُّبْحِ إِذَا تَنَفَّسَ",
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "fajr_tasbih_before_sunrise",
            type: .ayah,
            prayerTargets: [.fajr],
            tags: ["fajr", "sabah", "tesbih", "baslangic", "niyet"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Güneşin doğmasından önce rabbini överek tesbih et.",
                    source: "Taha 130",
                    arabicText: "وَسَبِّحْ بِحَمْدِ رَبِّكَ قَبْلَ طُلُوعِ الشَّمْسِ",
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "Glorify your Lord with praise before sunrise.",
                    source: "Ta-Ha 20:130",
                    arabicText: "وَسَبِّحْ بِحَمْدِ رَبِّكَ قَبْلَ طُلُوعِ الشَّمْسِ",
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "fajr_congregation_hadith",
            type: .hadith,
            prayerTargets: [.fajr],
            tags: ["fajr", "sabah", "istikrar", "niyet", "hadith"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Kim sabah namazını cemaatle kılarsa, sanki gecenin tamamını ibadetle geçirmiş gibi olur.",
                    source: "Müslim, Mesacid, 260",
                    arabicText: nil,
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "Whoever performs Fajr in congregation is as though he spent the whole night in worship.",
                    source: "Muslim, Masajid, 260",
                    arabicText: nil,
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "fajr_opening_dua",
            type: .dua,
            prayerTargets: [.fajr],
            tags: ["fajr", "sabah", "dua", "niyet", "sukur"],
            localizations: [
                "tr": SpiritualContentText(
                    title: "Sabah duası",
                    text: "Allah'ım, bu günün başlangıcını kalbim için berrak, dilim için yumuşak, niyetim için temiz kıl.",
                    source: "Güne başlarken",
                    arabicText: nil,
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: "Morning prayer",
                    text: "O Allah, make the opening of this day clear for my heart, gentle for my tongue, and pure for my intention.",
                    source: "At the start of the day",
                    arabicText: nil,
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "sunrise_gratitude_ayah",
            type: .ayah,
            prayerTargets: [.sunrise],
            tags: ["sunrise", "sabah", "isik", "sukur", "reflection"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Şükrederseniz elbette size nimetimi artırırım.",
                    source: "İbrahim 7",
                    arabicText: nil,
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "If you are grateful, I will surely increase you.",
                    source: "Ibrahim 14:7",
                    arabicText: nil,
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "sunrise_gratitude_reflection",
            type: .reflection,
            prayerTargets: [.sunrise],
            tags: ["sunrise", "sabah", "isik", "sukur", "reflection"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Işık yavaşça büyürken, şükür de kalpte sessizce yer açar.",
                    source: "Sabah düşüncesi",
                    arabicText: nil,
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "As the light widens gently, gratitude quietly opens a space in the heart.",
                    source: "Morning reflection",
                    arabicText: nil,
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "sunrise_alhamdulillah_dhikr",
            type: .dhikr,
            prayerTargets: [.sunrise],
            tags: ["sunrise", "sabah", "sukur", "dhikr"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Elhamdulillah",
                    source: "Güne şükürle başlamak için",
                    arabicText: "الْحَمْدُ لِلّٰهِ",
                    repeatSuggestion: "x33"
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "Alhamdulillah",
                    source: "A gratitude dhikr for the morning light",
                    arabicText: "الْحَمْدُ لِلّٰهِ",
                    repeatSuggestion: "x33"
                )
            ]
        ),
        SpiritualContentItem(
            id: "dhuhr_remembrance",
            type: .ayah,
            prayerTargets: [.dhuhr],
            tags: ["dhuhr", "ogle", "farkindalik", "denge"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Beni anın ki Ben de sizi anayım.",
                    source: "Bakara 152",
                    arabicText: "فَاذْكُرُونِي أَذْكُرْكُمْ",
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "Remember Me, and I will remember you.",
                    source: "Al-Baqarah 2:152",
                    arabicText: "فَاذْكُرُونِي أَذْكُرْكُمْ",
                    repeatSuggestion: nil
                ),
                "ar": SpiritualContentText(
                    title: nil,
                    text: "Remember Me, and I will remember you.",
                    source: "البقرة ١٥٢",
                    arabicText: "فَاذْكُرُونِي أَذْكُرْكُمْ",
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "dhuhr_consistency_hadith",
            type: .hadith,
            prayerTargets: [.dhuhr],
            tags: ["dhuhr", "ogle", "istikrar", "farkindalik", "hadith"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Allah katında amellerin en sevimlisi, az da olsa devamlı olanıdır.",
                    source: "Buhari, Rikak, 18",
                    arabicText: nil,
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "The most beloved deeds to Allah are those done regularly, even if they are small.",
                    source: "Bukhari, Riqaq, 18",
                    arabicText: nil,
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "dhuhr_pause_reflection",
            type: .reflection,
            prayerTargets: [.dhuhr],
            tags: ["dhuhr", "ogle", "farkindalik", "dua"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Günün ortasında kısa bir duruş, kalbin yönünü yeniden toparlayabilir.",
                    source: "Öğle düşüncesi",
                    arabicText: nil,
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "A brief pause in the middle of the day can gather the direction of the heart again.",
                    source: "Midday reflection",
                    arabicText: nil,
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "dhuhr_centering_dua",
            type: .dua,
            prayerTargets: [.dhuhr],
            tags: ["dhuhr", "ogle", "dua", "denge", "farkindalik"],
            localizations: [
                "tr": SpiritualContentText(
                    title: "Öğle duası",
                    text: "Allah'ım, günün ortasında kalbimi dağıtan şeyleri azalt, niyetimi yeniden topla.",
                    source: "Gün ortası duası",
                    arabicText: nil,
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: "Midday prayer",
                    text: "O Allah, lessen what scatters my heart in the middle of the day and gather my intention again.",
                    source: "Midday supplication",
                    arabicText: nil,
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "asr_seek_help_ayah",
            type: .ayah,
            prayerTargets: [.asr],
            tags: ["asr", "ikindi", "sabir", "istikrar", "ayat"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Sabır ve namazla Allah'tan yardım isteyin. Şüphesiz Allah sabredenlerle beraberdir.",
                    source: "Bakara 153",
                    arabicText: nil,
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "Seek help through patience and prayer. Surely Allah is with the patient.",
                    source: "Al-Baqarah 2:153",
                    arabicText: nil,
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "asr_patience_reflection",
            type: .reflection,
            prayerTargets: [.asr],
            tags: ["asr", "ikindi", "sabir", "istikrar"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "İkindi, günün ağırlığını acele etmeden taşıyıp kalbi yeniden sakinleştirme vaktidir.",
                    source: "İkindi düşüncesi",
                    arabicText: nil,
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "Asr is a moment to carry the weight of the day without haste and return the heart to calm.",
                    source: "Afternoon reflection",
                    arabicText: nil,
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "asr_subhanallah",
            type: .dhikr,
            prayerTargets: [.asr],
            tags: ["asr", "ikindi", "sabir", "dhikr"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Subhanallah",
                    source: "Kalbi hafifleten zikir",
                    arabicText: "سُبْحَانَ اللّٰهِ",
                    repeatSuggestion: "x33"
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "SubhanAllah",
                    source: "A light remembrance",
                    arabicText: "سُبْحَانَ اللّٰهِ",
                    repeatSuggestion: "x33"
                )
            ]
        ),
        SpiritualContentItem(
            id: "asr_hasbunallah_dhikr",
            type: .dhikr,
            prayerTargets: [.asr],
            tags: ["asr", "ikindi", "tevekkul", "sabir", "dhikr"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Hasbunallahu ve ni'mel vekil",
                    source: "Tevekkül zikri",
                    arabicText: "حَسْبُنَا اللّٰهُ وَنِعْمَ الْوَكِيلُ",
                    repeatSuggestion: "x7"
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "Hasbunallahu wa ni'mal wakeel",
                    source: "A remembrance of trust",
                    arabicText: "حَسْبُنَا اللّٰهُ وَنِعْمَ الْوَكِيلُ",
                    repeatSuggestion: "x7"
                )
            ]
        ),
        SpiritualContentItem(
            id: "maghrib_two_ends_ayah",
            type: .ayah,
            prayerTargets: [.maghrib],
            tags: ["maghrib", "aksam", "birakma", "teslimiyet", "ayat"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Gündüzün iki tarafında ve gecenin gündüze yakın vakitlerinde namaz kıl.",
                    source: "Hud 114",
                    arabicText: nil,
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "Establish prayer at both ends of the day and in the early hours of the night.",
                    source: "Hud 11:114",
                    arabicText: nil,
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "maghrib_release_reflection",
            type: .reflection,
            prayerTargets: [.maghrib],
            tags: ["maghrib", "aksam", "birakma", "sukur", "teslimiyet"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Akşam, günün yükünü bırakmak ve kalbi yeniden yumuşatmak için sessiz bir davettir.",
                    source: "Akşam düşüncesi",
                    arabicText: nil,
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "Evening is a quiet invitation to set down the weight of the day and soften the heart again.",
                    source: "Evening reflection",
                    arabicText: nil,
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "maghrib_alhamdulillah",
            type: .dhikr,
            prayerTargets: [.maghrib],
            tags: ["maghrib", "aksam", "sukur", "dhikr"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Elhamdulillah",
                    source: "Şükür zikri",
                    arabicText: "الْحَمْدُ لِلّٰهِ",
                    repeatSuggestion: "x33"
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "Alhamdulillah",
                    source: "A remembrance of gratitude",
                    arabicText: "الْحَمْدُ لِلّٰهِ",
                    repeatSuggestion: "x33"
                )
            ]
        ),
        SpiritualContentItem(
            id: "maghrib_release_dua",
            type: .dua,
            prayerTargets: [.maghrib],
            tags: ["maghrib", "aksam", "dua", "birakma", "teslimiyet"],
            localizations: [
                "tr": SpiritualContentText(
                    title: "Akşam duası",
                    text: "Allah'ım, bugün kalbimde ağırlaşan ne varsa hafiflet ve akşamımı rahmetinle tamamla.",
                    source: "Günün sonunda",
                    arabicText: nil,
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: "Evening prayer",
                    text: "O Allah, lighten whatever has grown heavy in my heart today and complete this evening with Your mercy.",
                    source: "At the close of the day",
                    arabicText: nil,
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "isha_hearts_rest",
            type: .ayah,
            prayerTargets: [.isha],
            tags: ["isha", "yatsi", "huzur", "sukunet", "gece"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Şüphesiz kalpler ancak Allah'ı anmakla huzur bulur.",
                    source: "Ra'd 28",
                    arabicText: "أَلَا بِذِكْرِ اللّٰهِ تَطْمَئِنُّ الْقُلُوبُ",
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "Surely in the remembrance of Allah do hearts find rest.",
                    source: "Ar-Ra'd 13:28",
                    arabicText: "أَلَا بِذِكْرِ اللّٰهِ تَطْمَئِنُّ الْقُلُوبُ",
                    repeatSuggestion: nil
                ),
                "ar": SpiritualContentText(
                    title: nil,
                    text: "Surely in the remembrance of Allah do hearts find rest.",
                    source: "الرعد ٢٨",
                    arabicText: "أَلَا بِذِكْرِ اللّٰهِ تَطْمَئِنُّ الْقُلُوبُ",
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "isha_night_devotion_ayah",
            type: .ayah,
            prayerTargets: [.isha],
            tags: ["isha", "yatsi", "gece", "huzur", "dua"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Gecenin bir kısmında uyanarak sana mahsus nafile olarak namaz kıl.",
                    source: "İsra 79",
                    arabicText: nil,
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "Rise in the night for prayer as an extra devotion for you.",
                    source: "Al-Isra 17:79",
                    arabicText: nil,
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "isha_congregation_hadith",
            type: .hadith,
            prayerTargets: [.isha],
            tags: ["isha", "yatsi", "gece", "istikrar", "hadith"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Kim yatsıyı cemaatle kılarsa sanki gecenin yarısını ihya etmiş gibi olur.",
                    source: "Müslim, Mesacid, 260",
                    arabicText: nil,
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "Whoever performs Isha in congregation is as though he spent half the night in worship.",
                    source: "Muslim, Masajid, 260",
                    arabicText: nil,
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "isha_sleep_dua",
            type: .dua,
            prayerTargets: [.isha],
            tags: ["isha", "yatsi", "gece", "dua", "huzur"],
            localizations: [
                "tr": SpiritualContentText(
                    title: "Gece duası",
                    text: "Allah'ım, gecemi emniyet, kalbimi sükunet ve uykumu rahmet kıl.",
                    source: "Gecenin eşiğinde",
                    arabicText: nil,
                    repeatSuggestion: nil
                ),
                "en": SpiritualContentText(
                    title: "Night prayer",
                    text: "O Allah, make my night secure, my heart tranquil, and my sleep a mercy.",
                    source: "At the edge of night",
                    arabicText: nil,
                    repeatSuggestion: nil
                )
            ]
        ),
        SpiritualContentItem(
            id: "isha_subhanallahi_wa_bihamdihi",
            type: .dhikr,
            prayerTargets: [.isha],
            tags: ["isha", "yatsi", "huzur", "sukunet", "dhikr"],
            localizations: [
                "tr": SpiritualContentText(
                    title: nil,
                    text: "Subhanallahi ve bihamdihi",
                    source: "Geceyi yumuşatan zikir",
                    arabicText: "سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ",
                    repeatSuggestion: "x33"
                ),
                "en": SpiritualContentText(
                    title: nil,
                    text: "SubhanAllahi wa bihamdihi",
                    source: "A quiet dhikr for the night",
                    arabicText: "سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ",
                    repeatSuggestion: "x33"
                )
            ]
        )
    ]
}

@Observable
@MainActor
final class SpiritualContentBookmarkStore {
    static let shared = SpiritualContentBookmarkStore()

    private let key = "spiritual_content_saved_ids"
    var savedIDs: Set<String> = []

    private init() {
        load()
    }

    func isSaved(_ item: ResolvedSpiritualContentItem) -> Bool {
        savedIDs.contains(item.id)
    }

    func toggle(_ item: ResolvedSpiritualContentItem) {
        if savedIDs.contains(item.id) {
            savedIDs.remove(item.id)
        } else {
            savedIDs.insert(item.id)
        }
        save()
    }

    private func save() {
        UserDefaults.standard.set(Array(savedIDs), forKey: key)
    }

    private func load() {
        let values = UserDefaults.standard.stringArray(forKey: key) ?? []
        savedIDs = Set(values)
    }
}

private extension ResolvedSpiritualContentItem {
    func sharePayload(for route: PrayerSpiritualContentRoute) -> ShareCardPayload {
        let navigationTitle = String(localized: "spiritual_action_share", defaultValue: "Paylaş")
        let theme = shareTheme

        switch type {
        case .hadith:
            return ShareCardPayload(
                id: "spiritual-share-\(id)",
                cardType: .hadith(
                    HadithShareCardContent(
                        title: route.prayerName,
                        referenceText: source,
                        bodyText: text,
                        fullBodyText: [arabicText, text, repeatSuggestion].compactMap { $0 }.joined(separator: "\n\n"),
                        arabicText: arabicText,
                        explanationText: repeatSuggestion,
                        narratorText: "\(route.prayerName) vakti",
                        gradeText: nil,
                        brandingTitle: AppName.full,
                        brandingSubtitle: ShareCardBranding.storeSubtitle
                    )
                ),
                navigationTitle: navigationTitle,
                initialTheme: theme
            )
        default:
            return ShareCardPayload(
                id: "spiritual-share-\(id)",
                cardType: .diyanet(
                    DiyanetShareCardContent(
                        title: route.prayerName,
                        typeText: type.localizedName,
                        categoryText: "\(route.prayerName) vakti",
                        summaryTitle: type.localizedName,
                        summaryText: text,
                        sourceTitle: route.formattedTime,
                        sourceSubtitle: source ?? String(localized: "prayer_stage_calc_label", defaultValue: "Diyanet vakitleri"),
                        fullBodyText: [arabicText, text, repeatSuggestion].compactMap { $0 }.joined(separator: "\n\n"),
                        ctaText: nil,
                        brandingTitle: AppName.full,
                        brandingSubtitle: ShareCardBranding.storeSubtitle
                    )
                ),
                navigationTitle: navigationTitle,
                initialTheme: theme
            )
        }
    }

    var shareTheme: ShareCardTheme {
        switch prayer {
        case .fajr, .sunrise:
            return .dawn
        case .dhuhr, .asr:
            return .emerald
        case .maghrib:
            return .kaaba
        case .isha:
            return .night
        }
    }
}

struct PrayerSpiritualContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let route: PrayerSpiritualContentRoute

    @State private var currentItem: ResolvedSpiritualContentItem?
    @State private var bookmarkStore = SpiritualContentBookmarkStore.shared
    @State private var sharePayload: ShareCardPayload?

    private let languageCode = RabiaAppLanguage.currentCode()

    private var theme: ActiveTheme { themeManager.current }
    private var style: PrayerGradientProvider.Style {
        PrayerGradientProvider.style(for: route.prayer, theme: theme)
    }

    var body: some View {
        ZStack {
            PrayerSpiritualAtmosphereBackground(style: style, theme: theme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topContext
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                Spacer(minLength: 32)

                mainContent
                    .padding(.horizontal, 28)

                Spacer(minLength: 32)

                bottomActions
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
            }
        }
        .task {
            loadDailyItemIfNeeded()
        }
        .sheet(item: $sharePayload) { payload in
            NavigationStack {
                SharePreviewScreen(
                    cardType: payload.cardType,
                    initialTheme: payload.initialTheme,
                    availableThemes: payload.availableThemes,
                    showsThemePicker: payload.showsThemePicker
                )
                .navigationTitle(payload.navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(.commonClose) {
                            sharePayload = nil
                        }
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var topContext: some View {
        VStack(spacing: 8) {
            Text("\(route.prayerName) vakti")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.86))

            Text(route.formattedTime)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
    }

    private var mainContent: some View {
        Group {
            if let currentItem {
                SpiritualContentBody(item: currentItem)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                ProgressView()
                    .tint(.white.opacity(0.88))
                    .scaleEffect(1.1)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: currentItem?.id)
    }

    private var bottomActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                saveButton
                nextButton
                shareButton
                closeButton
            }

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    saveButton
                    nextButton
                }
                HStack(spacing: 10) {
                    shareButton
                    closeButton
                }
            }
        }
    }

    private var saveButton: some View {
        Button(action: toggleSave) {
            PrayerSpiritualActionCapsule(
                title: (currentItem.map(bookmarkStore.isSaved) ?? false)
                    ? String(localized: "spiritual_action_saved", defaultValue: "Kaydedildi")
                    : String(localized: "spiritual_action_save", defaultValue: "Kaydet"),
                systemImage: (currentItem.map(bookmarkStore.isSaved) ?? false) ? "bookmark.fill" : "bookmark"
            )
        }
        .buttonStyle(.plain)
        .disabled(currentItem == nil)
    }

    private var nextButton: some View {
        Button(action: showNextItem) {
            PrayerSpiritualActionCapsule(
                title: String(localized: "spiritual_action_next", defaultValue: "Başka içerik"),
                systemImage: "sparkles"
            )
        }
        .buttonStyle(.plain)
        .disabled(currentItem == nil)
    }

    private var shareButton: some View {
        Button(action: openShareCard) {
            PrayerSpiritualActionCapsule(
                title: String(localized: "spiritual_action_share", defaultValue: "Paylaş"),
                systemImage: "square.and.arrow.up"
            )
        }
        .buttonStyle(.plain)
        .disabled(currentItem == nil)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            PrayerSpiritualActionCapsule(
                title: String(localized: "spiritual_action_close", defaultValue: "Kapat"),
                systemImage: "xmark"
            )
        }
        .buttonStyle(.plain)
    }

    private func loadDailyItemIfNeeded() {
        guard currentItem == nil else { return }
        currentItem = SpiritualContentProvider.dailyItem(
            for: route.prayer,
            date: route.date,
            languageCode: languageCode
        )
    }

    private func showNextItem() {
        withAnimation(.easeInOut(duration: 0.28)) {
            currentItem = SpiritualContentProvider.nextItem(
                after: currentItem?.id,
                for: route.prayer,
                date: route.date,
                languageCode: languageCode
            )
        }
    }

    private func toggleSave() {
        guard let currentItem else { return }
        bookmarkStore.toggle(currentItem)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func openShareCard() {
        guard let currentItem else { return }
        sharePayload = currentItem.sharePayload(for: route)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}

private struct SpiritualContentBody: View {
    let item: ResolvedSpiritualContentItem

    var body: some View {
        VStack(spacing: 20) {
            Text(item.type.localizedName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.72))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08), in: Capsule())

            if let arabicText = item.arabicText, !arabicText.isEmpty {
                Text(arabicText)
                    .font(.system(size: 34, weight: .medium, design: .default))
                    .foregroundStyle(.white.opacity(0.96))
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let title = item.title, !title.isEmpty {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(verbatim: item.text)
                .font(.system(size: item.type == .dhikr ? 34 : 29, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(11)
                .fixedSize(horizontal: false, vertical: true)

            if let repeatSuggestion = item.repeatSuggestion, !repeatSuggestion.isEmpty {
                Text(repeatSuggestion)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.76))
            }

            if let source = item.source, !source.isEmpty {
                Text(source)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.70))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }
}

private struct PrayerSpiritualActionCapsule: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.10), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct PrayerSpiritualAtmosphereBackground: View {
    let style: PrayerGradientProvider.Style
    let theme: ActiveTheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(style.glow)
                .frame(width: 320, height: 320)
                .blur(radius: 54)
                .offset(x: -120, y: -180)

            Circle()
                .fill(style.accent.opacity(theme.isDarkMode ? 0.18 : 0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 68)
                .offset(x: 150, y: 180)
        }
    }

    private var backgroundColors: [Color] {
        switch style.profile {
        case .predawn:
            return [Color(red: 0.03, green: 0.07, blue: 0.16), Color(red: 0.05, green: 0.16, blue: 0.26)]
        case .sunrise:
            return [Color(red: 0.16, green: 0.10, blue: 0.14), Color(red: 0.31, green: 0.20, blue: 0.18)]
        case .daylight:
            return [Color(red: 0.06, green: 0.16, blue: 0.25), Color(red: 0.08, green: 0.27, blue: 0.36)]
        case .afternoon:
            return [Color(red: 0.07, green: 0.14, blue: 0.14), Color(red: 0.16, green: 0.24, blue: 0.18)]
        case .dusk:
            return [Color(red: 0.12, green: 0.08, blue: 0.12), Color(red: 0.22, green: 0.15, blue: 0.16)]
        case .night:
            return [Color(red: 0.02, green: 0.06, blue: 0.13), Color(red: 0.05, green: 0.12, blue: 0.22)]
        }
    }
}

#Preview("Spiritual Content Isha") {
    NavigationStack {
        PrayerSpiritualContentView(
            route: PrayerSpiritualContentRoute(
                item: PrayerViewModel.preview(current: .isha).displayedPrayer,
                date: Date()
            )
        )
    }
    .environmentObject(ThemeManager.preview(theme: .nightMosque, appearanceMode: .dark))
}

#Preview("Spiritual Content Fajr") {
    NavigationStack {
        PrayerSpiritualContentView(
            route: PrayerSpiritualContentRoute(
                item: PrayerViewModel.preview(current: .fajr).displayedPrayer,
                date: Date()
            )
        )
    }
    .environmentObject(ThemeManager.preview(theme: .default, appearanceMode: .dark))
}
