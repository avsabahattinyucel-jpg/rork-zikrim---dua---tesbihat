import SwiftUI

struct DhikrCalendarView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    let storage: StorageService

    @State private var mode: DhikrCalendarMode = .gregorian
    @State private var hijriVisibleDate: Date
    @State private var expandedDhikrID: String?

    init(selectedDate: Binding<Date>, storage: StorageService) {
        _selectedDate = selectedDate
        self.storage = storage
        _hijriVisibleDate = State(initialValue: selectedDate.wrappedValue)
    }

    private var theme: ActiveTheme { themeManager.current }
    private var locale: Locale { Locale(identifier: RabiaAppLanguage.currentCode()) }

    private var gregorianCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return calendar
    }

    private var hijriCalendar: Calendar {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = locale
        return calendar
    }

    private var layoutDirection: LayoutDirection {
        let code = RabiaAppLanguage.currentCode().lowercased()
        return ["ar", "fa", "ur"].contains { code.hasPrefix($0) } ? .rightToLeft : .leftToRight
    }

    private var selectedDayStats: DailyStats {
        storage.stats(for: selectedDate)
    }

    private var selectedDayDhikrs: [DhikrCalendarEntry] {
        if !selectedDayStats.dhikrRecords.isEmpty {
            return selectedDayStats.dhikrRecords
                .sorted { lhs, rhs in
                    if lhs.count == rhs.count {
                        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                    }
                    return lhs.count > rhs.count
                }
                .map {
                    DhikrCalendarEntry(
                        id: $0.id,
                        title: $0.title,
                        count: $0.count,
                        arabicText: $0.arabicText,
                        transliteration: $0.transliteration
                    )
                }
        }

        return selectedDayStats.zikirDetails
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key.localizedCaseInsensitiveCompare(rhs.key) == .orderedAscending
                }
                return lhs.value > rhs.value
            }
            .map {
                DhikrCalendarEntry(
                    id: $0.key,
                    title: $0.key,
                    count: $0.value,
                    arabicText: "",
                    transliteration: ""
                )
            }
    }

    private var selectedDayTopDhikr: DhikrCalendarEntry? {
        selectedDayDhikrs.first
    }

    private var expandedDhikrEntry: DhikrCalendarEntry? {
        guard let expandedDhikrID else { return nil }
        return selectedDayDhikrs.first(where: { $0.id == expandedDhikrID && $0.hasDetail })
    }

    private var shouldShowTurkishTransliteration: Bool {
        AppLanguage(code: RabiaAppLanguage.currentCode()) == .tr
    }

    private var dailyGoalProgress: Double {
        Double(selectedDayStats.totalCount) / Double(max(storage.profile.dailyGoal, 1))
    }

    var body: some View {
        ZStack {
            ThemedSacredBackground(theme: theme)

            ScrollView {
                VStack(spacing: 18) {
                    dateSummaryCard
                    calendarModePicker

                    Group {
                        if mode == .gregorian {
                            gregorianCalendarCard
                        } else {
                            hijriCalendarCard
                        }
                    }

                    selectedDayDhikrCard

                    if let day = matchingReligiousDay(for: selectedDate) {
                        religiousDayDetailCard(day)
                    }

                    upcomingDaysCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle(DhikrScreenText.string(.calendarTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(L10n.string(.commonClose)) { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.string(.bugun)) {
                    selectedDate = Date()
                    hijriVisibleDate = Date()
                }
            }
        }
        .environment(\.layoutDirection, layoutDirection)
        .onChange(of: selectedDate) { _, newValue in
            hijriVisibleDate = newValue
            if let currentExpandedDhikrID = expandedDhikrID,
               !selectedDayDhikrs.contains(where: { $0.id == currentExpandedDhikrID }) {
                expandedDhikrID = nil
            }
        }
    }

    private var dateSummaryCard: some View {
        HStack(spacing: 14) {
            calendarSummaryColumn(
                title: L10n.string(.miladi2),
                systemImage: "calendar",
                value: gregorianLongText(for: selectedDate),
                accent: theme.accent
            )

            calendarSummaryColumn(
                title: L10n.string(.hicriTakvim2),
                systemImage: "moon.stars.fill",
                value: hijriLongText(for: selectedDate),
                accent: theme.accentSoft
            )
        }
        .padding(18)
        .background(calendarSurface)
    }

    private var selectedDayDhikrCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(DhikrScreenText.string(.selectedDayDhikrTitle))
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(theme.primaryText)

                Text(gregorianLongText(for: selectedDate))
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(theme.secondaryText)
            }

            if selectedDayStats.totalCount == 0 && selectedDayStats.sessionsCompleted == 0 && selectedDayDhikrs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(theme.secondaryText.opacity(0.82))

                    VStack(spacing: 6) {
                        Text(DhikrScreenText.string(.selectedDayDhikrEmptyTitle))
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(theme.primaryText)

                        Text(DhikrScreenText.string(.selectedDayDhikrEmptyMessage))
                            .font(.system(.subheadline, design: .default, weight: .regular))
                            .foregroundStyle(theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            } else {
                HStack(spacing: 10) {
                    dhikrMetricCard(
                        title: L10n.string(.istatistikToplamZikir),
                        value: selectedDayStats.totalCount.formatted(.number),
                        systemImage: "circle.grid.3x3.fill"
                    )

                    dhikrMetricCard(
                        title: DhikrScreenText.string(.selectedDaySessionsTitle),
                        value: selectedDayStats.sessionsCompleted.formatted(.number),
                        systemImage: "checkmark.seal.fill"
                    )

                    dhikrMetricCard(
                        title: DhikrScreenText.string(.selectedDayDistinctTitle),
                        value: selectedDayDhikrs.count.formatted(.number),
                        systemImage: "sparkles"
                    )
                }

                if let topDhikr = selectedDayTopDhikr {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(DhikrScreenText.string(.selectedDayTopDhikrTitle))
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(theme.primaryText)

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(topDhikr.title)
                                    .font(.system(.body, design: .rounded, weight: .semibold))
                                    .foregroundStyle(theme.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text("\(topDhikr.count.formatted(.number))")
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                    .foregroundStyle(theme.primaryText)
                            }

                            Spacer(minLength: 12)

                            goalProgressBadge
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(theme.accentSoft.opacity(theme.isDarkMode ? 0.12 : 0.18))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(theme.divider.opacity(0.16), lineWidth: 1)
                                }
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(DhikrScreenText.string(.selectedDayAllDhikrsTitle))
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(theme.primaryText)

                    VStack(spacing: 10) {
                        ForEach(selectedDayDhikrs) { item in
                            dhikrBreakdownRow(item: item)
                        }
                    }

                    if let expandedDhikrEntry {
                        expandedDhikrDetailCard(expandedDhikrEntry)
                    }
                }
            }
        }
        .padding(18)
        .background(calendarSurface)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: expandedDhikrID)
    }

    private func dhikrMetricCard(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.primaryText.opacity(0.84))

            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(theme.primaryText)

            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.cardBackground.opacity(theme.isDarkMode ? 0.82 : 0.90))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(theme.divider.opacity(0.14), lineWidth: 1)
                }
        )
    }

    private var goalProgressBadge: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(DhikrScreenText.string(.selectedDayGoalTitle))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(theme.secondaryText)

            Text("\(Int(min(dailyGoalProgress, 1) * 100).formatted(.number))%")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(theme.primaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(theme.isDarkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.58))
                .overlay {
                    Capsule().stroke(theme.divider.opacity(0.14), lineWidth: 1)
                }
        )
    }

    private func dhikrBreakdownRow(item: DhikrCalendarEntry) -> some View {
        let maxCount = max(selectedDayDhikrs.first?.count ?? 1, 1)
        let ratio = CGFloat(item.count) / CGFloat(maxCount)
        let isExpanded = expandedDhikrID == item.id

        return Button {
            guard item.hasDetail else { return }
            expandedDhikrID = isExpanded ? nil : item.id
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text(item.title)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(theme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 12)

                    if item.hasDetail {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.accent.opacity(0.92))
                    }

                    Text(item.count.formatted(.number))
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(theme.primaryText)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(theme.divider.opacity(theme.isDarkMode ? 0.20 : 0.12))

                        Capsule()
                            .fill(theme.accent.opacity(theme.isDarkMode ? 0.70 : 0.54))
                            .frame(width: max(proxy.size.width * ratio, 10))
                    }
                }
                .frame(height: 8)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.cardBackground.opacity(theme.isDarkMode ? 0.78 : 0.84))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                item.hasDetail && isExpanded ? theme.accent.opacity(0.42) : theme.divider.opacity(0.12),
                                lineWidth: 1
                            )
                    }
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String.localizedStringWithFormat(
                DhikrScreenText.string(.selectedDayCountAccessibilityFormat),
                item.title,
                item.count
            )
        )
    }

    private func expandedDhikrDetailCard(_ entry: DhikrCalendarEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(entry.title)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(theme.primaryText)

            Text(entry.arabicText)
                .font(QuranFontResolver.arabicFont(for: .classicMushaf, size: 24, relativeTo: .title2))
                .foregroundStyle(theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
                .environment(\.layoutDirection, .rightToLeft)
                .lineSpacing(12)

            if shouldShowTurkishTransliteration,
               let transliteration = entry.transliteration.trimmedNilIfEmpty {
                Text(transliteration)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(theme.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.accentSoft.opacity(theme.isDarkMode ? 0.12 : 0.18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(theme.accent.opacity(0.22), lineWidth: 1)
                }
        )
    }

    private func calendarSummaryColumn(title: String, systemImage: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(theme.secondaryText)

            Text(value)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(theme.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            RoundedRectangle(cornerRadius: 99)
                .fill(accent.opacity(theme.isDarkMode ? 0.55 : 0.40))
                .frame(height: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var calendarModePicker: some View {
        HStack(spacing: 10) {
            calendarModeChip(.gregorian, title: L10n.string(.miladi2), systemImage: "calendar")
            calendarModeChip(.hijri, title: L10n.string(.hicriTakvim2), systemImage: "moon.stars.fill")
        }
    }

    private func calendarModeChip(_ option: DhikrCalendarMode, title: String, systemImage: String) -> some View {
        let isSelected = mode == option

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                mode = option
            }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(isSelected ? theme.foregroundColor(forBackground: theme.accent) : theme.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isSelected ? theme.accent : theme.cardBackground.opacity(theme.isDarkMode ? 0.78 : 0.88))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(isSelected ? Color.white.opacity(theme.isDarkMode ? 0.14 : 0.52) : theme.divider.opacity(0.35), lineWidth: 1)
                        }
                )
        }
        .buttonStyle(.plain)
    }

    private var gregorianCalendarCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L10n.string(.miladi2))
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(theme.primaryText)
                Spacer()
            }

            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .environment(\.locale, locale)
            .tint(theme.accent)
        }
        .padding(18)
        .background(calendarSurface)
    }

    private var hijriCalendarCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    shiftHijriMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.primaryText)
                        .frame(width: 36, height: 36)
                        .background(hijriIconSurface)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(DhikrScreenText.string(.previousMonthAccessibility))

                Spacer()

                Text(hijriMonthTitle(for: hijriVisibleDate))
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(theme.primaryText)

                Spacer()

                Button {
                    shiftHijriMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.primaryText)
                        .frame(width: 36, height: 36)
                        .background(hijriIconSurface)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(DhikrScreenText.string(.nextMonthAccessibility))
            }

            weekdayHeader

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 10) {
                ForEach(Array(hijriMonthCells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        hijriDayButton(for: date)
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding(18)
        .background(calendarSurface)
    }

    private var weekdayHeader: some View {
        let symbols = reorderedWeekdaySymbols

        return HStack(spacing: 8) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func hijriDayButton(for date: Date) -> some View {
        let isSelected = gregorianCalendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = gregorianCalendar.isDateInToday(date)
        let dayNumber = hijriCalendar.component(.day, from: date)

        return Button {
            selectedDate = date
            hijriVisibleDate = date
        } label: {
            Text(dayNumber.formatted(.number))
                .font(.system(.body, design: .rounded, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? theme.foregroundColor(forBackground: theme.accent) : theme.primaryText)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            isSelected
                                ? theme.accent
                                : (isToday ? theme.accentSoft.opacity(theme.isDarkMode ? 0.24 : 0.34) : Color.clear)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isSelected ? Color.white.opacity(theme.isDarkMode ? 0.16 : 0.60) : theme.divider.opacity(isToday ? 0.35 : 0.12), lineWidth: 1)
                        }
                )
        }
        .buttonStyle(.plain)
    }

    private func religiousDayDetailCard(_ day: DhikrCalendarReligiousDay) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(day.title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(theme.primaryText)

                Text(gregorianLongText(for: selectedDate))
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(theme.secondaryText)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.string(.oGunNeYapabilirsin))
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(theme.primaryText)
                Text(day.worshipSuggestion)
                    .font(.system(.subheadline, design: .default, weight: .regular))
                    .foregroundStyle(theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.string(.kisaDua))
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(theme.primaryText)
                Text(day.duaSuggestion)
                    .font(.system(.subheadline, design: .default, weight: .regular))
                    .foregroundStyle(theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(calendarSurface)
    }

    private var upcomingDaysCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.string(.yaklasanDigerGunler))
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(theme.primaryText)

            ForEach(upcomingReligiousDays.prefix(4)) { day in
                let date = nextOccurrenceDate(for: day)

                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 4) {
                        Text(date.formatted(.dateTime.day()))
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(theme.primaryText)

                        Text(shortMonthText(for: date))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.secondaryText)
                    }
                    .frame(width: 46)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(theme.accentSoft.opacity(theme.isDarkMode ? 0.12 : 0.20))
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(day.title)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(theme.primaryText)

                        Text(gregorianLongText(for: date))
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(theme.secondaryText)

                        Text(hijriLongText(for: date))
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundStyle(theme.secondaryText.opacity(0.86))
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding(18)
        .background(calendarSurface)
    }

    private var calendarSurface: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(theme.isDarkMode ? theme.elevatedCardBackground.opacity(0.82) : Color.white.opacity(0.84))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(theme.isDarkMode ? Color.white.opacity(0.10) : theme.divider.opacity(0.20), lineWidth: 1)
            }
            .shadow(color: theme.shadowColor.opacity(theme.isDarkMode ? 0.34 : 0.10), radius: 20, y: 12)
    }

    private var hijriIconSurface: some View {
        Circle()
            .fill(theme.cardBackground.opacity(theme.isDarkMode ? 0.80 : 0.88))
            .overlay {
                Circle()
                    .stroke(theme.divider.opacity(0.25), lineWidth: 1)
            }
    }

    private var reorderedWeekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = hijriCalendar

        let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? formatter.veryShortWeekdaySymbols ?? []
        guard !symbols.isEmpty else { return [] }

        let first = max(hijriCalendar.firstWeekday - 1, 0)
        return Array(symbols[first...] + symbols[..<first])
    }

    private var hijriMonthCells: [Date?] {
        guard let monthStart = hijriMonthStart(for: hijriVisibleDate),
              let range = hijriCalendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let firstWeekday = hijriCalendar.component(.weekday, from: monthStart)
        let leading = (firstWeekday - hijriCalendar.firstWeekday + 7) % 7

        var cells = Array<Date?>(repeating: nil, count: leading)
        for day in range {
            var components = hijriCalendar.dateComponents([.year, .month], from: monthStart)
            components.day = day
            cells.append(hijriCalendar.date(from: components))
        }

        while cells.count % 7 != 0 {
            cells.append(nil)
        }

        return cells
    }

    private func shiftHijriMonth(by delta: Int) {
        if let shifted = hijriCalendar.date(byAdding: .month, value: delta, to: hijriVisibleDate) {
            hijriVisibleDate = shifted
        }
    }

    private func hijriMonthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = hijriCalendar
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }

    private func gregorianLongText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = gregorianCalendar
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    private func hijriLongText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = hijriCalendar
        formatter.dateFormat = "d MMMM yyyy, EEEE"
        return formatter.string(from: date)
    }

    private func shortMonthText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = gregorianCalendar
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased(with: locale)
    }

    private func hijriMonthStart(for date: Date) -> Date? {
        let components = hijriCalendar.dateComponents([.year, .month], from: date)
        return hijriCalendar.date(from: components)
    }

    private func matchingReligiousDay(for date: Date) -> DhikrCalendarReligiousDay? {
        let components = hijriCalendar.dateComponents([.day, .month], from: date)
        return religiousDays.first { $0.day == components.day && $0.month == components.month }
    }

    private var upcomingReligiousDays: [DhikrCalendarReligiousDay] {
        religiousDays.sorted { nextOccurrenceDate(for: $0) < nextOccurrenceDate(for: $1) }
    }

    private func nextOccurrenceDate(for religiousDay: DhikrCalendarReligiousDay) -> Date {
        let today = gregorianCalendar.startOfDay(for: Date())
        let currentYear = gregorianCalendar.component(.year, from: today)

        if let overridden = gregorianReligiousDate(for: religiousDay, year: currentYear),
           gregorianCalendar.startOfDay(for: overridden) >= today {
            return gregorianCalendar.startOfDay(for: overridden)
        }

        if let overriddenNext = gregorianReligiousDate(for: religiousDay, year: currentYear + 1),
           gregorianCalendar.startOfDay(for: overriddenNext) >= today {
            return gregorianCalendar.startOfDay(for: overriddenNext)
        }

        let currentHijriYear = hijriCalendar.component(.year, from: today)

        var components = DateComponents()
        components.calendar = hijriCalendar
        components.year = currentHijriYear
        components.month = religiousDay.month
        components.day = religiousDay.day

        let thisYear = hijriCalendar.date(from: components).map { gregorianCalendar.startOfDay(for: $0) } ?? today
        if thisYear >= today {
            return thisYear
        }

        components.year = currentHijriYear + 1
        return hijriCalendar.date(from: components).map { gregorianCalendar.startOfDay(for: $0) } ?? thisYear
    }

    private func gregorianReligiousDate(for religiousDay: DhikrCalendarReligiousDay, year: Int) -> Date? {
        let overrides: [Int: [String: DateComponents]] = [
            2026: [
                "mirac": DateComponents(year: 2026, month: 1, day: 15),
                "berat": DateComponents(year: 2026, month: 2, day: 2),
                "kadir": DateComponents(year: 2026, month: 3, day: 14),
                "ramazan_bayrami": DateComponents(year: 2026, month: 3, day: 20),
                "kurban_bayrami": DateComponents(year: 2026, month: 5, day: 27),
                "mevlid": DateComponents(year: 2026, month: 8, day: 24),
                "regaib": DateComponents(year: 2026, month: 12, day: 17)
            ]
        ]

        guard let components = overrides[year]?[religiousDay.id] else { return nil }
        return Calendar(identifier: .gregorian).date(from: components)
    }

    private var religiousDays: [DhikrCalendarReligiousDay] {
        [
            DhikrCalendarReligiousDay(
                id: "regaib",
                title: L10n.string(.religiousRegaibKandiliTitle),
                day: 1,
                month: 7,
                worshipSuggestion: L10n.string(.religiousRegaibKandiliWorship),
                duaSuggestion: L10n.string(.religiousRegaibKandiliDua)
            ),
            DhikrCalendarReligiousDay(
                id: "mirac",
                title: L10n.string(.religiousMiracKandiliTitle),
                day: 27,
                month: 7,
                worshipSuggestion: L10n.string(.religiousMiracKandiliWorship),
                duaSuggestion: L10n.string(.religiousMiracKandiliDua)
            ),
            DhikrCalendarReligiousDay(
                id: "berat",
                title: L10n.string(.religiousBeratKandiliTitle),
                day: 15,
                month: 8,
                worshipSuggestion: L10n.string(.religiousBeratKandiliWorship),
                duaSuggestion: L10n.string(.religiousBeratKandiliDua)
            ),
            DhikrCalendarReligiousDay(
                id: "kadir",
                title: L10n.string(.religiousKadirGecesiTitle),
                day: 27,
                month: 9,
                worshipSuggestion: L10n.string(.religiousKadirGecesiWorship),
                duaSuggestion: L10n.string(.religiousKadirGecesiDua)
            ),
            DhikrCalendarReligiousDay(
                id: "ramazan_bayrami",
                title: L10n.string(.religiousRamazanBayramiTitle),
                day: 1,
                month: 10,
                worshipSuggestion: L10n.string(.religiousRamazanBayramiWorship),
                duaSuggestion: L10n.string(.religiousRamazanBayramiDua)
            ),
            DhikrCalendarReligiousDay(
                id: "kurban_bayrami",
                title: L10n.string(.religiousKurbanBayramiTitle),
                day: 10,
                month: 12,
                worshipSuggestion: L10n.string(.religiousKurbanBayramiWorship),
                duaSuggestion: L10n.string(.religiousKurbanBayramiDua)
            ),
            DhikrCalendarReligiousDay(
                id: "mevlid",
                title: L10n.string(.religiousMevlidKandiliTitle),
                day: 12,
                month: 3,
                worshipSuggestion: L10n.string(.religiousMevlidKandiliWorship),
                duaSuggestion: L10n.string(.religiousMevlidKandiliDua)
            )
        ]
    }
}

