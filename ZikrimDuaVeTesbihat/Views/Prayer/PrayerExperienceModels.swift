import Foundation
import SwiftUI

enum PrayerMomentState: String, Sendable {
    case past
    case current
    case upcoming
}

enum PrayerGradientProfile: String, Sendable {
    case predawn
    case sunrise
    case daylight
    case afternoon
    case dusk
    case night
}

enum PrayerCompletionStatus: String, CaseIterable, Codable, Sendable {
    case unknown
    case prayed
    case missed

    var localizedTitle: String {
        switch self {
        case .unknown:
            return String(localized: "prayer_completion_unknown", defaultValue: "Henüz işaretlenmedi")
        case .prayed:
            return String(localized: "prayer_completion_prayed", defaultValue: "Kılındı")
        case .missed:
            return String(localized: "prayer_completion_missed", defaultValue: "Kaçırıldı")
        }
    }

    var shortLabel: String {
        switch self {
        case .unknown:
            return String(localized: "prayer_completion_unknown_short", defaultValue: "İşaretle")
        case .prayed:
            return String(localized: "prayer_completion_prayed_short", defaultValue: "Kılındı")
        case .missed:
            return String(localized: "prayer_completion_missed_short", defaultValue: "Kaçırıldı")
        }
    }

    var systemImage: String {
        switch self {
        case .unknown:
            return "circle.dashed"
        case .prayed:
            return "checkmark.circle.fill"
        case .missed:
            return "minus.circle.fill"
        }
    }

    var next: PrayerCompletionStatus {
        switch self {
        case .unknown:
            return .prayed
        case .prayed:
            return .missed
        case .missed:
            return .unknown
        }
    }
}

struct QadaTracker: Identifiable, Codable, Sendable {
    let prayerType: PrayerName
    var missedCount: Int
    var completedQadaCount: Int
    var userAdjustedValue: Int?

    nonisolated var id: PrayerName { prayerType }

    nonisolated var outstandingCount: Int {
        max(userAdjustedValue ?? missedCount, 0)
    }
}

struct QadaCalculationPlan: Codable, Equatable, Sendable {
    let yearsNotPrayed: Int
    let estimatedDays: Int
    let createdAt: Date

    nonisolated var estimatedCountPerPrayer: Int {
        estimatedDays
    }
}

struct QadaCalculationPreview: Equatable, Sendable {
    let yearsNotPrayed: Int
    let estimatedCountPerPrayer: Int
    let totalOutstanding: Int

    nonisolated var isReset: Bool {
        yearsNotPrayed == 0
    }
}

struct PrayerQadaCenterContext: Identifiable, Hashable, Sendable {
    let sourceDate: Date?
    let suggestedPrayers: [PrayerName]

    var id: String {
        let dayID = sourceDate.map { PrayerQadaCenterContext.idFormatter.string(from: $0) } ?? "general"
        let prayersID = suggestedPrayers.map(\.rawValue).joined(separator: "-")
        return "\(dayID)-\(prayersID)"
    }

    static let general = PrayerQadaCenterContext(sourceDate: nil, suggestedPrayers: [])

    private static let idFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct PrayerDailyProgress: Sendable {
    let completedCount: Int
    let totalCount: Int

    var progressFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var summaryText: String {
        "\(completedCount)/\(totalCount) namaz tamamlandi"
    }
}

struct PrayerHistoryDay: Identifiable, Sendable {
    let date: Date
    let completionCount: Int
    let totalCount: Int
    let statuses: [PrayerName: PrayerCompletionStatus]

    var id: String {
        PrayerHistoryDay.idFormatter.string(from: date)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var progressFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completionCount) / Double(totalCount)
    }

    var missedPrayers: [PrayerName] {
        PrayerName.obligatoryCases.filter { statuses[$0] == .missed }
    }

    var missedPrayerNames: [String] {
        missedPrayers.map(\.qadaDisplayName)
    }

    var hasMissedPrayers: Bool {
        !missedPrayers.isEmpty
    }

    private static let idFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct PrayerDisplayItem: Identifiable, Sendable {
    let id: PrayerName
    let localizedName: String
    let time: Date
    let formattedTime: String
    let state: PrayerMomentState
    let endTime: Date?
    let iconType: String
    let reminderEnabled: Bool
    let gradientProfile: PrayerGradientProfile
    let contextualMessageCandidates: [String]
    let completionState: PrayerCompletionStatus?

    var primaryMessage: String {
        PrayerMicroMessageCatalog.message(
            from: contextualMessageCandidates,
            seed: time
        )
    }
}

extension PrayerName {
    nonisolated static var obligatoryCases: [PrayerName] {
        allCases.filter(\.isObligatory)
    }

    nonisolated var isObligatory: Bool {
        self != .sunrise
    }

    nonisolated var dailyListDisplayName: String {
        switch self {
        case .fajr:
            return String(localized: "prayer_daily_list_fajr_name", defaultValue: "İmsak / Sabah")
        default:
            return localizedName
        }
    }

