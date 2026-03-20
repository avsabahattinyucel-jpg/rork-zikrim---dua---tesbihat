import SwiftUI

struct PrayerDayRhythmStripSection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let items: [PrayerDisplayItem]
    let selectedPrayer: PrayerName?
    let onSelectPrayer: (PrayerName) -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        PrayerSurfaceCard(theme: theme, tokens: theme.prayerTimesTokens, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                PrayerSectionHeader(
                    title: String(localized: "prayer_day_rhythm_strip_title", defaultValue: "Günün akışı"),
                    subtitle: nil
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(items) { item in
                            PrayerRhythmStripItem(
                                item: item,
                                isSelected: selectedPrayer == item.id,
                                onTap: { onSelectPrayer(item.id) }
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

struct PrayerTodayPrayerListSection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let viewModel: PrayerViewModel
    let selectedPrayer: PrayerName?
    let completionStatuses: [PrayerName: PrayerCompletionStatus]
    let onSelectPrayer: (PrayerName) -> Void
    let onChangeCompletion: (PrayerName, PrayerCompletionStatus) -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        PrayerSurfaceCard(theme: theme, tokens: theme.prayerTimesTokens) {
            VStack(alignment: .leading, spacing: 16) {
                PrayerSectionHeader(
                    title: viewModel.listSectionTitle,
                    subtitle: nil
                )

                VStack(spacing: 12) {
                    ForEach(viewModel.items) { item in
                        PrayerDailyPrayerRow(
                            item: item,
                            isSelected: selectedPrayer == item.id,
                            completionStatus: item.id.isObligatory ? completionStatuses[item.id] ?? .unknown : nil,
                            onTap: { onSelectPrayer(item.id) },
                            onChangeCompletion: { status in
                                onChangeCompletion(item.id, status)
                            }
                        )
                    }
                }
            }
        }
    }
}

struct PrayerDailyProgressSection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let progress: PrayerDailyProgress

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        PrayerSurfaceCard(theme: theme, tokens: theme.prayerTimesTokens, padding: 18) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(theme.border.opacity(theme.isDarkMode ? 0.26 : 0.36), lineWidth: 8)
                        .frame(width: 58, height: 58)

                    Circle()
                        .trim(from: 0, to: progress.progressFraction)
                        .stroke(theme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 58, height: 58)

                    Text("\(progress.completedCount)")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                        .contentTransition(.numericText())
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(String(localized: "prayer_daily_progress_title", defaultValue: "Bugün"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.textSecondary)

                    Text("\(progress.completedCount)/\(progress.totalCount) namaz tamamlandı")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.textPrimary)

                    Text(String(localized: "prayer_daily_progress_subtitle", defaultValue: "Günlük ibadet ve zikir kaydın burada toplanır"))
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

struct PrayerWeeklyHistorySection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let days: [PrayerHistoryDay]
    let onOpenQada: (PrayerHistoryDay) -> Void

    @State private var selectedDayID: String?

    private var theme: ActiveTheme { themeManager.current }
    private var selectedDay: PrayerHistoryDay? {
        if let selectedDayID,
           let matched = days.first(where: { $0.id == selectedDayID }) {
            return matched
        }

        return days.last(where: \.hasMissedPrayers) ?? days.last
    }

    var body: some View {
        PrayerSurfaceCard(theme: theme, tokens: theme.prayerTimesTokens, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                PrayerSectionHeader(
                    title: String(localized: "prayer_weekly_history_title", defaultValue: "Son 7 gün"),
                    subtitle: nil
                )

                HStack(spacing: 10) {
                    ForEach(days) { day in
                        PrayerWeeklyHistoryDayPill(
                            day: day,
                            isSelected: selectedDay?.id == day.id,
                            onTap: { selectedDayID = day.id }
                        )
                    }
                }

                if let selectedDay {
                    PrayerWeeklyHistoryDetailCard(
                        day: selectedDay,
                        onOpenQada: onOpenQada
                    )
                }
            }
        }
        .onAppear {
            if selectedDayID == nil {
                selectedDayID = (days.last(where: \.hasMissedPrayers) ?? days.last)?.id
            }
        }
    }
}

