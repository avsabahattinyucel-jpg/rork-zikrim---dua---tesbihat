import SwiftUI
import WidgetKit

private let prayerOrder = ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"]

private func localizedText(_ key: StaticString, defaultValue: String.LocalizationValue) -> String {
    String(localized: key, defaultValue: defaultValue)
}

private enum WidgetTitle {
    static var signature: String { localizedText("widget_signature_title", defaultValue: "İmza Widget") }
    static var prayerFocus: String { localizedText("widget_prayer_focus_title", defaultValue: "Sıradaki Vakit") }
    static var dhikrProgress: String { localizedText("widget_dhikr_progress_title", defaultValue: "Günlük Zikir") }
    static var prayerTimeline: String { localizedText("widget_prayer_timeline_title", defaultValue: "Tüm Vakitler") }
    static var prayerDhikr: String { localizedText("widget_prayer_dhikr_title", defaultValue: "Namaz ve Zikir") }
    static var spiritualDashboard: String { localizedText("widget_spiritual_dashboard_title", defaultValue: "Manevi Özet") }
    static var noorSpotlight: String { localizedText("widget_noor_spotlight_title", defaultValue: "Hikmet Kartı") }
    static var auraFlow: String { localizedText("widget_aura_flow_title", defaultValue: "Namaz Ritmi") }
    static var majlisGlow: String { localizedText("widget_majlis_glow_title", defaultValue: "Manevi Vitrin") }
}

struct ZikrimWidgetEntry: TimelineEntry {
    let date: Date
    let isPremiumUnlocked: Bool
    let fallbackNextPrayerName: String
    let fallbackNextPrayerTime: String
    let fallbackNextPrayerIcon: String
    let fallbackNextPrayerDate: Date?
    let city: String
    let dailyProgress: Int
    let dailyCount: Int
    let dailyGoal: Int
    let currentStreak: Int
    let dailyWisdom: String
    let dailyVerseMetadata: String
    let dailyVerseText: String
    let dailyVerseSource: String?
    let dailyHadithTitle: String
    let dailyHadithText: String
    let dailyHadithAttribution: String?
    let dailyHadithLanguage: String
    let prayerSchedule: [String: Date]
    let prayerTimeLabels: [String: String]
    let tomorrowFajr: Date?

    static var placeholder: ZikrimWidgetEntry {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let schedule = [
            "fajr": calendar.date(byAdding: .minute, value: 330, to: start) ?? Date(),
            "sunrise": calendar.date(byAdding: .minute, value: 420, to: start) ?? Date(),
            "dhuhr": calendar.date(byAdding: .minute, value: 766, to: start) ?? Date(),
            "asr": calendar.date(byAdding: .minute, value: 975, to: start) ?? Date(),
            "maghrib": calendar.date(byAdding: .minute, value: 1132, to: start) ?? Date(),
            "isha": calendar.date(byAdding: .minute, value: 1245, to: start) ?? Date()
        ]
        let tomorrowFajr = calendar.date(byAdding: .day, value: 1, to: schedule["fajr"] ?? start)

        return ZikrimWidgetEntry(
            date: Date(),
            isPremiumUnlocked: true,
            fallbackNextPrayerName: "dhuhr",
            fallbackNextPrayerTime: "12:46",
            fallbackNextPrayerIcon: "sun.max.fill",
            fallbackNextPrayerDate: schedule["dhuhr"],
            city: "Sivas, Türkiye",
            dailyProgress: 14,
            dailyCount: 14,
            dailyGoal: 100,
            currentStreak: 3,
            dailyWisdom: L10n.string(.dailyWisdom1),
            dailyVerseMetadata: L10n.format(.surahVerseFormat, "Ra'd", Int64(28)),
            dailyVerseText: "Bilesiniz ki kalpler ancak Allah'ı anmakla huzur bulur.",
            dailyVerseSource: L10n.string(.diyanetIsleriBaskanligi),
            dailyHadithTitle: localizedText("daily_hadith_card_title", defaultValue: "Günün Hadisi"),
            dailyHadithText: "Ameller niyetlere göredir.",
            dailyHadithAttribution: "Buhari 1",
            dailyHadithLanguage: "tr",
            prayerSchedule: schedule,
            prayerTimeLabels: Dictionary(uniqueKeysWithValues: schedule.map { ($0.key, WidgetClock.formatted($0.value)) }),
            tomorrowFajr: tomorrowFajr
        )
    }
}

func normalizePrayerKey(_ name: String) -> String {
    switch name.lowercased() {
    case "imsak", "fajr", "sabah":
        return "fajr"
    case "güneş", "gunes", "sunrise":
        return "sunrise"
    case "öğle", "ogle", "dhuhr":
        return "dhuhr"
    case "ikindi", "asr":
        return "asr"
    case "akşam", "aksam", "maghrib":
        return "maghrib"
    case "yatsı", "yatsi", "isha":
        return "isha"
    default:
        return name.lowercased()
    }
}

struct ZikrimProvider: TimelineProvider {
    private static let suiteName = "group.app.rork.pu2jopnhgtfk3o9m6amda.2de8110f.shared"