    nonisolated var qadaDisplayName: String {
        switch self {
        case .fajr:
            return String(localized: "prayer_qada_fajr_name", defaultValue: "Sabah")
        case .sunrise:
            return localizedName
        default:
            return localizedName
        }
    }
}

extension PrayerCompletionStatus {
    nonisolated static func defaultStatusMap() -> [PrayerName: PrayerCompletionStatus] {
        Dictionary(uniqueKeysWithValues: PrayerName.obligatoryCases.map { ($0, .unknown) })
    }
}

extension QadaTracker {
    nonisolated static func defaultTrackers() -> [PrayerName: QadaTracker] {
        Dictionary(uniqueKeysWithValues: PrayerName.obligatoryCases.map {
            ($0, QadaTracker(prayerType: $0, missedCount: 0, completedQadaCount: 0, userAdjustedValue: nil))
        })
    }
}

struct PrayerToolItem: Identifiable, Sendable {
    enum Kind: Sendable {
        case notifications
        case qibla
        case calculation
        case location
    }

    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let kind: Kind
}

struct PrayerExtraModule: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
}

struct PrayerViewModel: Sendable {
    let locationName: String
    let gregorianDateText: String
    let weekdayText: String
    let hijriDateText: String
    let sourceText: String
    let calculationText: String
    let items: [PrayerDisplayItem]
    let currentPrayer: PrayerDisplayItem
    let displayedPrayer: PrayerDisplayItem
    let nextTransitionPrayer: PrayerDisplayItem
    let countdownText: String
    let heroEyebrow: String
    let heroStatusText: String
    let compactTimelineItems: [PrayerDisplayItem]
    let toolItems: [PrayerToolItem]
    let extraModules: [PrayerExtraModule]

    init?(
        liveViewModel: PrayerTimesViewModel,
        settings: PrayerSettings,
        now: Date = Date(),
        selectedPrayer: PrayerName? = nil,
        locale: Locale = Locale(identifier: RabiaAppLanguage.currentCode())
    ) {
        guard let prayerTimes = liveViewModel.prayerTimes else { return nil }

        let calendar = PrayerViewModel.calendar(for: prayerTimes.timeZone, locale: locale)
        let items = PrayerViewModel.makeItems(
            prayerTimes: prayerTimes,
            tomorrowPrayerTimes: liveViewModel.tomorrowPrayerTimes,
            settings: settings,
            now: now,
            locale: locale,
            calendar: calendar
        )
        guard let currentPrayer = items.first(where: { $0.state == .current }) else { return nil }

        let displayedPrayer = items.first(where: { $0.id == selectedPrayer }) ?? currentPrayer
        let nextTransitionPrayer = PrayerViewModel.nextTransition(
            after: displayedPrayer,
            from: items,
            currentPrayer: currentPrayer,
            prayerTimes: prayerTimes,
            tomorrowPrayerTimes: liveViewModel.tomorrowPrayerTimes,
            locale: locale,
            calendar: calendar
        )

        locationName = liveViewModel.locationDisplayName
        gregorianDateText = PrayerViewModel.gregorianDateText(now, locale: locale, timeZone: prayerTimes.timeZone)
        weekdayText = PrayerViewModel.weekdayText(now, locale: locale, timeZone: prayerTimes.timeZone)
        hijriDateText = liveViewModel.hijriDate
        sourceText = PrayerViewModel.prayerSourceText(
            from: prayerTimes.sourceName ?? settings.calculationMethod.displayName
        )
        calculationText = settings.calculationMethod.displayName
        self.items = items
        self.currentPrayer = currentPrayer
        self.displayedPrayer = displayedPrayer
        self.nextTransitionPrayer = nextTransitionPrayer
        countdownText = PrayerViewModel.countdownText(from: now, to: nextTransitionPrayer.time, calendar: calendar)
        heroEyebrow = PrayerViewModel.heroEyebrow(for: displayedPrayer, currentPrayer: currentPrayer)
        heroStatusText = PrayerViewModel.heroStatusText(
            displayedPrayer: displayedPrayer,
            currentPrayer: currentPrayer,
            nextTransitionPrayer: nextTransitionPrayer,
            countdownText: countdownText,
            calendar: calendar,
            locale: locale
        )
        compactTimelineItems = PrayerViewModel.compactTimelineItems(
            from: items,
            currentPrayer: currentPrayer,
            now: now,
            locale: locale,
            calendar: calendar
        )
        toolItems = [
            PrayerToolItem(
                id: "notifications",
                title: String(localized: "prayer_tools_notifications_title", defaultValue: "Bildirimler"),
                subtitle: settings.prayerNotificationsEnabled
                    ? settings.reminderOffset.shortName
                    : String(localized: "prayer_tools_notifications_subtitle", defaultValue: "Ezan ve hatırlatıcılar"),
                icon: "bell.badge.fill",
                kind: .notifications
            ),
            PrayerToolItem(
                id: "qibla",
                title: String(localized: "prayer_tools_qibla_title", defaultValue: "Kıble bulucu"),
                subtitle: String(localized: "prayer_tools_qibla_subtitle", defaultValue: "Yönünü hızlıca bul"),
                icon: "location.north.line.fill",
                kind: .qibla
            ),
            PrayerToolItem(
                id: "calculation",
                title: String(localized: "prayer_tools_calculation_title", defaultValue: "Hesaplama yöntemi"),
                subtitle: String(localized: "prayer_tools_calculation_subtitle", defaultValue: "Diyanet vakitleri"),
                icon: "slider.horizontal.3",
                kind: .calculation
            ),
            PrayerToolItem(
                id: "location",
                title: String(localized: "prayer_tools_location_title", defaultValue: "Konum ve şehir"),
                subtitle: liveViewModel.locationChipText,
                icon: "mappin.and.ellipse",
                kind: .location
            )
        ]
        extraModules = [
            PrayerExtraModule(
                id: "qada",
                title: String(localized: "prayer_extra_qada_title", defaultValue: "Kaza namazları"),
                subtitle: String(localized: "prayer_extra_qada_subtitle", defaultValue: "Takip, hesaplama ve kayıt alanı"),
                icon: "clock.arrow.circlepath"
            ),
            PrayerExtraModule(
                id: "nafl",
                title: String(localized: "prayer_extra_nafl_title", defaultValue: "Nafile namazlar"),
                subtitle: String(localized: "prayer_extra_nafl_subtitle", defaultValue: "Duha, İşrak, Evvabin"),
                icon: "sparkles"
            ),
            PrayerExtraModule(
                id: "tahajjud",
                title: String(localized: "prayer_extra_tahajjud_title", defaultValue: "Teheccüd"),
                subtitle: String(localized: "prayer_extra_tahajjud_subtitle", defaultValue: "Gece ibadeti için vakit"),
                icon: "moon.stars"
            ),
            PrayerExtraModule(
                id: "tasbih",
                title: String(localized: "prayer_extra_tasbih_title", defaultValue: "Tesbih namazı"),
                subtitle: String(localized: "prayer_extra_tasbih_subtitle", defaultValue: "Özel ibadet rehberi"),
                icon: "circle.hexagongrid.fill"
            )
        ]
    }