struct PrayerQadaSummarySection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let trackers: [PrayerName: QadaTracker]
    let suggestedPrayerIDs: [PrayerName]
    let onOpenQada: () -> Void

    private var theme: ActiveTheme { themeManager.current }
    private var totalOutstanding: Int {
        PrayerName.obligatoryCases.reduce(0) { partialResult, prayer in
            partialResult + (trackers[prayer]?.outstandingCount ?? 0)
        }
    }
    private var totalCompleted: Int {
        PrayerName.obligatoryCases.reduce(0) { partialResult, prayer in
            partialResult + (trackers[prayer]?.completedQadaCount ?? 0)
        }
    }

    var body: some View {
        PrayerSurfaceCard(theme: theme, tokens: theme.prayerTimesTokens, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                PrayerSectionHeader(
                    title: String(localized: "prayer_qada_section_title", defaultValue: "Kaza takibi"),
                    subtitle: String(localized: "prayer_qada_summary_section_subtitle", defaultValue: "Detaylı takip ve hesaplama artık tek merkezde")
                )

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Toplam \(totalOutstanding) kaza")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(theme.textPrimary)

                        Text(totalCompleted > 0 ? "\(totalCompleted) kaza işlendi" : String(localized: "prayer_qada_summary_subtitle", defaultValue: "Kaza namazlarını niyet ve istikrarla sürdür"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(theme.textSecondary)

                        if !suggestedPrayerIDs.isEmpty {
                            Text("Bugünkü eksik vakitler istersen kaza merkezinde eklenebilir.")
                                .font(.caption)
                                .foregroundStyle(theme.textSecondary)
                                .padding(.top, 4)
                        }
                    }

                    Spacer(minLength: 0)

                    Button(action: onOpenQada) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.caption.weight(.semibold))
                            Text("Kaza namazları")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(theme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(theme.cardBackground.opacity(theme.isDarkMode ? 0.80 : 0.96), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(theme.border.opacity(theme.isDarkMode ? 0.26 : 0.40), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct PrayerQadaTrackingSection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let trackers: [PrayerName: QadaTracker]
    let suggestedPrayerIDs: [PrayerName]
    let onAddSuggested: (PrayerName) -> Void
    let onIncrement: (PrayerName) -> Void
    let onDecrement: (PrayerName) -> Void
    let onComplete: (PrayerName) -> Void

    private var theme: ActiveTheme { themeManager.current }

    private var orderedTrackers: [QadaTracker] {
        PrayerName.obligatoryCases.compactMap { trackers[$0] }
    }

    private var totalOutstanding: Int {
        orderedTrackers.reduce(0) { $0 + $1.outstandingCount }
    }

    private var totalCompleted: Int {
        orderedTrackers.reduce(0) { $0 + $1.completedQadaCount }
    }

    var body: some View {
        PrayerSurfaceCard(theme: theme, tokens: theme.prayerTimesTokens) {
            VStack(alignment: .leading, spacing: 16) {
                PrayerSectionHeader(
                    title: String(localized: "prayer_qada_section_title", defaultValue: "Kaza takibi"),
                    subtitle: String(localized: "prayer_qada_section_subtitle", defaultValue: "Eksik kalan vakitleri tek yerde sade biçimde tut")
                )

                PrayerQadaSummaryCard(
                    totalOutstanding: totalOutstanding,
                    totalCompleted: totalCompleted
                )

                if !suggestedPrayerIDs.isEmpty {
                    PrayerQadaSuggestionCard(
                        suggestedPrayerIDs: suggestedPrayerIDs,
                        onAddSuggested: onAddSuggested
                    )
                }

                VStack(spacing: 12) {
                    ForEach(orderedTrackers) { tracker in
                        PrayerQadaCounterRow(
                            tracker: tracker,
                            onIncrement: { onIncrement(tracker.prayerType) },
                            onDecrement: { onDecrement(tracker.prayerType) },
                            onComplete: { onComplete(tracker.prayerType) }
                        )
                    }
                }
            }
        }
    }
}

private struct PrayerWeeklyHistoryDayPill: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let day: PrayerHistoryDay
    let isSelected: Bool
    let onTap: () -> Void

    private var theme: ActiveTheme { themeManager.current }

    private var weekdayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: RabiaAppLanguage.currentCode())
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: day.date)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(weekdayLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.textSecondary)

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(theme.selectionBackground.opacity(theme.isDarkMode ? 0.58 : 0.86))
                        .frame(height: 58)

                    VStack(spacing: 4) {
                        Text("\(day.completionCount)/\(day.totalCount)")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(theme.textPrimary)

                        Capsule()
                            .fill(theme.accent.opacity(day.progressFraction > 0 ? 0.95 : 0.18))
                            .frame(width: CGFloat(22 + (28 * day.progressFraction)), height: 4)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .opacity(day.isToday ? 1 : 0.9)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? theme.accent.opacity(0.88) : .clear, lineWidth: 1.2)
                    .padding(.top, 24)
            }
            .overlay(alignment: .topTrailing) {
                if day.isToday {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 7, height: 7)
                        .offset(x: -2, y: 4)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct PrayerWeeklyHistoryDetailCard: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let day: PrayerHistoryDay
    let onOpenQada: (PrayerHistoryDay) -> Void

    private var theme: ActiveTheme { themeManager.current }

    private var dayLabel: String {
        if day.isToday {
            return "Bugün"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: RabiaAppLanguage.currentCode())
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter.string(from: day.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dayLabel)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.textPrimary)

            if day.hasMissedPrayers {
                Text("Eksik işaretlenen vakitler")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.textSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(day.missedPrayerNames, id: \.self) { name in
                            Text(name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(theme.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(theme.cardBackground.opacity(theme.isDarkMode ? 0.82 : 0.96), in: Capsule())
                        }
                    }
                }

                Button {
                    onOpenQada(day)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption.weight(.semibold))
                        Text("Kaza merkezine taşı")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(theme.selectionBackground.opacity(theme.isDarkMode ? 0.58 : 0.84), in: Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Text("Eksik vakit görünmüyor.")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .padding(14)
        .background(theme.selectionBackground.opacity(theme.isDarkMode ? 0.50 : 0.84), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(theme.border.opacity(theme.isDarkMode ? 0.24 : 0.38), lineWidth: 1)
        )
    }
}

struct PrayerExpandedExtrasSection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let title: String
    let subtitle: String
    let modules: [PrayerExtraModule]
    let onTapModule: (PrayerExtraModule) -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        PrayerSurfaceCard(theme: theme, tokens: theme.prayerTimesTokens) {
            VStack(alignment: .leading, spacing: 16) {
                PrayerSectionHeader(title: title, subtitle: subtitle)

                VStack(spacing: 12) {
                    ForEach(modules) { module in
                        PrayerExtraEntryCard(module: module) {
                            onTapModule(module)
                        }
                    }
                }
            }
        }
    }
}