private enum DhikrCalendarMode {
    case gregorian
    case hijri
}

private struct DhikrCalendarEntry: Identifiable, Hashable {
    let id: String
    let title: String
    let count: Int
    let arabicText: String
    let transliteration: String

    var hasDetail: Bool {
        !arabicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct DhikrCalendarReligiousDay: Identifiable {
    let id: String
    let title: String
    let day: Int
    let month: Int
    let worshipSuggestion: String
    let duaSuggestion: String
}

#Preview("Dhikr Calendar") {
    let storage: StorageService = {
        let storage = StorageService()
        var sample = DailyStats(date: Date())
        sample.totalCount = 132
        sample.sessionsCompleted = 2
        sample.zikirDetails = [
            "Sübhanallah": 66,
            "Elhamdülillah": 33,
            "Allahu Ekber": 33
        ]
        sample.dhikrRecords = [
            DailyDhikrRecord(
                id: "gunluk_sabah_zikri",
                title: "Sabah Zikri",
                count: 66,
                arabicText: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
                transliteration: "Sübhânallâhi ve bi-hamdihî",
                sourceID: "gunluk_sabah_zikri"
            )
        ]
        storage.allStats = [sample]
        return storage
    }()

    NavigationStack {
        DhikrCalendarView(selectedDate: .constant(Date()), storage: storage)
    }
    .environmentObject(ThemeManager.preview(theme: .sapphireCourtyard, appearanceMode: .dark))
}

private extension String {
    var trimmedNilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