    init(
        locationName: String,
        gregorianDateText: String,
        weekdayText: String,
        hijriDateText: String,
        sourceText: String,
        calculationText: String,
        items: [PrayerDisplayItem],
        selectedPrayer: PrayerName? = nil,
        now: Date = Date(),
        locale: Locale = Locale(identifier: "tr_TR"),
        timeZone: TimeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
    ) {
        let calendar = PrayerViewModel.calendar(for: timeZone, locale: locale)
        let currentPrayer = items.first(where: { $0.state == .current }) ?? items.last ?? PrayerViewModel.previewFallbackItem(now: now, timeZone: timeZone)
        let displayedPrayer = items.first(where: { $0.id == selectedPrayer }) ?? currentPrayer
        let nextTransitionPrayer = items.first(where: { $0.id == displayedPrayer.id && $0.state == .current })
            .flatMap { _ in PrayerViewModel.previewNextTransition(from: items, currentPrayer: currentPrayer, timeZone: timeZone) }
            ?? PrayerViewModel.previewNextTransition(from: items, currentPrayer: displayedPrayer, timeZone: timeZone)
            ?? currentPrayer

        self.locationName = locationName
        self.gregorianDateText = gregorianDateText
        self.weekdayText = weekdayText
        self.hijriDateText = hijriDateText
        self.sourceText = sourceText
        self.calculationText = calculationText
        self.items = items
        self.currentPrayer = currentPrayer
        self.displayedPrayer = displayedPrayer
        self.nextTransitionPrayer = nextTransitionPrayer
        countdownText = PrayerViewModel.countdownText(from: now, to: nextTransitionPrayer.time, calendar: calendar)
        heroEyebrow = PrayerViewModel.heroEyebrow(for: displayedPrayer, currentPrayer: currentPrayer)
        heroStatusText = PrayerViewModel.heroStatusText(
            displayedPrayer: displayedPrayer,
            currentPrayer: currentPrayer,
            nextTransitionPrayer: nextTransitionPrayer,
            countdownText: countdownText,
            calendar: calendar,
            locale: locale
        )
        compactTimelineItems = PrayerViewModel.compactTimelineItems(
            from: items,
            currentPrayer: currentPrayer,
            now: now,
            locale: locale,
            calendar: calendar
        )
        toolItems = [
            PrayerToolItem(
                id: "notifications",
                title: "Bildirimler",
                subtitle: "Ezan ve hatırlatıcılar",
                icon: "bell.badge.fill",
                kind: .notifications
            ),
            PrayerToolItem(
                id: "qibla",
                title: "Kıble bulucu",
                subtitle: "Yönünü hızlıca bul",
                icon: "location.north.line.fill",
                kind: .qibla
            ),
            PrayerToolItem(
                id: "calculation",
                title: "Hesaplama yöntemi",
                subtitle: "Diyanet vakitleri",
                icon: "slider.horizontal.3",
                kind: .calculation
            ),
            PrayerToolItem(
                id: "location",
                title: "Konum ve şehir",
                subtitle: locationName,
                icon: "mappin.and.ellipse",
                kind: .location
            )
        ]
        extraModules = [
            PrayerExtraModule(id: "qada", title: "Kaza namazları", subtitle: "Takip, hesaplama ve kayıt alanı", icon: "clock.arrow.circlepath"),
            PrayerExtraModule(id: "nafl", title: "Nafile namazlar", subtitle: "Duha, İşrak, Evvabin", icon: "sparkles"),
            PrayerExtraModule(id: "tahajjud", title: "Teheccüd", subtitle: "Gece ibadeti için vakit", icon: "moon.stars"),
            PrayerExtraModule(id: "tasbih", title: "Tesbih namazı", subtitle: "Özel ibadet rehberi", icon: "circle.hexagongrid.fill")
        ]
    }