struct PrayerSecondaryToolsSection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let items: [PrayerToolItem]
    let onOpenPreferences: () -> Void
    let onOpenQibla: () -> Void
    let onOpenLocation: () -> Void

    private var theme: ActiveTheme { themeManager.current }
    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

    var body: some View {
        PrayerSurfaceCard(theme: theme, tokens: theme.prayerTimesTokens, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                PrayerSectionHeader(
                    title: String(localized: "prayer_tools_section_compact_title", defaultValue: "Araçlar"),
                    subtitle: String(localized: "prayer_tools_section_compact_subtitle", defaultValue: "Diyanet, kıble ve hatırlatıcılar")
                )

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(items) { item in
                        toolButton(for: item)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func toolButton(for item: PrayerToolItem) -> some View {
        switch item.kind {
        case .notifications:
            NavigationLink {
                NotificationSettingsView()
            } label: {
                PrayerCompactToolCard(item: item)
            }
            .buttonStyle(.plain)
        case .qibla:
            Button(action: onOpenQibla) {
                PrayerCompactToolCard(item: item)
            }
            .buttonStyle(.plain)
        case .location:
            Button(action: onOpenLocation) {
                PrayerCompactToolCard(item: item)
            }
            .buttonStyle(.plain)
        case .calculation:
            Button(action: onOpenPreferences) {
                PrayerCompactToolCard(item: item)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct PrayerSectionHeader: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let title: String
    let subtitle: String?

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.textPrimary)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct PrayerRhythmStripItem: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let item: PrayerDisplayItem
    let isSelected: Bool
    let onTap: () -> Void

    private var theme: ActiveTheme { themeManager.current }
    private var style: PrayerGradientProvider.Style {
        PrayerGradientProvider.style(for: item.id, theme: theme)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    PrayerIconView(assetName: item.iconType, size: 20)
                        .opacity(item.state == .past ? 0.84 : 1)

                    Spacer(minLength: 0)

                    Circle()
                        .fill(stateDotColor)
                        .frame(width: 8, height: 8)
                }

                Text(item.localizedName)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(labelColor)
                    .fixedSize(horizontal: true, vertical: false)

                Text(item.formattedTime)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(secondaryLabelColor)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(minWidth: 104, alignment: .leading)
            .background(background)
            .overlay(border)
            .shadow(color: item.state == .current ? style.glow.opacity(0.18) : .clear, radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.localizedName), \(item.formattedTime)")
    }

    private var iconColor: Color {
        item.state == .current ? .white : style.accent
    }

    private var labelColor: Color {
        item.state == .past ? theme.textSecondary : (item.state == .current ? .white : theme.textPrimary)
    }

    private var secondaryLabelColor: Color {
        item.state == .current ? Color.white.opacity(0.82) : theme.textSecondary
    }

    private var stateDotColor: Color {
        switch item.state {
        case .past:
            return theme.textSecondary.opacity(0.48)
        case .current:
            return .white
        case .upcoming:
            return style.accent.opacity(0.92)
        }
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                item.state == .current
                    ? AnyShapeStyle(style.heroGradient)
                    : AnyShapeStyle(theme.cardBackground.opacity(theme.isDarkMode ? 0.68 : 0.94))
            )
            .opacity(item.state == .past ? 0.74 : 1)
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(
                isSelected ? style.ring.opacity(0.90) : theme.border.opacity(theme.isDarkMode ? 0.26 : 0.40),
                lineWidth: isSelected ? 1.2 : 1
            )
    }
}

private struct PrayerDailyPrayerRow: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let item: PrayerDisplayItem
    let isSelected: Bool
    let completionStatus: PrayerCompletionStatus?
    let onTap: () -> Void
    let onChangeCompletion: (PrayerCompletionStatus) -> Void

    private var theme: ActiveTheme { themeManager.current }
    private var style: PrayerGradientProvider.Style {
        PrayerGradientProvider.style(for: item.id, theme: theme)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            iconView

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text(item.id.dailyListDisplayName)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(titleColor)

                    PrayerStateBadge(item: item)
                }

                if let completionStatus {
                    PrayerCompletionControl(
                        status: completionStatus,
                        style: style,
                        isCurrentPrayer: item.state == .current,
                        isEnabled: item.state != .upcoming,
                        onSelect: onChangeCompletion
                    )
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 10) {
                Text(item.formattedTime)
                    .font(.system(size: item.state == .current ? 30 : 26, weight: .bold, design: .rounded))
                    .foregroundStyle(titleColor)

                if item.reminderEnabled {
                    Image(systemName: "bell.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(item.state == .current ? Color.white.opacity(0.86) : style.accent.opacity(0.94))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, item.state == .current ? 16 : 13)
        .background(background)
        .overlay(border)
        .shadow(color: item.state == .current ? style.glow.opacity(0.18) : .clear, radius: 18, x: 0, y: 10)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.id.dailyListDisplayName), \(item.formattedTime), \(shortStateLabel)")
    }

    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(item.state == .current ? Color.white.opacity(0.16) : style.glow.opacity(theme.isDarkMode ? 0.20 : 0.14))
                .frame(width: 50, height: 50)

            PrayerIconView(assetName: item.iconType, size: 28)
        }
    }

    private var titleColor: Color {
        if item.state == .current {
            return .white
        }
        if item.state == .past {
            return theme.textPrimary.opacity(0.82)
        }
        return theme.textPrimary
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                item.state == .current
                    ? AnyShapeStyle(style.heroGradient)
                    : AnyShapeStyle(theme.cardBackground.opacity(theme.isDarkMode ? 0.70 : 0.94))
            )
            .opacity(item.state == .past ? 0.84 : 1)
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(
                isSelected ? style.ring.opacity(0.88) : theme.border.opacity(theme.isDarkMode ? 0.28 : 0.44),
                lineWidth: isSelected ? 1.2 : 1
            )
    }

    private var shortStateLabel: String {
        switch item.state {
        case .past:
            return String(localized: "prayer_row_state_past", defaultValue: "Geçti")
        case .current:
            return String(localized: "prayer_row_state_current_now", defaultValue: "Şimdi")
        case .upcoming:
            return String(localized: "prayer_row_state_upcoming", defaultValue: "Yakın")
        }
    }
}

