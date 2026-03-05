import SwiftUI

struct IstatistikView: View {
    let storage: StorageService
    @State private var animateChart: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    todayHeroCard
                    lifetimeStatsRow
                    WeeklyChartView(storage: storage, animate: $animateChart)
                    TopZikirsView(storage: storage)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("İstatistik")
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
                    animateChart = true
                }
            }
        }
    }

    private var todayHeroCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Bugün", systemImage: "sun.max.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(storage.todayStats().totalCount)")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("tekrar yapıldı")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 5) {
                            Image(systemName: "flame.fill")
                                .font(.title3)
                                .foregroundStyle(.orange)
                                .shadow(color: .orange.opacity(0.5), radius: 6)
                            Text("\(storage.profile.currentStreak)")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Text("günlük seri")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }
            }

            let progress = min(Double(storage.todayStats().totalCount) / Double(max(storage.profile.dailyGoal, 1)), 1.0)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Günlük Hedef")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("\(storage.profile.dailyGoal) tekrar · \(Int(progress * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.18))
                            .frame(height: 7)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.teal, Color.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: animateChart ? geo.size.width * progress : 0, height: 7)
                            .animation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.2), value: animateChart)
                    }
                }
                .frame(height: 7)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.14, blue: 0.32), Color(red: 0.04, green: 0.36, blue: 0.40)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: 22))
    }

    private var lifetimeStatsRow: some View {
        HStack(spacing: 12) {
            GlowStatCard(
                title: "Toplam Zikir",
                value: formattedCount(storage.profile.totalLifetimeCount),
                icon: "chart.line.uptrend.xyaxis",
                color: Color(red: 0.55, green: 0.2, blue: 0.9)
            )
            GlowStatCard(
                title: "En Uzun Seri",
                value: "\(storage.profile.longestStreak) gün",
                icon: "trophy.fill",
                color: Color(red: 0.95, green: 0.7, blue: 0.1)
            )
        }
    }

    private func formattedCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        }
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}

struct GlowStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .shadow(color: color.opacity(0.3), radius: 8)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            Spacer()
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(height: 110)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(color.opacity(0.12), lineWidth: 1)
        )
    }
}

struct WeeklyChartView: View {
    let storage: StorageService
    @Binding var animate: Bool

    private var weeklyData: [DailyStats] { storage.weeklyStats() }
    private var maxCount: Int { max(weeklyData.map(\.totalCount).max() ?? 1, 1) }

    private let barColors: [Color] = [
        Color(red: 0.04, green: 0.36, blue: 0.40),
        Color.teal,
        Color.cyan,
        Color(red: 0.1, green: 0.5, blue: 0.8),
        Color(red: 0.3, green: 0.3, blue: 0.9),
        Color.indigo,
        Color(red: 0.5, green: 0.2, blue: 0.85)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Haftalık Özet")
                    .font(.headline)
                Spacer()
                Text("\(weeklyData.reduce(0) { $0 + $1.totalCount }) toplam")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, day in
                    GradientBarView(
                        day: day,
                        maxCount: maxCount,
                        color: barColors[index % barColors.count],
                        animate: animate
                    )
                }
            }
            .frame(height: 140)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }
}

struct GradientBarView: View {
    let day: DailyStats
    let maxCount: Int
    let color: Color
    let animate: Bool

    private var barFraction: CGFloat {
        max(CGFloat(day.totalCount) / CGFloat(maxCount), day.totalCount > 0 ? 0.06 : 0.04)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }

    var body: some View {
        VStack(spacing: 5) {
            if day.totalCount > 0 {
                Text("\(day.totalCount)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(color)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            } else {
                Text("")
                    .font(.system(size: 9))
            }

            GeometryReader { geo in
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            day.totalCount > 0
                                ? AnyShapeStyle(LinearGradient(colors: [color.opacity(0.5), color], startPoint: .bottom, endPoint: .top))
                                : AnyShapeStyle(Color(.tertiarySystemFill))
                        )
                        .frame(height: animate ? geo.size.height * barFraction : 4)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.05), value: animate)
                        .overlay(alignment: .top) {
                            if isToday && day.totalCount > 0 {
                                Circle()
                                    .fill(color)
                                    .frame(width: 5, height: 5)
                                    .offset(y: -3)
                                    .shadow(color: color.opacity(0.6), radius: 4)
                            }
                        }
                }
            }

            Text(dayLabel)
                .font(.caption2.bold())
                .foregroundStyle(isToday ? color : .secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: day.date)
    }
}

struct TopZikirsView: View {
    let storage: StorageService

    private var topZikirs: [(name: String, count: Int)] {
        var combined: [String: Int] = [:]
        for stats in storage.allStats {
            for (name, count) in stats.zikirDetails {
                combined[name, default: 0] += count
            }
        }
        return combined.sorted { $0.value > $1.value }.prefix(5).map { (name: $0.key, count: $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("En Çok Yapılan Zikirler")
                    .font(.headline)
                Spacer()
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }

            if topZikirs.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("Henüz istatistik yok")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(topZikirs.enumerated()), id: \.offset) { index, item in
                        MedalZikirRow(index: index, name: item.name, count: item.count, maxCount: topZikirs.first?.count ?? 1)
                    }
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }
}

struct MedalZikirRow: View {
    let index: Int
    let name: String
    let count: Int
    let maxCount: Int

    private var medalColor: Color {
        switch index {
        case 0: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 1: return Color(red: 0.75, green: 0.75, blue: 0.78)
        case 2: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return .secondary
        }
    }

    private var medalIcon: String {
        switch index {
        case 0: return "medal.fill"
        case 1: return "medal.fill"
        case 2: return "medal.fill"
        default: return "circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                if index < 3 {
                    Circle()
                        .fill(medalColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: medalIcon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(medalColor)
                } else {
                    Circle()
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 32, height: 32)
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                            .frame(height: 5)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: index < 3 ? [medalColor.opacity(0.7), medalColor] : [Color.accentColor.opacity(0.6), Color.accentColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(count) / CGFloat(max(maxCount, 1)), height: 5)
                    }
                }
                .frame(height: 5)
            }

            Text("\(count)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(index < 3 ? medalColor : .secondary)
                .frame(minWidth: 40, alignment: .trailing)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
    }
}