    var compactTimelineText: String {
        compactTimelineItems
            .map { "\($0.localizedName) \($0.formattedTime)" }
            .joined(separator: " • ")
    }

    var heroMessage: String {
        displayedPrayer.primaryMessage
    }

    var dayProgressTitle: String {
        String(localized: "prayer_day_progress_title", defaultValue: "Günün ritmi")
    }

    var listSectionTitle: String {
        String(localized: "prayer_list_section_title", defaultValue: "Bugünkü vakitler")
    }

    var listSectionSubtitle: String {
        String(localized: "prayer_list_section_subtitle", defaultValue: "Geçen, şu anki ve yaklaşan vakitleri tek bakışta gör")
    }

    var toolsSectionTitle: String {
        String(localized: "prayer_tools_section_title", defaultValue: "Araçlar ve ayarlar")
    }

    var extrasSectionTitle: String {
        String(localized: "prayer_extras_section_title", defaultValue: "Kaza ve diğer namazlar")
    }

    var extrasSectionSubtitle: String {
        String(localized: "prayer_extras_section_subtitle", defaultValue: "Kaza, nafile ve gece ibadetleri için ayrı alanlar")
    }
}

enum PrayerGradientProvider {
    struct Style {
        let profile: PrayerGradientProfile
        let heroGradient: LinearGradient
        let accent: Color
        let accentSecondary: Color
        let glow: Color
        let ring: Color
    }

    static func profile(for prayer: PrayerName) -> PrayerGradientProfile {
        switch prayer {
        case .fajr:
            return .predawn
        case .sunrise:
            return .sunrise
        case .dhuhr:
            return .daylight
        case .asr:
            return .afternoon
        case .maghrib:
            return .dusk
        case .isha:
            return .night
        }
    }

    static func style(for prayer: PrayerName, theme: ActiveTheme) -> Style {
        style(for: profile(for: prayer), theme: theme)
    }