    func placeholder(in context: Context) -> ZikrimWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ZikrimWidgetEntry) -> Void) {
        completion(loadEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ZikrimWidgetEntry>) -> Void) {
        let baseEntry = loadEntry(at: Date())
        let timelineDates = timelineDates(for: baseEntry)
        let entries = timelineDates.map { loadEntry(at: $0, base: baseEntry) }
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }

    private func loadEntry(at date: Date, base: ZikrimWidgetEntry? = nil) -> ZikrimWidgetEntry {
        let defaults = UserDefaults(suiteName: Self.suiteName)

        let fallbackName = defaults?.string(forKey: "widget_next_prayer_name") ?? base?.fallbackNextPrayerName ?? ZikrimWidgetEntry.placeholder.fallbackNextPrayerName
        let fallbackTime = defaults?.string(forKey: "widget_next_prayer_time") ?? base?.fallbackNextPrayerTime ?? ZikrimWidgetEntry.placeholder.fallbackNextPrayerTime
        let fallbackIcon = defaults?.string(forKey: "widget_next_prayer_icon") ?? base?.fallbackNextPrayerIcon ?? ZikrimWidgetEntry.placeholder.fallbackNextPrayerIcon
        let isPremiumUnlocked = defaults?.bool(forKey: "widget_premium_access") ?? base?.isPremiumUnlocked ?? false
        let city = defaults?.string(forKey: "widget_next_prayer_city") ?? base?.city ?? ZikrimWidgetEntry.placeholder.city
        let progress = defaults?.integer(forKey: "widget_daily_progress") ?? base?.dailyProgress ?? ZikrimWidgetEntry.placeholder.dailyProgress
        let dailyCount = defaults?.integer(forKey: "widget_daily_count") ?? base?.dailyCount ?? ZikrimWidgetEntry.placeholder.dailyCount
        let dailyGoal = defaults?.integer(forKey: "widget_daily_goal") ?? base?.dailyGoal ?? ZikrimWidgetEntry.placeholder.dailyGoal
        let streak = defaults?.integer(forKey: "widget_current_streak") ?? base?.currentStreak ?? ZikrimWidgetEntry.placeholder.currentStreak
        let wisdom = defaults?.string(forKey: "widget_daily_wisdom") ?? base?.dailyWisdom ?? L10n.string(.widgetDefaultWisdom)
        let dailyVerseMetadata = defaults?.string(forKey: "widget_daily_verse_metadata") ?? base?.dailyVerseMetadata ?? ZikrimWidgetEntry.placeholder.dailyVerseMetadata
        let dailyVerseText = defaults?.string(forKey: "widget_daily_verse_text") ?? base?.dailyVerseText ?? ZikrimWidgetEntry.placeholder.dailyVerseText
        let dailyVerseSource = defaults?.string(forKey: "widget_daily_verse_source") ?? base?.dailyVerseSource ?? ZikrimWidgetEntry.placeholder.dailyVerseSource
        let dailyHadithTitle = defaults?.string(forKey: "widget_daily_hadith_title") ?? base?.dailyHadithTitle ?? ZikrimWidgetEntry.placeholder.dailyHadithTitle
        let dailyHadithText = defaults?.string(forKey: "widget_daily_hadith_text") ?? base?.dailyHadithText ?? ZikrimWidgetEntry.placeholder.dailyHadithText
        let dailyHadithAttribution = defaults?.string(forKey: "widget_daily_hadith_attribution") ?? base?.dailyHadithAttribution ?? ZikrimWidgetEntry.placeholder.dailyHadithAttribution
        let dailyHadithLanguage = defaults?.string(forKey: "widget_daily_hadith_language") ?? base?.dailyHadithLanguage ?? ZikrimWidgetEntry.placeholder.dailyHadithLanguage
        let fallbackNextPrayerDate = readDate(forKey: "widget_next_prayer_date", defaults: defaults) ?? base?.fallbackNextPrayerDate
        let tomorrowFajr = readDate(forKey: "widget_tomorrow_fajr_date", defaults: defaults) ?? base?.tomorrowFajr

        let prayerLabels = normalizedDictionary(
            defaults?.dictionary(forKey: "widget_all_prayer_times"),
            fallback: base?.prayerTimeLabels ?? ZikrimWidgetEntry.placeholder.prayerTimeLabels
        )
        let schedule = normalizedDateDictionary(
            defaults?.dictionary(forKey: "widget_prayer_schedule_timestamps"),
            fallback: base?.prayerSchedule ?? ZikrimWidgetEntry.placeholder.prayerSchedule
        )

        return ZikrimWidgetEntry(
            date: date,
            isPremiumUnlocked: isPremiumUnlocked,
            fallbackNextPrayerName: normalizePrayerKey(fallbackName),
            fallbackNextPrayerTime: fallbackTime,
            fallbackNextPrayerIcon: fallbackIcon,
            fallbackNextPrayerDate: fallbackNextPrayerDate,
            city: city,
            dailyProgress: progress,
            dailyCount: dailyCount,
            dailyGoal: dailyGoal,
            currentStreak: streak,
            dailyWisdom: wisdom,
            dailyVerseMetadata: dailyVerseMetadata,
            dailyVerseText: dailyVerseText,
            dailyVerseSource: dailyVerseSource,
            dailyHadithTitle: dailyHadithTitle,
            dailyHadithText: dailyHadithText,
            dailyHadithAttribution: dailyHadithAttribution,
            dailyHadithLanguage: dailyHadithLanguage,
            prayerSchedule: schedule,
            prayerTimeLabels: prayerLabels,
            tomorrowFajr: tomorrowFajr
        )
    }

    private func timelineDates(for entry: ZikrimWidgetEntry) -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        let endOfWindow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now.addingTimeInterval(86_400)
        var dates: Set<Date> = [now]

        var cursor = now
        while cursor < endOfWindow {
            dates.insert(cursor)
            cursor = cursor.addingTimeInterval(900)
        }

        for prayerDate in entry.prayerSchedule.values {
            if prayerDate > now, prayerDate < endOfWindow {
                dates.insert(prayerDate)
            }
        }

        if let tomorrowFajr = entry.tomorrowFajr, tomorrowFajr > now, tomorrowFajr < endOfWindow {
            dates.insert(tomorrowFajr)
        }

        if let fallbackNextPrayerDate = entry.fallbackNextPrayerDate, fallbackNextPrayerDate > now, fallbackNextPrayerDate < endOfWindow {
            dates.insert(fallbackNextPrayerDate)
        }

        return dates.sorted()
    }

    private func readDate(forKey key: String, defaults: UserDefaults?) -> Date? {
        guard let interval = defaults?.object(forKey: key) as? Double, interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    private func normalizedDictionary(_ raw: [String: Any]?, fallback: [String: String]) -> [String: String] {
        guard let raw else { return fallback }
        var result: [String: String] = [:]
        for (key, value) in raw {
            if let stringValue = value as? String {
                result[normalizePrayerKey(key)] = stringValue
            }
        }
        return result.isEmpty ? fallback : result
    }

    private func normalizedDateDictionary(_ raw: [String: Any]?, fallback: [String: Date]) -> [String: Date] {
        guard let raw else { return fallback }
        var result: [String: Date] = [:]

        for (key, value) in raw {
            if let interval = value as? Double {
                result[normalizePrayerKey(key)] = Date(timeIntervalSince1970: interval)
            } else if let number = value as? NSNumber {
                result[normalizePrayerKey(key)] = Date(timeIntervalSince1970: number.doubleValue)
            }
        }

        return result.isEmpty ? fallback : result
    }
}

