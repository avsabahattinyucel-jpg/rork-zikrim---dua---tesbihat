import Foundation
import WidgetKit

enum SharedDefaults {
    static let suiteName = "group.app.rork.pu2jopnhgtfk3o9m6amda.2de8110f.shared"

    static let nextPrayerNameKey = "widget_next_prayer_name"
    static let nextPrayerTimeKey = "widget_next_prayer_time"
    static let nextPrayerDateKey = "widget_next_prayer_date"
    static let nextPrayerCityKey = "widget_next_prayer_city"
    static let nextPrayerIconKey = "widget_next_prayer_icon"
    static let dailyProgressKey = "widget_daily_progress"
    static let dailyGoalKey = "widget_daily_goal"
    static let dailyCountKey = "widget_daily_count"
    static let currentStreakKey = "widget_current_streak"
    static let dailyWisdomKey = "widget_daily_wisdom"
    static let dailyVerseMetadataKey = "widget_daily_verse_metadata"
    static let dailyVerseTextKey = "widget_daily_verse_text"
    static let dailyVerseSourceKey = "widget_daily_verse_source"
    static let dailyHadithTitleKey = "widget_daily_hadith_title"
    static let dailyHadithTextKey = "widget_daily_hadith_text"
    static let dailyHadithAttributionKey = "widget_daily_hadith_attribution"
    static let dailyHadithLanguageKey = "widget_daily_hadith_language"
    static let allPrayerTimesKey = "widget_all_prayer_times"
    static let prayerScheduleTimestampsKey = "widget_prayer_schedule_timestamps"
    static let tomorrowFajrDateKey = "widget_tomorrow_fajr_date"
    static let premiumAccessKey = "widget_premium_access"

    static var shared: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func updateWidgetData(
        nextPrayerName: String,
        nextPrayerTime: String,
        nextPrayerDate: Date,
        nextPrayerIcon: String,
        city: String,
        allPrayerTimes: [String: String],
        prayerSchedule: [String: Date],
        tomorrowFajr: Date?
    ) {
        guard let defaults = shared else { return }
        defaults.set(nextPrayerName, forKey: nextPrayerNameKey)
        defaults.set(nextPrayerTime, forKey: nextPrayerTimeKey)
        defaults.set(nextPrayerDate.timeIntervalSince1970, forKey: nextPrayerDateKey)
        defaults.set(nextPrayerIcon, forKey: nextPrayerIconKey)
        defaults.set(city, forKey: nextPrayerCityKey)
        defaults.set(allPrayerTimes, forKey: allPrayerTimesKey)
        defaults.set(
            Dictionary(uniqueKeysWithValues: prayerSchedule.map { ($0.key, $0.value.timeIntervalSince1970) }),
            forKey: prayerScheduleTimestampsKey
        )
        if let tomorrowFajr {
            defaults.set(tomorrowFajr.timeIntervalSince1970, forKey: tomorrowFajrDateKey)
        } else {
            defaults.removeObject(forKey: tomorrowFajrDateKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func updateZikirProgress(dailyCount: Int, dailyGoal: Int, streak: Int) {
        guard let defaults = shared else { return }
        let progress = dailyGoal > 0 ? min(Int((Double(dailyCount) / Double(dailyGoal)) * 100.0), 100) : 0
        defaults.set(progress, forKey: dailyProgressKey)
        defaults.set(dailyCount, forKey: dailyCountKey)
        defaults.set(dailyGoal, forKey: dailyGoalKey)
        defaults.set(streak, forKey: currentStreakKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func updateDailyWisdom(_ wisdom: String) {
        guard let defaults = shared else { return }
        defaults.set(wisdom, forKey: dailyWisdomKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func updateDailyVerse(metadata: String, text: String, source: String?) {
        guard let defaults = shared else { return }
        defaults.set(metadata, forKey: dailyVerseMetadataKey)
        defaults.set(text, forKey: dailyVerseTextKey)

        if let source, !source.isEmpty {
            defaults.set(source, forKey: dailyVerseSourceKey)
        } else {
            defaults.removeObject(forKey: dailyVerseSourceKey)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    static func updateDailyHadith(title: String, text: String, attribution: String?, language: String) {
        guard let defaults = shared else { return }
        defaults.set(title, forKey: dailyHadithTitleKey)
        defaults.set(text, forKey: dailyHadithTextKey)
        defaults.set(language, forKey: dailyHadithLanguageKey)

        if let attribution, !attribution.isEmpty {
            defaults.set(attribution, forKey: dailyHadithAttributionKey)
        } else {
            defaults.removeObject(forKey: dailyHadithAttributionKey)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    static func updatePremiumAccess(_ hasPremiumAccess: Bool) {
        guard let defaults = shared else { return }

        let currentValue = defaults.bool(forKey: premiumAccessKey)
        guard currentValue != hasPremiumAccess else { return }

        defaults.set(hasPremiumAccess, forKey: premiumAccessKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func clearAll() {
        guard let defaults = shared else { return }

        [
            nextPrayerNameKey,
            nextPrayerTimeKey,
            nextPrayerDateKey,
            nextPrayerCityKey,
            nextPrayerIconKey,
            dailyProgressKey,
            dailyGoalKey,
            dailyCountKey,
            currentStreakKey,
            dailyWisdomKey,
            dailyVerseMetadataKey,
            dailyVerseTextKey,
            dailyVerseSourceKey,
            dailyHadithTitleKey,
            dailyHadithTextKey,
            dailyHadithAttributionKey,
            dailyHadithLanguageKey,
            allPrayerTimesKey,
            prayerScheduleTimestampsKey,
            tomorrowFajrDateKey,
            premiumAccessKey
        ].forEach { defaults.removeObject(forKey: $0) }

        WidgetCenter.shared.reloadAllTimelines()
    }
}
