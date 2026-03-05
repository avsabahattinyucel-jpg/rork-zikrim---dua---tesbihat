import WidgetKit
import SwiftUI

nonisolated struct ZikrimWidgetEntry: TimelineEntry {
    let date: Date
    let nextPrayerName: String
    let nextPrayerTime: String
    let dailyProgress: Int
    let dailyWisdom: String
}

nonisolated struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ZikrimWidgetEntry {
        ZikrimWidgetEntry(date: .now, nextPrayerName: "Öğle", nextPrayerTime: "13:05", dailyProgress: 45, dailyWisdom: "Bugün kalbini ferahlatacak bir dua ile güne başla.")
    }

    func getSnapshot(in context: Context, completion: @escaping (ZikrimWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ZikrimWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> ZikrimWidgetEntry {
        let defaults = UserDefaults.standard
        let prayer = defaults.string(forKey: "widget_next_prayer_name") ?? "Öğle"
        let prayerTime = defaults.string(forKey: "widget_next_prayer_time") ?? "--:--"
        let progress = defaults.integer(forKey: "widget_daily_progress")
        let wisdom = defaults.string(forKey: "widget_daily_wisdom") ?? "Bugün birine iyilik yap ve kalbini şükürle tazele."
        return ZikrimWidgetEntry(date: Date(), nextPrayerName: prayer, nextPrayerTime: prayerTime, dailyProgress: progress, dailyWisdom: wisdom)
    }
}

struct ZikrimWidgetView: View {
    var entry: ZikrimWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sonraki Namaz")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Text(entry.nextPrayerName)
                    .font(.headline)
                Spacer()
                Text(entry.nextPrayerTime)
                    .font(.headline)
            }
            Divider()
            Text("Günlük Zikir: %\(entry.dailyProgress)")
                .font(.subheadline.bold())
            ProgressView(value: Double(entry.dailyProgress), total: 100)
                .tint(.blue)
            Divider()
            Text("Rabia'nın Tavsiyesi")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(entry.dailyWisdom)
                .font(.caption)
                .lineLimit(2)
        }
        .widgetURL(URL(string: "zikrim://home"))
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct ZikrimWidget: Widget {
    let kind: String = "ZikrimWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ZikrimWidgetView(entry: entry)
        }
        .configurationDisplayName("Zikrim")
        .description("Namaz vakitleri ve Rabia destekli günün tavsiyesi")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