private struct WidgetPrayerState {
    let name: String
    let time: Date?
    let fallbackText: String
    let icon: String
    let isTomorrow: Bool

    var displayName: String {
        prayerDisplayName(for: name)
    }

    var prayerColor: Color {
        prayerAccentColor(for: name)
    }

    var timeLabel: String {
        if let time {
            return WidgetClock.formatted(time)
        }
        return fallbackText
    }
}

private struct WidgetClock {
    static func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

private func resolvedPrayerState(for entry: ZikrimWidgetEntry) -> WidgetPrayerState {
    let referenceDate = entry.date
    let todaySchedule = prayerOrder.compactMap { key -> (String, Date)? in
        guard let time = entry.prayerSchedule[key] else { return nil }
        return (key, time)
    }

    if let upcoming = todaySchedule.first(where: { $0.1 > referenceDate }) {
        return WidgetPrayerState(
            name: upcoming.0,
            time: upcoming.1,
            fallbackText: entry.prayerTimeLabels[upcoming.0] ?? WidgetClock.formatted(upcoming.1),
            icon: prayerIcon(for: upcoming.0),
            isTomorrow: false
        )
    }

    if let tomorrowFajr = entry.tomorrowFajr, tomorrowFajr > referenceDate {
        return WidgetPrayerState(
            name: "fajr",
            time: tomorrowFajr,
            fallbackText: WidgetClock.formatted(tomorrowFajr),
            icon: prayerIcon(for: "fajr"),
            isTomorrow: true
        )
    }

    return WidgetPrayerState(
        name: normalizePrayerKey(entry.fallbackNextPrayerName),
        time: entry.fallbackNextPrayerDate,
        fallbackText: entry.fallbackNextPrayerTime,
        icon: entry.fallbackNextPrayerIcon,
        isTomorrow: false
    )
}

private func prayerDisplayName(for key: String) -> String {
    switch normalizePrayerKey(key) {
    case "fajr":
        return L10n.string(.prayerFajr)
    case "sunrise":
        return L10n.string(.prayerSunrise)
    case "dhuhr":
        return L10n.string(.prayerDhuhr)
    case "asr":
        return L10n.string(.prayerAsr)
    case "maghrib":
        return L10n.string(.prayerMaghrib)
    case "isha":
        return L10n.string(.prayerIsha)
    default:
        return key
    }
}

private func prayerIcon(for key: String) -> String {
    switch normalizePrayerKey(key) {
    case "fajr":
        return "moon.stars.fill"
    case "sunrise":
        return "sunrise.fill"
    case "dhuhr":
        return "sun.max.fill"
    case "asr":
        return "sun.haze.fill"
    case "maghrib":
        return "sunset.fill"
    case "isha":
        return "moon.fill"
    default:
        return "sparkles"
    }
}

private func prayerAccentColor(for key: String) -> Color {
    switch normalizePrayerKey(key) {
    case "fajr":
        return Color(hex: "#3E5C8A")
    case "sunrise":
        return Color(hex: "#E7C873")
    case "dhuhr":
        return Color(hex: "#2E8A7F")
    case "asr":
        return Color(hex: "#D89A49")
    case "maghrib":
        return Color(hex: "#7656A7")
    case "isha":
        return Color(hex: "#22314E")
    default:
        return Color(hex: "#E7C873")
    }
}

private struct WidgetNavigationContainer<Content: View>: View {
    let destination: URL?
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .widgetURL(destination)
    }
}

private struct PrayerFocusHomeWidgetView: View {
    let entry: ZikrimWidgetEntry
    private var prayer: WidgetPrayerState { resolvedPrayerState(for: entry) }

    var body: some View {
        WidgetNavigationContainer(destination: URL(string: "zikrim://prayer")) {
            VStack(alignment: .leading, spacing: 10) {
                WidgetBrandBar()

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 4) {
                    Text(prayer.displayName.uppercased(with: Locale.autoupdatingCurrent))
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)

                    if let time = prayer.time {
                        Text(time, style: .time)
                            .font(.system(.title, design: .rounded).weight(.semibold))
                            .monospacedDigit()
                    } else {
                        Text(prayer.timeLabel)
                            .font(.system(.title, design: .rounded).weight(.semibold))
                            .monospacedDigit()
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 4) {
                    Text(.widgetNextPrayerTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let time = prayer.time {
                        Text(time, style: .timer)
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .monospacedDigit()
                            .widgetAccentable()
                    } else {
                        Text(prayer.timeLabel)
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .monospacedDigit()
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(for: .widget) {
                PremiumWidgetBackground(accent: prayer.prayerColor)
            }
        }
    }
}

private struct PrayerFocusInlineAccessoryView: View {
    let prayer: WidgetPrayerState

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: prayer.icon)
                .widgetAccentable()

            Text(prayer.displayName)
                .lineLimit(1)

            if let time = prayer.time {
                Text(time, style: .time)
                    .monospacedDigit()
            } else {
                Text(prayer.timeLabel)
                    .monospacedDigit()
            }
        }
    }
}

private struct PrayerFocusCircularAccessoryView: View {
    let prayer: WidgetPrayerState

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 3) {
                Image(systemName: prayer.icon)
                    .font(.caption.weight(.semibold))
                    .widgetAccentable()

                if let time = prayer.time {
                    Text(time, format: .dateTime.hour().minute())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                } else {
                    Text(prayer.timeLabel)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
            }
            .padding(6)
        }
    }
}

private struct PrayerFocusRectangularAccessoryView: View {
    let prayer: WidgetPrayerState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(.widgetNextPrayerTitle)
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: prayer.icon)
                    .font(.caption.weight(.semibold))
                    .widgetAccentable()

                Text(prayer.displayName)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: 4)

                if let time = prayer.time {
                    Text(time, style: .time)
                        .font(.headline.weight(.bold))
                        .monospacedDigit()
                } else {
                    Text(prayer.timeLabel)
                        .font(.headline.weight(.bold))
                        .monospacedDigit()
                }
            }

            if let time = prayer.time {
                Text(time, style: .timer)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }
}

