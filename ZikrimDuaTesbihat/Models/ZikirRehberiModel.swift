import Foundation

nonisolated enum RehberCategory: String, Codable, CaseIterable, Sendable {
    case favoriler = "favoriler"
    case gunlukRutinler = "gunluk_rutinler"
    case duygusalDurumlar = "duygusal_durumlar"
    case hayatDurumlari = "hayat_durumlari"
    case kisaTesbihatlar = "kisa_tesbihatlar"
    case kuranDualari = "kuran_dualari"
    case rabbena = "rabbena"
    case esmaülHüsna = "esmaulhusna"
    case hisnulMuslim = "hisnul_muslim"
    case cevsen = "cevsen"
    case kullanici = "kullanici"

    var displayName: String {
        switch self {
        case .favoriler: return "Favoriler"
        case .gunlukRutinler: return "Günlük Rutinler"
        case .duygusalDurumlar: return "Duygusal Durumlar"
        case .hayatDurumlari: return "Hayat Durumları"
        case .kisaTesbihatlar: return "Kısa Tesbih"
        case .kuranDualari: return "Kur'an Duaları"
        case .rabbena: return "Rabbena Duaları"
        case .esmaülHüsna: return "Esmaül Hüsna"
        case .hisnulMuslim: return "Hisn'ul Müslim"
        case .cevsen: return "Cevşen"
        case .kullanici: return "Eklediklerim"
        }
    }

    var icon: String {
        switch self {
        case .favoriler: return "heart.fill"
        case .gunlukRutinler: return "sun.max.fill"
        case .duygusalDurumlar: return "brain.head.profile"
        case .hayatDurumlari: return "leaf.fill"
        case .kisaTesbihatlar: return "circle.grid.3x3.fill"
        case .kuranDualari: return "book.closed.fill"
        case .rabbena: return "hands.sparkles.fill"
        case .esmaülHüsna: return "star.circle.fill"
        case .hisnulMuslim: return "shield.lefthalf.filled"
        case .cevsen: return "sparkles"
        case .kullanici: return "person.crop.circle.badge.plus"
        }
    }
}

nonisolated enum MoodFilter: String, CaseIterable, Sendable {
    case huzursuz = "huzursuz"
    case sukur = "sukur"
    case dardaKaldim = "darda_kaldim"
    case hastaOldum = "hasta_oldum"
    case sinavBasarisi = "sinav"

    var displayName: String {
        switch self {
        case .huzursuz: return "Huzursuzum"
        case .sukur: return "Şükrediyorum"
        case .dardaKaldim: return "Darda Kaldım"
        case .hastaOldum: return "Hasta Oldum"
        case .sinavBasarisi: return "Sınav Var"
        }
    }

    var icon: String {
        switch self {
        case .huzursuz: return "cloud.rain.fill"
        case .sukur: return "sun.max.fill"
        case .dardaKaldim: return "exclamationmark.triangle.fill"
        case .hastaOldum: return "cross.fill"
        case .sinavBasarisi: return "graduationcap.fill"
        }
    }
}

nonisolated struct RehberEntry: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let title: String
    let arabicText: String
    let transliteration: String
    let meaning: String
    let purpose: String
    let recommendedCount: Int
    let recommendedCountNote: String?
    let category: RehberCategory
    let notes: String?
    let schedule: String?
    let isInformational: Bool
    let moodTags: [String]

    init(
        id: String,
        title: String,
        arabicText: String,
        transliteration: String,
        meaning: String,
        purpose: String,
        recommendedCount: Int,
        recommendedCountNote: String? = nil,
        category: RehberCategory,
        notes: String? = nil,
        schedule: String? = nil,
        isInformational: Bool = false,
        moodTags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.meaning = meaning
        self.purpose = purpose
        self.recommendedCount = recommendedCount
        self.recommendedCountNote = recommendedCountNote
        self.category = category
        self.notes = notes
        self.schedule = schedule
        self.isInformational = isInformational
        self.moodTags = moodTags
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RehberEntry, rhs: RehberEntry) -> Bool {
        lhs.id == rhs.id
    }
}