private struct PrayerStateBadge: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let item: PrayerDisplayItem

    private var theme: ActiveTheme { themeManager.current }
    private var style: PrayerGradientProvider.Style {
        PrayerGradientProvider.style(for: item.id, theme: theme)
    }

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(background, in: Capsule())
    }

    private var label: String {
        switch item.state {
        case .past:
            return String(localized: "prayer_state_badge_past", defaultValue: "Geçti")
        case .current:
            return String(localized: "prayer_state_badge_current", defaultValue: "Şimdi")
        case .upcoming:
            return String(localized: "prayer_state_badge_upcoming", defaultValue: "Yakın")
        }
    }

    private var foreground: Color {
        item.state == .current ? .white : theme.textSecondary
    }

    private var background: Color {
        switch item.state {
        case .past:
            return theme.selectionBackground.opacity(theme.isDarkMode ? 0.62 : 0.88)
        case .current:
            return Color.white.opacity(0.16)
        case .upcoming:
            return style.glow.opacity(theme.isDarkMode ? 0.22 : 0.16)
        }
    }
}

private struct PrayerCompletionControl: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let status: PrayerCompletionStatus
    let style: PrayerGradientProvider.Style
    let isCurrentPrayer: Bool
    let isEnabled: Bool
    let onSelect: (PrayerCompletionStatus) -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        Button {
            guard isEnabled else { return }
            onSelect(status.next)
        } label: {
            HStack(spacing: 7) {
                Image(systemName: isEnabled ? status.systemImage : "clock")
                    .font(.caption.weight(.semibold))

                Text(isEnabled ? status.shortLabel : String(localized: "prayer_completion_waiting_short", defaultValue: "Vakti gelince"))
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(background, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(status.localizedTitle)
    }

    private var foreground: Color {
        guard isEnabled else { return theme.textSecondary.opacity(0.74) }
        if isCurrentPrayer {
            return .white
        }

        switch status {
        case .unknown:
            return theme.textSecondary
        case .prayed:
            return style.accentSecondary
        case .missed:
            return Color(red: 0.97, green: 0.78, blue: 0.55)
        }
    }

    private var background: Color {
        guard isEnabled else {
            return theme.selectionBackground.opacity(theme.isDarkMode ? 0.36 : 0.72)
        }
        if isCurrentPrayer {
            return Color.white.opacity(0.10)
        }

        switch status {
        case .unknown:
            return theme.selectionBackground.opacity(theme.isDarkMode ? 0.54 : 0.86)
        case .prayed:
            return style.glow.opacity(theme.isDarkMode ? 0.18 : 0.14)
        case .missed:
            return Color(red: 0.63, green: 0.39, blue: 0.18).opacity(theme.isDarkMode ? 0.28 : 0.16)
        }
    }

    private var borderColor: Color {
        guard isEnabled else {
            return theme.border.opacity(theme.isDarkMode ? 0.22 : 0.36)
        }
        if isCurrentPrayer {
            return Color.white.opacity(0.14)
        }

        switch status {
        case .unknown:
            return theme.border.opacity(theme.isDarkMode ? 0.30 : 0.44)
        case .prayed:
            return style.ring.opacity(0.48)
        case .missed:
            return Color(red: 0.93, green: 0.70, blue: 0.45).opacity(0.36)
        }
    }
}

private struct PrayerQadaSummaryCard: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let totalOutstanding: Int
    let totalCompleted: Int

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Toplam \(totalOutstanding) kaza")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.textPrimary)

                Text(totalCompleted > 0 ? "\(totalCompleted) tamamlandı" : String(localized: "prayer_qada_summary_subtitle", defaultValue: "Kaza namazlarını niyet ve istikrarla sürdür"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            theme.selectionBackground.opacity(theme.isDarkMode ? 0.62 : 0.90),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.border.opacity(theme.isDarkMode ? 0.26 : 0.40), lineWidth: 1)
        )
    }
}