private struct PrayerFocusWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: ZikrimWidgetEntry
    private var prayer: WidgetPrayerState { resolvedPrayerState(for: entry) }

    @ViewBuilder
    var body: some View {
        WidgetNavigationContainer(destination: URL(string: "zikrim://prayer")) {
            switch family {
            case .accessoryInline:
                PrayerFocusInlineAccessoryView(prayer: prayer)
            case .accessoryCircular:
                PrayerFocusCircularAccessoryView(prayer: prayer)
            case .accessoryRectangular:
                PrayerFocusRectangularAccessoryView(prayer: prayer)
            default:
                PrayerFocusHomeWidgetView(entry: entry)
            }
        }
    }
}

private struct DhikrProgressWidgetView: View {
    let entry: ZikrimWidgetEntry

    var body: some View {
        WidgetNavigationContainer(destination: URL(string: "zikrim://dhikr")) {
            VStack(alignment: .leading, spacing: 12) {
                WidgetBrandBar()

                Spacer(minLength: 0)

                DhikrBeadRow(progress: progressFraction, beadCount: 10, accent: Color(hex: "#E7C873"), beadHeight: 12)
                    .widgetAccentable()

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.format(.countFractionFormat, Int64(entry.dailyCount), Int64(max(entry.dailyGoal, 1))))
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .monospacedDigit()

                    if entry.currentStreak > 0 {
                        Label(L10n.format(.widgetStreakDaysShort, Int64(entry.currentStreak)), systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(for: .widget) {
                PremiumWidgetBackground(accent: Color(hex: "#E7C873"))
            }
        }
    }

    private var progressFraction: Double {
        guard entry.dailyGoal > 0 else { return 0 }
        return min(max(Double(entry.dailyCount) / Double(entry.dailyGoal), 0), 1)
    }
}

private struct PrayerTimelineWidgetView: View {
    let entry: ZikrimWidgetEntry
    private var prayer: WidgetPrayerState { resolvedPrayerState(for: entry) }

    var body: some View {
        WidgetNavigationContainer(destination: URL(string: "zikrim://prayer-times")) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "location.north.line.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(entry.city.isEmpty ? L10n.string(.currentLocation) : entry.city)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                PrayerHeroMiniCard(prayer: prayer)

                HStack(spacing: 8) {
                    ForEach(prayerOrder, id: \.self) { key in
                        PrayerTimelineNode(
                            title: prayerDisplayName(for: key),
                            timeText: entry.prayerTimeLabels[key] ?? "—",
                            isActive: key == prayer.name,
                            accent: prayerAccentColor(for: key)
                        )
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(for: .widget) {
                PremiumWidgetBackground(accent: prayer.prayerColor)
            }
        }
    }
}

private struct PrayerDhikrWidgetView: View {
    let entry: ZikrimWidgetEntry
    private var prayer: WidgetPrayerState { resolvedPrayerState(for: entry) }

    var body: some View {
        WidgetNavigationContainer(destination: URL(string: "zikrim://prayer-times")) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    WidgetBrandBar()

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(prayer.displayName.uppercased(with: Locale.autoupdatingCurrent))
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        if let time = prayer.time {
                            Text(time, style: .time)
                                .font(.system(.title2, design: .rounded).weight(.semibold))
                                .monospacedDigit()
                        } else {
                            Text(prayer.timeLabel)
                                .font(.system(.title2, design: .rounded).weight(.semibold))
                                .monospacedDigit()
                        }
                    }

                    if let time = prayer.time {
                        Text(time, style: .timer)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 10) {
                    Text(.widgetDhikrTitleShort)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(L10n.format(.countFractionFormat, Int64(entry.dailyCount), Int64(max(entry.dailyGoal, 1))))
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .monospacedDigit()

                    DhikrBeadRow(progress: progressFraction, beadCount: 8, accent: Color(hex: "#E7C873"), beadHeight: 9)
                        .widgetAccentable()

                    if entry.currentStreak > 0 {
                        Label(L10n.format(.widgetStreakDaysShort, Int64(entry.currentStreak)), systemImage: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        )
                )
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(for: .widget) {
                PremiumWidgetBackground(accent: prayer.prayerColor)
            }
        }
    }

    private var progressFraction: Double {
        guard entry.dailyGoal > 0 else { return 0 }
        return min(max(Double(entry.dailyCount) / Double(entry.dailyGoal), 0), 1)
    }
}

private struct SpiritualDashboardWidgetView: View {
    let entry: ZikrimWidgetEntry
    private var prayer: WidgetPrayerState { resolvedPrayerState(for: entry) }

    var body: some View {
        WidgetNavigationContainer(destination: URL(string: "zikrim://dashboard")) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "building.columns.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(entry.city.isEmpty ? L10n.string(.currentLocation) : entry.city)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    WidgetBrandBar(compact: true)
                }

                HStack(spacing: 14) {
                    PrayerDashboardCard(prayer: prayer)
                    DhikrCircleCard(
                        count: entry.dailyCount,
                        goal: max(entry.dailyGoal, 1),
                        streak: entry.currentStreak
                    )
                }

                HStack(spacing: 8) {
                    ForEach(prayerOrder, id: \.self) { key in
                        PrayerTimelineNode(
                            title: prayerDisplayName(for: key),
                            timeText: entry.prayerTimeLabels[key] ?? "—",
                            isActive: key == prayer.name,
                            accent: prayerAccentColor(for: key)
                        )
                    }
                }

                Text(entry.dailyWisdom)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(for: .widget) {
                PremiumWidgetBackground(accent: prayer.prayerColor)
            }
        }
    }
}

private struct SignatureWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: ZikrimWidgetEntry

    @ViewBuilder
    var body: some View {
        switch family {
        case .systemSmall:
            PrayerFocusWidgetView(entry: entry)
        case .systemMedium:
            PrayerDhikrWidgetView(entry: entry)
        case .systemLarge:
            SpiritualDashboardWidgetView(entry: entry)
        default:
            PrayerFocusWidgetView(entry: entry)
        }
    }
}

private struct WidgetBrandBar: View {
    var compact: Bool = false

    var body: some View {
        EmptyView()
    }
}

