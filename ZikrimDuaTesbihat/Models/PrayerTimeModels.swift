import Foundation

nonisolated struct PrayerTimes: Codable, Sendable {
    let fajr: String
    let sunrise: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    let date: String
    let city: String

    enum CodingKeys: String, CodingKey {
        case fajr = "Fajr"
        case sunrise = "Sunrise"
        case dhuhr = "Dhuhr"
        case asr = "Asr"
        case maghrib = "Maghrib"
        case isha = "Isha"
        case date
        case city
    }

    init(fajr: String, sunrise: String, dhuhr: String, asr: String, maghrib: String, isha: String, date: String, city: String) {
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
        self.date = date
        self.city = city
    }
}

nonisolated struct AladhanResponse: Codable, Sendable {
    let code: Int
    let data: AladhanData
}

nonisolated struct AladhanData: Codable, Sendable {
    let timings: AladhanTimings
    let date: AladhanDate
}

nonisolated struct AladhanTimings: Codable, Sendable {
    let Fajr: String
    let Sunrise: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String
}

nonisolated struct AladhanDate: Codable, Sendable {
    let readable: String
    let hijri: AladhanHijri
    let gregorian: AladhanGregorian
}

nonisolated struct AladhanHijri: Codable, Sendable {
    let date: String
    let month: AladhanMonth
    let year: String
    let day: String
}

nonisolated struct AladhanGregorian: Codable, Sendable {
    let date: String
    let weekday: AladhanWeekday
}

nonisolated struct AladhanMonth: Codable, Sendable {
    let number: Int
    let en: String
    let ar: String
}

nonisolated struct AladhanWeekday: Codable, Sendable {
    let en: String
}

nonisolated struct TurkishCity: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let englishName: String
}

nonisolated enum PrayerName: String, CaseIterable, Sendable {
    case fajr = "İmsak"
    case sunrise = "Güneş"
    case dhuhr = "Öğle"
    case asr = "İkindi"
    case maghrib = "Akşam"
    case isha = "Yatsı"

    var systemImage: String {
        switch self {
        case .fajr: return "moon.stars.fill"
        case .sunrise: return "sunrise.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.haze.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.fill"
        }
    }

    var color: String {
        switch self {
        case .fajr: return "indigo"
        case .sunrise: return "orange"
        case .dhuhr: return "yellow"
        case .asr: return "green"
        case .maghrib: return "red"
        case .isha: return "purple"
        }
    }
}