private struct PrayerQadaSuggestionCard: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let suggestedPrayerIDs: [PrayerName]
    let onAddSuggested: (PrayerName) -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "prayer_qada_suggestion_text", defaultValue: "İstersen bunu kaza takibine ekleyebilirsin."))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(theme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggestedPrayerIDs, id: \.self) { prayer in
                        Button {
                            onAddSuggested(prayer)
                        } label: {
                            HStack(spacing: 8) {
                                PrayerIconView(assetName: prayer.systemImage, size: 18)
                                Text("\(prayer.qadaDisplayName) ekle")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(theme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                theme.cardBackground.opacity(theme.isDarkMode ? 0.78 : 0.96),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .stroke(theme.border.opacity(theme.isDarkMode ? 0.28 : 0.40), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(
            theme.selectionBackground.opacity(theme.isDarkMode ? 0.50 : 0.86),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.border.opacity(theme.isDarkMode ? 0.24 : 0.38), lineWidth: 1)
        )
    }
}

private struct PrayerQadaCounterRow: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let tracker: QadaTracker
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onComplete: () -> Void

    private var theme: ActiveTheme { themeManager.current }
    private var style: PrayerGradientProvider.Style {
        PrayerGradientProvider.style(for: tracker.prayerType, theme: theme)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(tracker.prayerType.qadaDisplayName)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            PrayerQadaStepper(
                value: tracker.outstandingCount,
                onIncrement: onIncrement,
                onDecrement: onDecrement
            )

            PrayerCompleteQadaButton(
                isEnabled: tracker.outstandingCount > 0,
                onTap: onComplete
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            theme.cardBackground.opacity(theme.isDarkMode ? 0.72 : 0.94),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.border.opacity(theme.isDarkMode ? 0.28 : 0.42), lineWidth: 1)
        )
    }
}