private struct PrayerHeroMiniCard: View {
    let prayer: WidgetPrayerState

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(prayer.prayerColor.opacity(0.24))
                    .frame(width: 42, height: 42)
                    .widgetAccentable()
                Image(systemName: prayer.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(.widgetNextPrayerTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(prayer.displayName.uppercased(with: Locale.autoupdatingCurrent))
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .lineLimit(1)
                if let time = prayer.time {
                    Text(time, style: .time)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .monospacedDigit()
                } else {
                    Text(prayer.timeLabel)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .monospacedDigit()
                }
            }

            Spacer(minLength: 0)

            if let time = prayer.time {
                Text(time, style: .timer)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: prayer.prayerColor.opacity(0.25), radius: 18, y: 8)
        )
    }
}

private struct PrayerTimelineNode: View {
    let title: String
    let timeText: String
    let isActive: Bool
    let accent: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(isActive ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(timeText)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(isActive ? .primary : .secondary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Circle()
                .fill(isActive ? accent : .white.opacity(0.22))
                .frame(width: 8, height: 8)
                .shadow(color: isActive ? accent.opacity(0.6) : .clear, radius: 8)
                .widgetAccentable()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PrayerDashboardCard: View {
    let prayer: WidgetPrayerState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(.widgetNextPrayerTitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(prayer.displayName.uppercased(with: Locale.autoupdatingCurrent))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if let time = prayer.time {
                Text(time, style: .time)
                    .font(.system(.title, design: .rounded).weight(.semibold))
                    .monospacedDigit()
            } else {
                Text(prayer.timeLabel)
                    .font(.system(.title, design: .rounded).weight(.semibold))
                    .monospacedDigit()
            }

            if let time = prayer.time {
                Text(time, style: .timer)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: prayer.prayerColor.opacity(0.24), radius: 22, y: 10)
        )
    }
}

private struct DhikrCircleCard: View {
    let count: Int
    let goal: Int
    let streak: Int

    private var progress: Double {
        min(max(Double(count) / Double(goal), 0), 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.10), style: StrokeStyle(lineWidth: 10, lineCap: .round))

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [Color(hex: "#E7C873"), Color(hex: "#F3E3AE"), Color(hex: "#2E8A7F")],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .widgetAccentable()

                VStack(spacing: 2) {
                    Text(.widgetDhikrTitleShort)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(L10n.format(.countFractionFormat, Int64(count), Int64(goal)))
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .monospacedDigit()
                }
            }
            .frame(width: 110, height: 110)

            if streak > 0 {
                Label(L10n.format(.widgetStreakDaysShort, Int64(streak)), systemImage: "flame.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

private struct DhikrBeadRow: View {
    let progress: Double
    let beadCount: Int
    let accent: Color
    let beadHeight: CGFloat

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<beadCount, id: \.self) { index in
                let fill = beadFill(for: index)
                Capsule()
                    .fill(.white.opacity(0.12))
                    .frame(maxWidth: .infinity)
                    .frame(height: beadHeight)
                    .overlay(alignment: .leading) {
                        GeometryReader { geometry in
                            Capsule()
                                .fill(accent)
                                .frame(width: geometry.size.width * fill, height: beadHeight)
                        }
                    }
                    .overlay(
                        Capsule()
                            .strokeBorder(.white.opacity(0.08), lineWidth: 0.8)
                    )
            }
        }
    }

    private func beadFill(for index: Int) -> Double {
        let scaledProgress = progress * Double(beadCount)
        return min(max(scaledProgress - Double(index), 0), 1)
    }
}

private struct PremiumWidgetContainer<Content: View>: View {
    let entry: ZikrimWidgetEntry
    let premiumDestination: String
    @ViewBuilder let content: () -> Content

    private var destination: URL? {
        let route = entry.isPremiumUnlocked ? premiumDestination : "zikrim://more"
        return URL(string: route)
    }

    var body: some View {
        WidgetNavigationContainer(destination: destination) {
            content()
        }
    }
}

private struct PremiumStoryBadge: View {
    var title: String? = nil

    private var isDecorativeOnly: Bool {
        guard let title else { return true }
        return title.isEmpty
    }

    var body: some View {
        HStack(spacing: isDecorativeOnly ? 5 : 6) {
            Image(systemName: "crown.fill")
                .font(.system(size: isDecorativeOnly ? 10 : 11, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#FFF7D6"), Color(hex: "#E7C873")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            if let title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(hex: "#F6E8B1"))
            }
        }
        .foregroundStyle(Color(hex: "#1D1607"))
        .padding(.horizontal, isDecorativeOnly ? 9 : 10)
        .padding(.vertical, isDecorativeOnly ? 7 : 6)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isDecorativeOnly ? 0.16 : 0.10),
                            Color(hex: "#E7C873").opacity(isDecorativeOnly ? 0.28 : 0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            Capsule()
                .strokeBorder(Color(hex: "#F6E8B1").opacity(isDecorativeOnly ? 0.34 : 0.18), lineWidth: 0.8)
        )
        .shadow(color: Color(hex: "#E7C873").opacity(isDecorativeOnly ? 0.22 : 0.12), radius: isDecorativeOnly ? 10 : 6, y: 4)
    }
}

private enum PremiumWidgetCopy {
    static var noorLockedSubtitle: String {
        localizedText(
            "widget_noor_locked_subtitle",
            defaultValue: "Hikmet notunu zarif bir premium kart olarak ana ekrana taşır."
        )
    }

    static var auraLockedSubtitle: String {
        localizedText(
            "widget_aura_flow_locked_subtitle",
            defaultValue: "Namaz, zikir ve hikmeti tek premium sahnede buluşturur."
        )
    }

    static var majlisLockedSubtitle: String {
        localizedText(
            "widget_majlis_glow_locked_subtitle",
            defaultValue: "Büyük premium sahnede şehir, vakit ve hikmeti bir araya getirir."
        )
    }

    static var verseLockedSubtitle: String {
        localizedText(
            "widget_daily_verse_locked_subtitle",
            defaultValue: "Her gün yenilenen ayeti premium editoryal kartta sunar."
        )
    }