    static func style(for profile: PrayerGradientProfile, theme: ActiveTheme) -> Style {
        let isDarkMode = theme.isDarkMode

        switch profile {
        case .predawn:
            return Style(
                profile: profile,
                heroGradient: LinearGradient(
                    colors: isDarkMode
                        ? [Color(red: 0.07, green: 0.10, blue: 0.27), Color(red: 0.06, green: 0.30, blue: 0.38)]
                        : [Color(red: 0.18, green: 0.28, blue: 0.56), Color(red: 0.35, green: 0.68, blue: 0.74)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                accent: Color(red: 0.56, green: 0.88, blue: 0.92),
                accentSecondary: Color(red: 0.71, green: 0.92, blue: 1.0),
                glow: Color(red: 0.41, green: 0.81, blue: 0.86).opacity(isDarkMode ? 0.30 : 0.22),
                ring: Color(red: 0.61, green: 0.93, blue: 0.96)
            )
        case .sunrise:
            return Style(
                profile: profile,
                heroGradient: LinearGradient(
                    colors: isDarkMode
                        ? [Color(red: 0.23, green: 0.16, blue: 0.20), Color(red: 0.47, green: 0.30, blue: 0.18)]
                        : [Color(red: 0.83, green: 0.63, blue: 0.39), Color(red: 0.97, green: 0.82, blue: 0.56)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                accent: Color(red: 0.99, green: 0.82, blue: 0.55),
                accentSecondary: Color(red: 1.0, green: 0.90, blue: 0.72),
                glow: Color(red: 0.93, green: 0.70, blue: 0.38).opacity(isDarkMode ? 0.24 : 0.18),
                ring: Color(red: 0.98, green: 0.79, blue: 0.48)
            )
        case .daylight:
            return Style(
                profile: profile,
                heroGradient: LinearGradient(
                    colors: isDarkMode
                        ? [Color(red: 0.08, green: 0.20, blue: 0.33), Color(red: 0.11, green: 0.38, blue: 0.49)]
                        : [Color(red: 0.30, green: 0.61, blue: 0.88), Color(red: 0.55, green: 0.84, blue: 0.96)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                accent: Color(red: 0.60, green: 0.88, blue: 0.98),
                accentSecondary: Color(red: 0.82, green: 0.95, blue: 1.0),
                glow: Color(red: 0.44, green: 0.72, blue: 0.95).opacity(isDarkMode ? 0.24 : 0.18),
                ring: Color(red: 0.59, green: 0.87, blue: 1.0)
            )
        case .afternoon:
            return Style(
                profile: profile,
                heroGradient: LinearGradient(
                    colors: isDarkMode
                        ? [Color(red: 0.10, green: 0.18, blue: 0.18), Color(red: 0.24, green: 0.35, blue: 0.25)]
                        : [Color(red: 0.43, green: 0.62, blue: 0.46), Color(red: 0.78, green: 0.82, blue: 0.58)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                accent: Color(red: 0.83, green: 0.83, blue: 0.58),
                accentSecondary: Color(red: 0.92, green: 0.90, blue: 0.72),
                glow: Color(red: 0.71, green: 0.70, blue: 0.41).opacity(isDarkMode ? 0.22 : 0.18),
                ring: Color(red: 0.86, green: 0.86, blue: 0.62)
            )
        case .dusk:
            return Style(
                profile: profile,
                heroGradient: LinearGradient(
                    colors: isDarkMode
                        ? [Color(red: 0.18, green: 0.10, blue: 0.16), Color(red: 0.36, green: 0.19, blue: 0.23), Color(red: 0.12, green: 0.24, blue: 0.34)]
                        : [Color(red: 0.84, green: 0.49, blue: 0.34), Color(red: 0.93, green: 0.71, blue: 0.46), Color(red: 0.39, green: 0.57, blue: 0.73)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                accent: Color(red: 0.99, green: 0.73, blue: 0.50),
                accentSecondary: Color(red: 0.98, green: 0.84, blue: 0.70),
                glow: Color(red: 0.88, green: 0.45, blue: 0.34).opacity(isDarkMode ? 0.24 : 0.18),
                ring: Color(red: 0.99, green: 0.71, blue: 0.50)
            )
        case .night:
            return Style(
                profile: profile,
                heroGradient: LinearGradient(
                    colors: isDarkMode
                        ? [Color(red: 0.04, green: 0.08, blue: 0.18), Color(red: 0.07, green: 0.17, blue: 0.30)]
                        : [Color(red: 0.13, green: 0.21, blue: 0.42), Color(red: 0.19, green: 0.43, blue: 0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                accent: Color(red: 0.55, green: 0.88, blue: 0.91),
                accentSecondary: Color(red: 0.76, green: 0.94, blue: 0.95),
                glow: Color(red: 0.34, green: 0.73, blue: 0.80).opacity(isDarkMode ? 0.28 : 0.20),
                ring: Color(red: 0.62, green: 0.92, blue: 0.94)
            )
        }
    }
}

enum PrayerMicroMessageCatalog {
    static func messages(for prayer: PrayerName) -> [String] {
        switch prayer {
        case .fajr:
            return [
                String(localized: "prayer_message_fajr_1", defaultValue: "Güne niyetle başla"),
                String(localized: "prayer_message_fajr_2", defaultValue: "Elhamdulillah yeni bir sabah için")
            ]
        case .sunrise:
            return [
                String(localized: "prayer_message_sunrise_1", defaultValue: "Işığı fark etmek de bir şükürdür"),
                String(localized: "prayer_message_sunrise_2", defaultValue: "Yeni gün Bismillah ile başlıyor")
            ]
        case .dhuhr:
            return [
                String(localized: "prayer_message_dhuhr_1", defaultValue: "Gün ortasında kısa bir durak"),
                String(localized: "prayer_message_dhuhr_2", defaultValue: "Kalbini yeniden topla")
            ]
        case .asr:
            return [
                String(localized: "prayer_message_asr_1", defaultValue: "Kalan vakti zikir ve şükürle tamamla"),
                String(localized: "prayer_message_asr_2", defaultValue: "Küçük bir durak günün yönünü değiştirir")
            ]
        case .maghrib:
            return [
                String(localized: "prayer_message_maghrib_1", defaultValue: "Günün yükünü bırak"),
                String(localized: "prayer_message_maghrib_2", defaultValue: "Subhanallah ×33")
            ]
        case .isha:
            return [
                String(localized: "prayer_message_isha_1", defaultValue: "Sükunet burada başlar"),
                String(localized: "prayer_message_isha_2", defaultValue: "Geceyi zikirle yumuşat")
            ]
        }
    }

    static func message(from candidates: [String], seed: Date) -> String {
        guard !candidates.isEmpty else { return "" }
        let daySeed = Calendar(identifier: .gregorian).ordinality(of: .day, in: .year, for: seed) ?? 0
        return candidates[abs(daySeed) % candidates.count]
    }
}

extension PrayerViewModel {
    static func preview(
        current prayer: PrayerName,
        selectedPrayer: PrayerName? = nil,
        themeTimeZone: TimeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
    ) -> PrayerViewModel {
        let baseDate = Self.previewBaseDate(for: prayer, timeZone: themeTimeZone)
        let allItems = Self.previewItems(now: baseDate, timeZone: themeTimeZone)
        return PrayerViewModel(
            locationName: "Istanbul",
            gregorianDateText: "20 Mart 2026",
            weekdayText: "Cuma",
            hijriDateText: "10 Ramazan 1447",
            sourceText: "Diyanet",
            calculationText: "Diyanet vakitleri",
            items: allItems,
            selectedPrayer: selectedPrayer ?? prayer,
            now: baseDate,
            locale: Locale(identifier: "tr_TR"),
            timeZone: themeTimeZone
        )
    }

    private static func makeItems(
        prayerTimes: PrayerTimes,
        tomorrowPrayerTimes: PrayerTimes?,
        settings: PrayerSettings,
        now: Date,
        locale: Locale,
        calendar: Calendar
    ) -> [PrayerDisplayItem] {
        let activePrayer = activePrayerName(prayerTimes: prayerTimes, now: now)
        let formattedTime: (Date) -> String = { date in
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.timeZone = prayerTimes.timeZone
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }

        return PrayerName.allCases.map { prayer in
            let state: PrayerMomentState
            if now < prayerTimes.fajr {
                state = prayer == .isha ? .current : .upcoming
            } else if prayer == activePrayer {
                state = .current
            } else if let activeIndex = PrayerName.allCases.firstIndex(of: activePrayer),
                      let itemIndex = PrayerName.allCases.firstIndex(of: prayer),
                      itemIndex < activeIndex {
                state = .past
            } else {
                state = .upcoming
            }

            return PrayerDisplayItem(
                id: prayer,
                localizedName: prayer.localizedName,
                time: effectiveTime(
                    for: prayer,
                    prayerTimes: prayerTimes,
                    tomorrowPrayerTimes: tomorrowPrayerTimes,
                    now: now,
                    calendar: calendar
                ),
                formattedTime: formattedTime(
                    effectiveTime(
                        for: prayer,
                        prayerTimes: prayerTimes,
                        tomorrowPrayerTimes: tomorrowPrayerTimes,
                        now: now,
                        calendar: calendar
                    )
                ),
                state: state,
                endTime: endTime(
                    for: prayer,
                    prayerTimes: prayerTimes,
                    tomorrowPrayerTimes: tomorrowPrayerTimes,
                    calendar: calendar
                ),
                iconType: prayer.systemImage,
                reminderEnabled: settings.prayerNotificationsEnabled,
                gradientProfile: PrayerGradientProvider.profile(for: prayer),
                contextualMessageCandidates: PrayerMicroMessageCatalog.messages(for: prayer),
                completionState: nil
            )
        }
    }

    static func activePrayerName(prayerTimes: PrayerTimes, now: Date) -> PrayerName {
        if now < prayerTimes.fajr { return .isha }
        if now < prayerTimes.sunrise { return .fajr }
        if now < prayerTimes.dhuhr { return .sunrise }
        if now < prayerTimes.asr { return .dhuhr }
        if now < prayerTimes.maghrib { return .asr }
        if now < prayerTimes.isha { return .maghrib }
        return .isha
    }

    static func prayerSourceText(from source: String) -> String {
        if source.caseInsensitiveCompare("Diyanet") == .orderedSame {
            return L10n.string(.diyanetIsleriBaskanligi)
        }
        return source
    }

    private static func nextTransition(
        after displayedPrayer: PrayerDisplayItem,
        from items: [PrayerDisplayItem],
        currentPrayer: PrayerDisplayItem,
        prayerTimes: PrayerTimes,
        tomorrowPrayerTimes: PrayerTimes?,
        locale: Locale,
        calendar: Calendar
    ) -> PrayerDisplayItem {
        if displayedPrayer.state == .current {
            if displayedPrayer.id == .isha,
               let tomorrowPrayerTimes {
                return PrayerDisplayItem(
                    id: .fajr,
                    localizedName: PrayerName.fajr.localizedName,
                    time: tomorrowPrayerTimes.fajr,
                    formattedTime: formattedTime(tomorrowPrayerTimes.fajr, locale: locale, timeZone: prayerTimes.timeZone),
                    state: .upcoming,
                    endTime: tomorrowPrayerTimes.sunrise,
                    iconType: PrayerName.fajr.systemImage,
                    reminderEnabled: displayedPrayer.reminderEnabled,
                    gradientProfile: PrayerGradientProvider.profile(for: .fajr),
                    contextualMessageCandidates: PrayerMicroMessageCatalog.messages(for: .fajr),
                    completionState: nil
                )
            }

            if let currentIndex = PrayerName.allCases.firstIndex(of: displayedPrayer.id) {
                let nextIndex = min(currentIndex + 1, PrayerName.allCases.count - 1)
                return items[nextIndex]
            }
        }

        return displayedPrayer
    }

    private static func compactTimelineItems(
        from items: [PrayerDisplayItem],
        currentPrayer: PrayerDisplayItem,
        now: Date,
        locale: Locale,
        calendar: Calendar
    ) -> [PrayerDisplayItem] {
        if now < items.first(where: { $0.id == .fajr })?.time ?? .distantPast {
            let fajr = items.first(where: { $0.id == .fajr })
            let sunrise = items.first(where: { $0.id == .sunrise })
            return [currentPrayer, fajr, sunrise].compactMap { $0 }
        }

        guard let currentIndex = items.firstIndex(where: { $0.id == currentPrayer.id }) else {
            return Array(items.prefix(3))
        }

        return Array(items[currentIndex...].prefix(3))
    }

    private static func effectiveTime(
        for prayer: PrayerName,
        prayerTimes: PrayerTimes,
        tomorrowPrayerTimes: PrayerTimes?,
        now: Date,
        calendar: Calendar
    ) -> Date {
        if prayer == .isha, now < prayerTimes.fajr {
            return calendar.date(byAdding: .day, value: -1, to: prayerTimes.isha) ?? prayerTimes.isha
        }

        return prayerTimes.allTimes[prayer] ?? prayerTimes.fajr
    }

    private static func endTime(
        for prayer: PrayerName,
        prayerTimes: PrayerTimes,
        tomorrowPrayerTimes: PrayerTimes?,
        calendar: Calendar
    ) -> Date? {
        switch prayer {
        case .fajr:
            return prayerTimes.sunrise
        case .sunrise:
            return prayerTimes.dhuhr
        case .dhuhr:
            return prayerTimes.asr
        case .asr:
            return prayerTimes.maghrib
        case .maghrib:
            return prayerTimes.isha
        case .isha:
            return tomorrowPrayerTimes?.fajr ?? calendar.date(byAdding: .day, value: 1, to: prayerTimes.fajr)
        }
    }

    private static func heroEyebrow(for displayedPrayer: PrayerDisplayItem, currentPrayer: PrayerDisplayItem) -> String {
        if displayedPrayer.id == currentPrayer.id {
            return String(localized: "prayer_hero_eyebrow_current", defaultValue: "Şu anki vakit")
        }

        switch displayedPrayer.state {
        case .past:
            return String(localized: "prayer_hero_eyebrow_past", defaultValue: "Geçen vakit")
        case .current:
            return String(localized: "prayer_hero_eyebrow_current", defaultValue: "Şu anki vakit")
        case .upcoming:
            return String(localized: "prayer_hero_eyebrow_upcoming", defaultValue: "Yaklaşan vakit")
        }
    }

    private static func heroStatusText(
        displayedPrayer: PrayerDisplayItem,
        currentPrayer: PrayerDisplayItem,
        nextTransitionPrayer: PrayerDisplayItem,
        countdownText: String,
        calendar: Calendar,
        locale: Locale
    ) -> String {
        if displayedPrayer.id == currentPrayer.id {
            return "\(nextTransitionPrayer.localizedName) vaktine \(countdownText)"
        }

        switch displayedPrayer.state {
        case .past:
            return String(localized: "prayer_hero_status_past", defaultValue: "Bu vakit bugün geçti")
        case .current:
            return "\(nextTransitionPrayer.localizedName) vaktine \(countdownText)"
        case .upcoming:
            return "\(countdownText) sonra başlıyor"
        }
    }

    static func countdownText(from now: Date, to target: Date, calendar: Calendar) -> String {
        let totalMinutes = max(Int(target.timeIntervalSince(now) / 60), 0)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours) sa \(minutes) dk"
        }

        return "\(minutes) dk"
    }

    private static func gregorianDateText(_ date: Date, locale: Locale, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private static func weekdayText(_ date: Date, locale: Locale, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private static func formattedTime(_ date: Date, locale: Locale, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private static func calendar(for timeZone: TimeZone, locale: Locale) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        calendar.timeZone = timeZone
        return calendar
    }

    private static func previewBaseDate(for prayer: PrayerName, timeZone: TimeZone) -> Date {
        let baseDay = Date(timeIntervalSince1970: 1_773_969_600) // 2026-03-20 00:00:00 UTC
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let time: String
        switch prayer {
        case .fajr:
            time = "05:45"
        case .sunrise:
            time = "06:48"
        case .dhuhr:
            time = "12:34"
        case .asr:
            time = "16:41"
        case .maghrib:
            time = "19:08"
        case .isha:
            time = "21:07"
        }

        let parts = time.split(separator: ":")
        return calendar.date(
            bySettingHour: Int(parts[0]) ?? 12,
            minute: Int(parts[1]) ?? 0,
            second: 0,
            of: baseDay
        ) ?? baseDay
    }

    private static func previewItems(now: Date, timeZone: TimeZone) -> [PrayerDisplayItem] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let schedule: [(PrayerName, String)] = [
            (.fajr, "05:32"),
            (.sunrise, "06:51"),
            (.dhuhr, "12:28"),
            (.asr, "16:42"),
            (.maghrib, "19:11"),
            (.isha, "20:37")
        ]

        let activePrayer: PrayerName
        if now < scheduleDate("05:32", calendar: calendar, base: now) {
            activePrayer = .isha
        } else if now < scheduleDate("06:51", calendar: calendar, base: now) {
            activePrayer = .fajr
        } else if now < scheduleDate("12:28", calendar: calendar, base: now) {
            activePrayer = .sunrise
        } else if now < scheduleDate("16:42", calendar: calendar, base: now) {
            activePrayer = .dhuhr
        } else if now < scheduleDate("19:11", calendar: calendar, base: now) {
            activePrayer = .asr
        } else if now < scheduleDate("20:37", calendar: calendar, base: now) {
            activePrayer = .maghrib
        } else {
            activePrayer = .isha
        }

        return schedule.map { prayer, value in
            let baseTime = scheduleDate(value, calendar: calendar, base: now)
            let effectiveTime = prayer == .isha && now < scheduleDate("05:32", calendar: calendar, base: now)
                ? calendar.date(byAdding: .day, value: -1, to: baseTime) ?? baseTime
                : baseTime
            let state: PrayerMomentState
            if now < scheduleDate("05:32", calendar: calendar, base: now) {
                state = prayer == .isha ? .current : .upcoming
            } else if prayer == activePrayer {
                state = .current
            } else if let activeIndex = PrayerName.allCases.firstIndex(of: activePrayer),
                      let currentIndex = PrayerName.allCases.firstIndex(of: prayer),
                      currentIndex < activeIndex {
                state = .past
            } else {
                state = .upcoming
            }

            return PrayerDisplayItem(
                id: prayer,
                localizedName: prayer.localizedName,
                time: effectiveTime,
                formattedTime: formattedTime(effectiveTime, locale: Locale(identifier: "tr_TR"), timeZone: timeZone),
                state: state,
                endTime: nil,
                iconType: prayer.systemImage,
                reminderEnabled: prayer == .fajr || prayer == .isha,
                gradientProfile: PrayerGradientProvider.profile(for: prayer),
                contextualMessageCandidates: PrayerMicroMessageCatalog.messages(for: prayer),
                completionState: nil
            )
        }
    }

    private static func scheduleDate(_ value: String, calendar: Calendar, base: Date) -> Date {
        let parts = value.split(separator: ":")
        return calendar.date(
            bySettingHour: Int(parts[0]) ?? 0,
            minute: Int(parts[1]) ?? 0,
            second: 0,
            of: base
        ) ?? base
    }

    private static func previewNextTransition(
        from items: [PrayerDisplayItem],
        currentPrayer: PrayerDisplayItem,
        timeZone: TimeZone
    ) -> PrayerDisplayItem? {
        guard let currentIndex = items.firstIndex(where: { $0.id == currentPrayer.id }) else { return nil }
        if currentIndex < items.count - 1 {
            return items[currentIndex + 1]
        }

        let tomorrowFajr = Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: items[0].time) ?? items[0].time
        return PrayerDisplayItem(
            id: .fajr,
            localizedName: PrayerName.fajr.localizedName,
            time: tomorrowFajr,
            formattedTime: formattedTime(tomorrowFajr, locale: Locale(identifier: "tr_TR"), timeZone: timeZone),
            state: .upcoming,
            endTime: nil,
            iconType: PrayerName.fajr.systemImage,
            reminderEnabled: true,
            gradientProfile: PrayerGradientProvider.profile(for: .fajr),
            contextualMessageCandidates: PrayerMicroMessageCatalog.messages(for: .fajr),
            completionState: nil
        )
    }

    private static func previewFallbackItem(now: Date, timeZone: TimeZone) -> PrayerDisplayItem {
        PrayerDisplayItem(
            id: .isha,
            localizedName: PrayerName.isha.localizedName,
            time: now,
            formattedTime: formattedTime(now, locale: Locale(identifier: "tr_TR"), timeZone: timeZone),
            state: .current,
            endTime: nil,
            iconType: PrayerName.isha.systemImage,
            reminderEnabled: true,
            gradientProfile: .night,
            contextualMessageCandidates: PrayerMicroMessageCatalog.messages(for: .isha),
            completionState: nil
        )
    }
}