private struct PrayerQadaStepper: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let value: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        HStack(spacing: 0) {
            PrayerCounterActionButton(icon: "minus", action: onDecrement)

            Divider()
                .overlay(theme.border.opacity(theme.isDarkMode ? 0.26 : 0.40))

            Text("\(value)")
                .font(.system(.callout, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.textPrimary)
                .frame(minWidth: 44)
                .contentTransition(.numericText())

            Divider()
                .overlay(theme.border.opacity(theme.isDarkMode ? 0.26 : 0.40))

            PrayerCounterActionButton(icon: "plus", action: onIncrement)
        }
        .frame(height: 42)
        .background(
            theme.selectionBackground.opacity(theme.isDarkMode ? 0.58 : 0.86),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(theme.border.opacity(theme.isDarkMode ? 0.26 : 0.42), lineWidth: 1)
        )
    }
}

private struct PrayerCounterActionButton: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let icon: String
    let action: () -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.textPrimary)
                .frame(width: 38, height: 42)
        }
        .buttonStyle(.plain)
    }
}

private struct PrayerCompleteQadaButton: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let isEnabled: Bool
    let onTap: () -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                Text(String(localized: "prayer_qada_complete_button", defaultValue: "Tamamla"))
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isEnabled ? theme.textPrimary : theme.textSecondary)
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(
                (isEnabled ? theme.cardBackground.opacity(theme.isDarkMode ? 0.86 : 0.98) : theme.selectionBackground.opacity(theme.isDarkMode ? 0.36 : 0.70)),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(theme.border.opacity(theme.isDarkMode ? 0.26 : 0.42), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

private struct PrayerExtraEntryCard: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let module: PrayerExtraModule
    let action: () -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(theme.selectionBackground.opacity(theme.isDarkMode ? 0.70 : 0.86))
                        .frame(width: 46, height: 46)

                    Image(systemName: module.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(module.title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.textPrimary)

                    Text(module.subtitle)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.textSecondary.opacity(0.7))
            }
            .padding(16)
            .background(
                theme.cardBackground.opacity(theme.isDarkMode ? 0.72 : 0.94),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(theme.border.opacity(theme.isDarkMode ? 0.28 : 0.42), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PrayerCompactToolCard: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let item: PrayerToolItem

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.selectionBackground.opacity(theme.isDarkMode ? 0.68 : 0.86))
                    .frame(width: 40, height: 40)

                Image(systemName: item.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.accent)
            }

            Text(item.title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)

                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
        .background(
            theme.cardBackground.opacity(theme.isDarkMode ? 0.66 : 0.94),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(theme.border.opacity(theme.isDarkMode ? 0.26 : 0.40), lineWidth: 1)
        )
    }
}