    static var hadithLockedSubtitle: String {
        localizedText(
            "widget_daily_hadith_locked_subtitle",
            defaultValue: "Her gün seçilen hadisi şık bir premium alıntı kartına dönüştürür."
        )
    }
}

private struct PremiumLockView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PremiumStoryBadge(title: L10n.string(.premium).uppercased(with: Locale.autoupdatingCurrent))

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased(with: Locale.autoupdatingCurrent))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }

            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.caption.weight(.semibold))
                Text(L10n.string(.premiumAGec2))
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(Color(hex: "#E7C873"))
        }
    }
}

private struct NoorSpotlightWidgetView: View {
    let entry: ZikrimWidgetEntry

    var body: some View {
        PremiumWidgetContainer(entry: entry, premiumDestination: "zikrim://dashboard") {
            VStack(alignment: .leading, spacing: 12) {
                if entry.isPremiumUnlocked {
                    PremiumStoryBadge()

                    Spacer(minLength: 0)

                    Text(entry.dailyWisdom)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .lineSpacing(2)
                        .lineLimit(4)
                        .minimumScaleFactor(0.75)

                    HStack {
                        Label(L10n.format(.widgetStreakDaysShort, Int64(max(entry.currentStreak, 1))), systemImage: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(L10n.format(.countFractionFormat, Int64(entry.dailyCount), Int64(max(entry.dailyGoal, 1))))
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .monospacedDigit()
                    }
                } else {
                    PremiumLockView(
                        title: WidgetTitle.noorSpotlight,
                        subtitle: PremiumWidgetCopy.noorLockedSubtitle
                    )
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(for: .widget) {
                LuxePremiumBackground(accent: Color(hex: "#E7C873"), isLocked: !entry.isPremiumUnlocked)
            }
        }
    }
}

private struct AuraFlowWidgetView: View {
    let entry: ZikrimWidgetEntry
    private var prayer: WidgetPrayerState { resolvedPrayerState(for: entry) }

    var body: some View {
        PremiumWidgetContainer(entry: entry, premiumDestination: "zikrim://dashboard") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    PremiumStoryBadge(title: entry.isPremiumUnlocked ? nil : L10n.string(.premium).uppercased(with: Locale.autoupdatingCurrent))
                    Spacer()
                    if entry.isPremiumUnlocked {
                        Text(entry.city.isEmpty ? L10n.string(.currentLocation) : entry.city)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                if entry.isPremiumUnlocked {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(prayer.displayName.uppercased(with: Locale.autoupdatingCurrent))
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .lineLimit(1)

                            if let time = prayer.time {
                                Text(time, style: .time)
                                    .font(.system(.title2, design: .rounded).weight(.semibold))
                                    .monospacedDigit()
                            } else {
                                Text(prayer.timeLabel)
                                    .font(.system(.title2, design: .rounded).weight(.semibold))
                                    .monospacedDigit()
                            }

                            if let time = prayer.time {
                                Text(time, style: .timer)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }

                        Spacer(minLength: 0)

                        ZStack {
                            Circle()
                                .stroke(.white.opacity(0.10), style: StrokeStyle(lineWidth: 8, lineCap: .round))

                            Circle()
                                .trim(from: 0, to: progressFraction)
                                .stroke(
                                    AngularGradient(
                                        colors: [Color(hex: "#E7C873"), prayer.prayerColor, Color(hex: "#F8ECC7")],
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .widgetAccentable()

                            VStack(spacing: 2) {
                                Text(.widgetDhikrTitleShort)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(L10n.format(.countFractionFormat, Int64(entry.dailyCount), Int64(max(entry.dailyGoal, 1))))
                                    .font(.system(.caption2, design: .rounded).weight(.bold))
                                    .monospacedDigit()
                            }
                        }
                        .frame(width: 74, height: 74)
                    }

                    Text(entry.dailyWisdom)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                } else {
                    PremiumLockView(
                        title: WidgetTitle.auraFlow,
                        subtitle: PremiumWidgetCopy.auraLockedSubtitle
                    )
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(for: .widget) {
                LuxePremiumBackground(accent: prayer.prayerColor, isLocked: !entry.isPremiumUnlocked)
            }
        }
    }

    private var progressFraction: Double {
        guard entry.dailyGoal > 0 else { return 0 }
        return min(max(Double(entry.dailyCount) / Double(entry.dailyGoal), 0), 1)
    }
}

private struct MajlisGlowWidgetView: View {
    let entry: ZikrimWidgetEntry
    private var prayer: WidgetPrayerState { resolvedPrayerState(for: entry) }

    var body: some View {
        PremiumWidgetContainer(entry: entry, premiumDestination: "zikrim://dashboard") {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    PremiumStoryBadge(title: entry.isPremiumUnlocked ? nil : L10n.string(.premium).uppercased(with: Locale.autoupdatingCurrent))
                    Spacer()
                    Text(entry.city.isEmpty ? L10n.string(.currentLocation) : entry.city)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                if entry.isPremiumUnlocked {
                    HStack(spacing: 14) {
                        PrayerDashboardCard(prayer: prayer)

                        VStack(alignment: .leading, spacing: 12) {
                            DhikrCircleCard(
                                count: entry.dailyCount,
                                goal: max(entry.dailyGoal, 1),
                                streak: entry.currentStreak
                            )
                            .frame(maxWidth: .infinity)

                            Text(entry.dailyWisdom)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(spacing: 8) {
                        ForEach(prayerOrder, id: \.self) { key in
                            PrayerTimelineNode(
                                title: prayerDisplayName(for: key),
                                timeText: entry.prayerTimeLabels[key] ?? "—",
                                isActive: key == prayer.name,
                                accent: prayerAccentColor(for: key)
                            )
                        }
                    }
                } else {
                    PremiumLockView(
                        title: WidgetTitle.majlisGlow,
                        subtitle: PremiumWidgetCopy.majlisLockedSubtitle
                    )
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(for: .widget) {
                LuxePremiumBackground(accent: prayer.prayerColor, isLocked: !entry.isPremiumUnlocked)
            }
        }
    }
}

private struct DailyVerseWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: ZikrimWidgetEntry

    private var isLarge: Bool { family == .systemLarge }

    var body: some View {
        PremiumWidgetContainer(entry: entry, premiumDestination: "zikrim://quran") {
            VStack(alignment: .leading, spacing: isLarge ? 16 : 12) {
                HStack(alignment: .top, spacing: 10) {
                    PremiumStoryBadge(
                        title: entry.isPremiumUnlocked
                            ? nil
                            : L10n.string(.premium).uppercased(with: Locale.autoupdatingCurrent)
                    )

                    Spacer(minLength: 0)

                    if entry.isPremiumUnlocked {
                        Image(systemName: "book.pages.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(hex: "#E7C873"))
                    }
                }

                if entry.isPremiumUnlocked {
                    VStack(alignment: .leading, spacing: isLarge ? 14 : 10) {
                        Text(localizedText("daily_quran_verse_title", defaultValue: "Günün Ayeti"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(entry.dailyVerseText)
                            .font(isLarge ? .system(.title3, design: .serif).weight(.semibold) : .system(.body, design: .serif).weight(.semibold))
                            .lineSpacing(isLarge ? 5 : 3)
                            .lineLimit(isLarge ? 8 : 5)
                            .minimumScaleFactor(0.72)
                            .allowsTightening(true)

                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.dailyVerseMetadata)
                                .font(.system(isLarge ? .body : .caption, design: .rounded).weight(.bold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)

                            if let source = entry.dailyVerseSource {
                                Text(source)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                        }

                        HStack(spacing: 8) {
                            Capsule()
                                .fill(Color(hex: "#E7C873"))
                                .frame(width: 26, height: 4)
                                .widgetAccentable()

                            Text(localizedText("daily_quran_verse_renews_daily", defaultValue: "Her gün yenilenir"))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                } else {
                    PremiumLockView(
                        title: localizedText("daily_quran_verse_title", defaultValue: "Günün Ayeti"),
                        subtitle: PremiumWidgetCopy.verseLockedSubtitle
                    )
                }
            }
            .padding(isLarge ? 18 : 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(for: .widget) {
                LuxePremiumBackground(accent: Color(hex: "#4E9A86"), isLocked: !entry.isPremiumUnlocked)
            }
        }
    }
}

private struct DailyHadithWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: ZikrimWidgetEntry

    private var isLarge: Bool { family == .systemLarge }

    var body: some View {
        PremiumWidgetContainer(entry: entry, premiumDestination: "zikrim://guide") {
            VStack(alignment: .leading, spacing: isLarge ? 16 : 12) {
                HStack(alignment: .top, spacing: 10) {
                    PremiumStoryBadge(
                        title: entry.isPremiumUnlocked
                            ? nil
                            : L10n.string(.premium).uppercased(with: Locale.autoupdatingCurrent)
                    )

                    Spacer(minLength: 0)

                    if entry.isPremiumUnlocked {
                        Text(entry.dailyHadithLanguage.uppercased(with: Locale.autoupdatingCurrent))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(.white.opacity(0.08))
                            .clipShape(.capsule)
                    }
                }

                if entry.isPremiumUnlocked {
                    VStack(alignment: .leading, spacing: isLarge ? 14 : 10) {
                        Text(localizedText("daily_hadith_card_title", defaultValue: "Günün Hadisi"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text("\"\(entry.dailyHadithText)\"")
                            .font(isLarge ? .system(.title3, design: .serif).weight(.semibold) : .system(.body, design: .serif).weight(.semibold))
                            .lineSpacing(isLarge ? 5 : 3)
                            .lineLimit(isLarge ? 8 : 5)
                            .minimumScaleFactor(0.72)
                            .allowsTightening(true)

                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.dailyHadithTitle)
                                .font(.system(isLarge ? .body : .caption, design: .rounded).weight(.bold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)

                            Text(entry.dailyHadithAttribution ?? localizedText("daily_hadith_card_renews_daily", defaultValue: "Her gün yenilenir"))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                } else {
                    PremiumLockView(
                        title: localizedText("daily_hadith_card_title", defaultValue: "Günün Hadisi"),
                        subtitle: PremiumWidgetCopy.hadithLockedSubtitle
                    )
                }
            }
            .padding(isLarge ? 18 : 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(for: .widget) {
                LuxePremiumBackground(accent: Color(hex: "#B98539"), isLocked: !entry.isPremiumUnlocked)
            }
        }
    }
}

private struct PremiumWidgetBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    let accent: Color

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [accent.opacity(colorScheme == .dark ? 0.30 : 0.22), .clear],
                center: .topTrailing,
                startRadius: 8,
                endRadius: 180
            )

            SacredGeometryOverlay(accent: accent)
            WidgetGrainOverlay()
        }
    }

    private var backgroundGradient: [Color] {
        if colorScheme == .dark {
            return [Color(hex: "#0F3D3E"), Color(hex: "#1F6F78"), Color(hex: "#0C2E2F")]
        }

        return [Color(hex: "#E7F2EE"), Color(hex: "#CFE5E1"), Color(hex: "#B9D8D4")]
    }
}

private struct LuxePremiumBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    let accent: Color
    let isLocked: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [accent.opacity(colorScheme == .dark ? 0.32 : 0.26), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 160
            )

            if isLocked {
                RadialGradient(
                    colors: [Color.white.opacity(0.08), .clear],
                    center: .bottomLeading,
                    startRadius: 6,
                    endRadius: 120
                )
            }

            SacredGeometryOverlay(accent: accent)
            WidgetGrainOverlay()
        }
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return isLocked
                ? [Color(hex: "#17131F"), Color(hex: "#2A2233"), Color(hex: "#130F18")]
                : [Color(hex: "#1C1820"), Color(hex: "#3D3321"), Color(hex: "#17131E")]
        }

        return isLocked
            ? [Color(hex: "#F1EDE7"), Color(hex: "#E8E0D3"), Color(hex: "#DDD2C2")]
            : [Color(hex: "#FAF4E8"), Color(hex: "#EADCB8"), Color(hex: "#E2D2AA")]
    }
}

private struct SacredGeometryOverlay: View {
    let accent: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .strokeBorder(.white.opacity(0.06), lineWidth: 1)
                    .frame(width: geometry.size.width * 0.72, height: geometry.size.width * 0.72)
                    .offset(x: geometry.size.width * 0.18, y: -geometry.size.height * 0.22)

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(accent.opacity(0.10), lineWidth: 1)
                    .frame(width: geometry.size.width * 0.40, height: geometry.size.width * 0.40)
                    .rotationEffect(.degrees(45))
                    .offset(x: geometry.size.width * 0.26, y: -geometry.size.height * 0.28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .allowsHitTesting(false)
    }
}

private struct WidgetGrainOverlay: View {
    var body: some View {
        Canvas { context, size in
            for index in 0..<120 {
                let x = pseudo(index * 17, scale: size.width)
                let y = pseudo(index * 31, scale: size.height)
                let alpha = 0.018 + pseudo(index * 13, scale: 0.04)
                let rect = CGRect(x: x, y: y, width: 1.5, height: 1.5)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
            }
        }
        .blendMode(.overlay)
        .opacity(0.6)
        .allowsHitTesting(false)
    }

    private func pseudo(_ seed: Int, scale: CGFloat) -> CGFloat {
        let value = sin(Double(seed) * 12.9898 + 78.233) * 43758.5453
        return CGFloat(value - floor(value)) * scale
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

struct PrayerFocusWidget: Widget {
    let kind = "ZikrimPrayerFocusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZikrimProvider()) { entry in
            PrayerFocusWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetTitle.prayerFocus)
        .description(L10n.string(.widgetDescription))
        .supportedFamilies([.systemSmall, .accessoryInline, .accessoryCircular, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

struct SignatureWidget: Widget {
    let kind = "ZikrimSignatureWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZikrimProvider()) { entry in
            SignatureWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetTitle.signature)
        .description("Small, medium ve large için tek widget.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct DhikrProgressWidget: Widget {
    let kind = "ZikrimDhikrProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZikrimProvider()) { entry in
            DhikrProgressWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetTitle.dhikrProgress)
        .description(L10n.string(.zikirIstatistikleriVeIlerlemeTakibi))
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct PrayerTimelineWidget: Widget {
    let kind = "ZikrimPrayerTimelineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZikrimProvider()) { entry in
            PrayerTimelineWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetTitle.prayerTimeline)
        .description(L10n.string(.widgetDescription))
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

struct PrayerDhikrWidget: Widget {
    let kind = "ZikrimPrayerDhikrWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZikrimProvider()) { entry in
            PrayerDhikrWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetTitle.prayerDhikr)
        .description(L10n.string(.widgetDescription))
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

struct SpiritualDashboardWidget: Widget {
    let kind = "ZikrimSpiritualDashboardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZikrimProvider()) { entry in
            SpiritualDashboardWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetTitle.spiritualDashboard)
        .description(L10n.string(.widgetDescription))
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}

struct NoorSpotlightWidget: Widget {
    let kind = "ZikrimNoorSpotlightWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZikrimProvider()) { entry in
            NoorSpotlightWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetTitle.noorSpotlight)
        .description("Premium hikmet kartı ve zikir ritmi.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct AuraFlowWidget: Widget {
    let kind = "ZikrimAuraFlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZikrimProvider()) { entry in
            AuraFlowWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetTitle.auraFlow)
        .description("Premium namaz ve zikir vitrini.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

struct MajlisGlowWidget: Widget {
    let kind = "ZikrimMajlisGlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZikrimProvider()) { entry in
            MajlisGlowWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetTitle.majlisGlow)
        .description("Büyük premium manevi vitrin.")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}

struct DailyVerseWidget: Widget {
    let kind = "ZikrimDailyVerseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZikrimProvider()) { entry in
            DailyVerseWidgetView(entry: entry)
        }
        .configurationDisplayName(localizedText("daily_quran_verse_title", defaultValue: "Günün Ayeti"))
        .description(localizedText("widget_daily_verse_description", defaultValue: "Premium günlük ayet kartı."))
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct DailyHadithWidget: Widget {
    let kind = "ZikrimDailyHadithWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZikrimProvider()) { entry in
            DailyHadithWidgetView(entry: entry)
        }
        .configurationDisplayName(localizedText("daily_hadith_card_title", defaultValue: "Günün Hadisi"))
        .description(localizedText("widget_daily_hadith_description", defaultValue: "Premium günlük hadis kartı."))
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

#Preview("Prayer Focus", as: .systemSmall) {
    PrayerFocusWidget()
} timeline: {
    ZikrimWidgetEntry.placeholder
}

#Preview("Prayer Focus Inline", as: .accessoryInline) {
    PrayerFocusWidget()
} timeline: {
    ZikrimWidgetEntry.placeholder
}

#Preview("Prayer Focus Circular", as: .accessoryCircular) {
    PrayerFocusWidget()
} timeline: {
    ZikrimWidgetEntry.placeholder
}

#Preview("Prayer Focus Rectangular", as: .accessoryRectangular) {
    PrayerFocusWidget()
} timeline: {
    ZikrimWidgetEntry.placeholder
}

#Preview("Signature Medium", as: .systemMedium) {
    SignatureWidget()
} timeline: {
    ZikrimWidgetEntry.placeholder
}

#Preview("Dhikr Progress", as: .systemSmall) {
    DhikrProgressWidget()
} timeline: {
    ZikrimWidgetEntry.placeholder
}

#Preview("Prayer Timeline", as: .systemMedium) {
    PrayerTimelineWidget()
} timeline: {
    ZikrimWidgetEntry.placeholder
}

#Preview("Prayer + Dhikr", as: .systemMedium) {
    PrayerDhikrWidget()
} timeline: {
    ZikrimWidgetEntry.placeholder
}

#Preview("Spiritual Dashboard", as: .systemLarge) {
    SpiritualDashboardWidget()
} timeline: {
    ZikrimWidgetEntry.placeholder
}

#Preview("Noor Spotlight", as: .systemSmall) {
    NoorSpotlightWidget()
} timeline: {
    ZikrimWidgetEntry.placeholder
}

#Preview("Aura Flow", as: .systemMedium) {
    AuraFlowWidget()
} timeline: {
    ZikrimWidgetEntry.placeholder
}

#Preview("Majlis Glow", as: .systemLarge) {
    MajlisGlowWidget()
} timeline: {
    ZikrimWidgetEntry.placeholder
}

#Preview("Daily Verse", as: .systemMedium) {
    DailyVerseWidget()
} timeline: {
    ZikrimWidgetEntry.placeholder
}

#Preview("Daily Hadith", as: .systemLarge) {
    DailyHadithWidget()
} timeline: {
    ZikrimWidgetEntry.placeholder
}
