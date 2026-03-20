import Foundation

enum GuideContentStore {
    private static var cachedBundle: HisnulMuslimGuideBundle?

    static func hisnulMuslimEntries() -> [RehberEntry] {
        let bundle = loadBundle()
        let mappingByCategory = Dictionary(uniqueKeysWithValues: bundle.categoryMappings.map { ($0.duaCategoryId, $0) })

        return bundle.duas
            .sorted { $0.metadata.orderIndex < $1.metadata.orderIndex }
            .map { toRehberEntry(dua: $0, mapping: mappingByCategory[$0.categoryId]) }
    }

    static func guideSections() -> [GuideSectionViewModel] {
        loadBundle().guideTabs
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { tab in
                GuideSectionViewModel(
                    id: tab.id,
                    title: localizedValue(from: tab.title.asDictionary),
                    shortDescription: localizedValue(from: tab.shortDescription.asDictionary),
                    iconName: tab.iconName,
                    sortOrder: tab.sortOrder,
                    featuredDuaId: tab.featuredDuaId
                )
            }
    }

    private static func loadBundle() -> HisnulMuslimGuideBundle {
        if let cachedBundle {
            return cachedBundle
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let url = Bundle.main.url(forResource: "hisnul_muslim_guide_bundle", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bundle = try? decoder.decode(HisnulMuslimGuideBundle.self, from: data) else {
            let empty = HisnulMuslimGuideBundle(
                version: 1,
                exportedAt: "",
                guideTabs: [],
                categoryMappings: [],
                duas: []
            )
            cachedBundle = empty
            return empty
        }

        cachedBundle = bundle
        return bundle
    }

    private static func toRehberEntry(dua: GuideBundleDua, mapping: GuideCategoryMapping?) -> RehberEntry {
        let guideTabID = mapping?.guideTabId ?? dua.guide?.primaryTabId ?? RehberCategory.hisnulMuslim.rawValue
        let legacyOverride = HisnulMuslimLegacyOverrides.matching(arabicText: dua.arabicText)
        let authoritativeTurkishTitle = authoritativeTurkishTitleOverride(
            for: dua.categoryId,
            fallback: legacyOverride?.title ?? dua.title.tr
        )
        let localizedTitleMap = HisnulMuslimContentRefiner.refinedTitleMap(
            dua.title.asDictionary,
            entryID: dua.id,
            turkishOverride: authoritativeTurkishTitle,
            transliterationMap: dua.transliteration.asDictionary,
            meaningMap: dua.meaning.asDictionary,
            arabicText: dua.arabicText
        )
        let localizedTransliterationMap = HisnulMuslimContentRefiner.refinedTransliterationMap(
            mergedLocalizedMap(dua.transliteration.asDictionary, turkishOverride: legacyOverride?.transliteration),
            entryID: dua.id
        )
        let localizedMeaningMap = HisnulMuslimContentRefiner.refinedMeaningMap(
            mergedLocalizedMap(dua.meaning.asDictionary, turkishOverride: legacyOverride?.meaning),
            entryID: dua.id
        )
        let localizedPurposeMap = mergedLocalizedMap(
            guidePurposeMap(for: guideTabID),
            turkishOverride: legacyOverride?.purpose
        )
        let localizedSourceLabelMap = HisnulMuslimContentRefiner.localizedSourceLabelMap(for: dua.source)
        let sourceLabel = localizedSourceLabelMap["tr"] ?? localizedSourceLabelMap["en"] ?? ""
        let fallbackPurpose = localizedPurposeMap["tr"] ?? localizedPurposeMap["en"] ?? dua.shortExplanation.tr
        let fallbackTitle = localizedTitleMap["tr"] ?? localizedTitleMap["en"] ?? dua.title.tr
        let fallbackTransliteration = localizedTransliterationMap["tr"] ?? localizedTransliterationMap["en"] ?? ""
        let fallbackMeaning = localizedMeaningMap["tr"] ?? localizedMeaningMap["en"] ?? dua.meaning.tr
        let mappedCategory = RehberCategory(rawValue: guideTabID) ?? .hisnulMuslim

        return RehberEntry(
            id: dua.id,
            title: fallbackTitle,
            arabicText: dua.arabicText,
            transliteration: fallbackTransliteration,
            meaning: fallbackMeaning,
            purpose: fallbackPurpose,
            recommendedCount: 1,
            category: mappedCategory,
            moodTags: moodTags(from: dua.usageContext),
            guideTabID: guideTabID,
            sourceLabel: sourceLabel,
            verificationStatus: sanitizedVerificationStatus(dua.verification.status),
            localizedTitleMap: localizedTitleMap,
            localizedTransliterationMap: localizedTransliterationMap,
            localizedMeaningMap: localizedMeaningMap,
            localizedPurposeMap: localizedPurposeMap,
            localizedSourceLabelMap: localizedSourceLabelMap
        )
    }

    private static func mergedLocalizedMap(
        _ base: [String: String],
        turkishOverride: String?
    ) -> [String: String] {
        guard let turkishOverride = sanitizedLocalizedValue(turkishOverride) else {
            return base
        }

        var result = base
        result["tr"] = turkishOverride
        return result
    }

    private static func sanitizedLocalizedValue(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func moodTags(from usageContext: GuideUsageContext) -> [String] {
        let tags = Set(usageContext.tags + (usageContext.emotionalStates ?? []))
        var result = Set<String>()

        if tags.contains("gratitude") {
            result.insert(MoodFilter.sukur.rawValue)
        }

        if tags.contains("sadness") || tags.contains("fear") || tags.contains("anxiety") || tags.contains("stress") {
            result.insert(MoodFilter.huzursuz.rawValue)
            result.insert(MoodFilter.dardaKaldim.rawValue)
        }

        return Array(result)
    }

    private static func localizedValue(from map: [String: String]) -> String {
        let current = RabiaAppLanguage.currentCode()
        for code in [current, "en", "ar"].map(RabiaAppLanguage.normalizedCode(for:)) {
            if let value = map[code]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }

        return map["en"] ?? ""
    }

    private static func authoritativeTurkishTitleOverride(
        for categoryID: String,
        fallback: String
    ) -> String {
        switch categoryID {
        case "hisn_chapter_005_before_undressing":
            return "Elbise Çıkarırken Yapılan Duâ"
        case "hisn_chapter_006_before_entering_the_bathroom":
            return "Tuvalete Girmeden Önce Yapılan Duâ"
        case "hisn_chapter_007_after_leaving_the_bathroom":
            return "Tuvaletten Çıktıktan Sonra Yapılan Duâ"
        case "hisn_chapter_008_before_ablution":
            return "Abdestten Önce Yapılan Duâ"
        case "hisn_chapter_009_upon_completing_the_ablution":
            return "Abdestten Sonra Yapılan Duâ"
        case "hisn_chapter_010_remembrance_when_leaving_the_home":
            return "Evden Çıkarken Yapılan Duâ"
        case "hisn_chapter_011_remembrance_upon_entering_the_home":
            return "Eve Girerken Yapılan Duâ"
        case "hisn_chapter_012_when_going_to_the_mosque":
            return "Câmiye Giderken Yapılan Duâ"
        case "hisn_chapter_013_upon_entering_the_mosque":
            return "Câmiye Girerken Yapılan Duâ"
        case "hisn_chapter_014_upon_leaving_the_mosque":
            return "Câmiden Çıkarken Yapılan Duâ"
        default:
            return fallback
        }
    }

    private static func guidePurposeMap(for guideTabID: String) -> [String: String] {
        switch guideTabID {
        case RehberCategory.gunlukRutinler.rawValue:
            return [
                "tr": "Bu dua Hüsnü'l Müslim'de günlük ibadet ve rutinler arasında yer alır. İlgili vakitte okunur ve kaynak bilgisiyle birlikte takip edilir.",
                "ar": "يرد هذا الدعاء في حصن المسلم ضمن أذكار العبادة والروتين اليومي، ويُقرأ في وقته المناسب مع متابعة ملاحظة المصدر.",
                "en": "This supplication appears in Hisn al-Muslim among daily worship and routine remembrances. It is read at the appropriate time with the source note kept in view.",
                "fr": "Cette invocation figure dans Hisn al-Muslim parmi les adorations et routines quotidiennes. Elle se lit au moment opportun en gardant la note de source visible.",
                "de": "Dieses Bittgebet erscheint in Hisn al-Muslim unter den taeglichen Andachten und Routinen. Es wird zur passenden Zeit mit sichtbarer Quellenangabe gelesen.",
                "id": "Doa ini terdapat dalam Hisn al-Muslim di antara zikir ibadah dan rutinitas harian. Doa ini dibaca pada waktunya dengan tetap memperhatikan catatan sumber.",
                "ms": "Doa ini terdapat dalam Hisn al-Muslim dalam zikir ibadah dan rutin harian. Ia dibaca pada waktu yang sesuai sambil merujuk catatan sumber.",
                "fa": "اين دعا در حصن المسلم در ميان اذكار عبادت و برنامه هاي روزانه آمده است. در زمان مناسب خوانده مي شود و يادداشت منبع نيز همراه آن ديده مي شود.",
                "ru": "Это дуа приводится в Hisn al-Muslim среди ежедневных поклонений и повседневных зикров. Его читают в подходящее время, сохраняя пометку об источнике.",
                "es": "Esta suplica aparece en Hisn al-Muslim entre los recuerdos de adoracion y rutina diaria. Se recita en el momento adecuado manteniendo visible la nota de la fuente.",
                "ur": "یہ دعا حصن المسلم میں روز مرہ عبادت اور معمول کے اذکار میں شامل ہے۔ اسے مناسب وقت پر ماخذ کے نوٹ کے ساتھ پڑھا جاتا ہے۔"
            ]
        case RehberCategory.duygusalDurumlar.rawValue:
            return [
                "tr": "Bu dua Hüsnü'l Müslim'de kaygı, sıkıntı ve iç daralması gibi haller için aktarılır. Gerektiğinde okunur ve kaynak bilgisiyle birlikte takip edilir.",
                "ar": "يرد هذا الدعاء في حصن المسلم للحالات التي يمر فيها المرء بالقلق والضيق وانقباض الصدر، ويُقرأ عند الحاجة مع متابعة ملاحظة المصدر.",
                "en": "This supplication is transmitted in Hisn al-Muslim for moments of anxiety, distress, and inner constriction. It is read when needed with the source note kept in view.",
                "fr": "Cette invocation est rapportee dans Hisn al-Muslim pour les moments d'anxiete, de detresse et de resserrement interieur. Elle se lit au besoin avec la note de source visible.",
                "de": "Dieses Bittgebet wird in Hisn al-Muslim fuer Zeiten von Angst, Bedrueckung und innerer Enge ueberliefert. Es wird bei Bedarf mit sichtbarer Quellenangabe gelesen.",
                "id": "Doa ini diriwayatkan dalam Hisn al-Muslim untuk saat-saat cemas, sempit, dan gelisah. Doa ini dibaca ketika diperlukan sambil tetap melihat catatan sumber.",
                "ms": "Doa ini disebut dalam Hisn al-Muslim untuk saat kegelisahan, kesempitan dan keresahan hati. Ia dibaca apabila perlu bersama catatan sumber.",
                "fa": "اين دعا در حصن المسلم براي لحظه هاي اضطراب، تنگي و فشار دروني نقل شده است. هنگام نياز خوانده مي شود و يادداشت منبع نيز همراه آن ديده مي شود.",
                "ru": "Это дуа передано в Hisn al-Muslim для моментов тревоги, стеснения и душевной тяжести. Его читают по мере необходимости, сохраняя пометку об источнике.",
                "es": "Esta suplica se transmite en Hisn al-Muslim para momentos de ansiedad, angustia y opresion interior. Se recita cuando hace falta manteniendo visible la nota de la fuente.",
                "ur": "یہ دعا حصن المسلم میں گھبراہٹ، تنگی اور دل کی بے چینی کے لمحات کے لیے منقول ہے۔ ضرورت کے وقت اسے ماخذ کے نوٹ کے ساتھ پڑھا جاتا ہے۔"
            ]
        case RehberCategory.hayatDurumlari.rawValue:
            return [
                "tr": "Bu dua Hüsnü'l Müslim'de yolculuk, aile, hastalık ve benzeri hayat durumları için aktarılır. Uygun durumda okunur ve kaynak bilgisiyle birlikte takip edilir.",
                "ar": "يرد هذا الدعاء في حصن المسلم لمواقف الحياة مثل السفر والعائلة والمرض وما شابه ذلك، ويُقرأ في الحال المناسبة مع متابعة ملاحظة المصدر.",
                "en": "This supplication is transmitted in Hisn al-Muslim for life situations such as travel, family, illness, and similar circumstances. It is read in the relevant situation with the source note kept in view.",
                "fr": "Cette invocation est rapportee dans Hisn al-Muslim pour des situations de vie comme le voyage, la famille, la maladie et d'autres circonstances semblables. Elle se lit dans le contexte approprie avec la note de source visible.",
                "de": "Dieses Bittgebet wird in Hisn al-Muslim fuer Lebenslagen wie Reise, Familie, Krankheit und aehnliche Umstaende ueberliefert. Es wird in der passenden Situation mit sichtbarer Quellenangabe gelesen.",
                "id": "Doa ini diriwayatkan dalam Hisn al-Muslim untuk keadaan hidup seperti perjalanan, keluarga, sakit, dan kondisi serupa. Doa ini dibaca sesuai keadaan sambil tetap melihat catatan sumber.",
                "ms": "Doa ini disebut dalam Hisn al-Muslim untuk keadaan hidup seperti musafir, keluarga, sakit dan situasi yang seumpamanya. Ia dibaca mengikut keadaan bersama catatan sumber.",
                "fa": "اين دعا در حصن المسلم براي موقعيت هاي زندگي مانند سفر، خانواده، بيماري و شرايط مشابه نقل شده است. در موقعيت مناسب خوانده مي شود و يادداشت منبع نيز همراه آن ديده مي شود.",
                "ru": "Это дуа передано в Hisn al-Muslim для жизненных ситуаций, таких как путешествие, семья, болезнь и подобные обстоятельства. Его читают в соответствующем случае, сохраняя пометку об источнике.",
                "es": "Esta suplica se transmite en Hisn al-Muslim para situaciones de la vida como viaje, familia, enfermedad y circunstancias similares. Se recita en el contexto adecuado manteniendo visible la nota de la fuente.",
                "ur": "یہ دعا حصن المسلم میں سفر، خاندان، بیماری اور اسی طرح کے حالات کے لیے منقول ہے۔ مناسب موقع پر اسے ماخذ کے نوٹ کے ساتھ پڑھا جاتا ہے۔"
            ]
        default:
            return [
                "tr": "Bu dua Hüsnü'l Müslim derlemesinde yer alır. İlgili durumda okunur ve kaynak bilgisiyle birlikte takip edilir.",
                "ar": "يرد هذا الدعاء في مجموعة حصن المسلم، ويُقرأ في الحال المناسبة مع متابعة ملاحظة المصدر.",
                "en": "This supplication appears in the Hisn al-Muslim collection. It is read in the relevant situation with the source note kept in view.",
                "fr": "Cette invocation figure dans la collection Hisn al-Muslim. Elle se lit dans la situation appropriee avec la note de source visible.",
                "de": "Dieses Bittgebet erscheint in der Sammlung Hisn al-Muslim. Es wird in der passenden Situation mit sichtbarer Quellenangabe gelesen.",
                "id": "Doa ini terdapat dalam koleksi Hisn al-Muslim. Doa ini dibaca pada keadaan yang relevan dengan tetap memperhatikan catatan sumber.",
                "ms": "Doa ini terdapat dalam koleksi Hisn al-Muslim. Ia dibaca pada keadaan yang sesuai sambil merujuk catatan sumber.",
                "fa": "اين دعا در مجموعه حصن المسلم آمده است. در موقعيت مناسب خوانده مي شود و يادداشت منبع نيز همراه آن ديده مي شود.",
                "ru": "Это дуа входит в сборник Hisn al-Muslim. Его читают в соответствующей ситуации, сохраняя пометку об источнике.",
                "es": "Esta suplica aparece en la coleccion Hisn al-Muslim. Se recita en la situacion adecuada manteniendo visible la nota de la fuente.",
                "ur": "یہ دعا حصن المسلم کے مجموعے میں شامل ہے۔ مناسب حالت میں اسے ماخذ کے نوٹ کے ساتھ پڑھا جاتا ہے۔"
            ]
        }
    }

    private static func sanitizedVerificationStatus(_ status: GuideVerificationStatus) -> GuideVerificationStatus? {
        switch status {
        case .needsReview:
            return nil
        case .verified, .unknown:
            return status
        }
    }
}
