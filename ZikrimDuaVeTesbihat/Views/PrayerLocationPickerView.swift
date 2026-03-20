import CoreLocation
import SwiftUI

struct PrayerLocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var query: String = ""
    @FocusState private var isSearchFocused: Bool

    let viewModel: PrayerTimesViewModel

    private var theme: ActiveTheme { themeManager.current }

    private var appLocale: Locale {
        Locale(identifier: RabiaAppLanguage.currentCode())
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var mergedSearchResults: [CitySearchResult] {
        guard !trimmedQuery.isEmpty else { return [] }
        return viewModel.searchResults
    }

    private var shouldShowEmptyState: Bool {
        !trimmedQuery.isEmpty && mergedSearchResults.isEmpty && !viewModel.isSearching
    }

    private var selectedLocationSubtitle: String? {
        switch viewModel.locationMode {
        case .automatic:
            return L10n.string(.currentLocationAutoDetected)
        case .manual:
            return viewModel.manualLocation?.subtitle ?? L10n.string(.chooseCityPrompt)
        }
    }

    private var modeBadge: String {
        viewModel.locationModeBadge.uppercased(with: appLocale)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                searchSection

                if trimmedQuery.isEmpty, !viewModel.recentLocations.isEmpty {
                    recentSection
                }

                if !trimmedQuery.isEmpty || viewModel.isSearching {
                    searchResultsSection
                }

                if let message = statusMessage {
                    statusRow(message)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(sheetBackground.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }

    private var heroCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(heroGradient)

            Circle()
                .fill(theme.accent.opacity(theme.isDarkMode ? 0.22 : 0.16))
                .frame(width: 180, height: 180)
                .blur(radius: 18)
                .offset(x: -32, y: -42)

            Circle()
                .fill(Color.white.opacity(theme.isDarkMode ? 0.10 : 0.22))
                .frame(width: 150, height: 150)
                .blur(radius: 24)
                .offset(x: 210, y: 72)

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(theme.isDarkMode ? 0.16 : 0.74))
                            .frame(width: 56, height: 56)

                        Image(systemName: viewModel.locationMode == .automatic ? "location.fill" : "mappin.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(theme.accent)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.string(.prayerLocationTitle))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(theme.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Text(viewModel.locationChipText)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let subtitle = selectedLocationSubtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer(minLength: 8)

                    Text(modeBadge)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(theme.isDarkMode ? 0.12 : 0.72), in: Capsule())
                }

                HStack(spacing: 12) {
                    quickActionButton(
                        title: L10n.string(.useCurrentLocation),
                        icon: "location.fill",
                        isSelected: viewModel.locationMode == .automatic
                    ) {
                        viewModel.useAutomaticLocation()
                        closeSheet()
                    }

                    quickActionButton(
                        title: L10n.string(.searchCity),
                        icon: "magnifyingglass",
                        isSelected: viewModel.locationMode == .manual || isSearchFocused
                    ) {
                        withAnimation(.easeOut(duration: 0.18)) {
                            isSearchFocused = true
                        }
                    }
                }
            }
            .padding(22)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(theme.isDarkMode ? 0.10 : 0.36), lineWidth: 1)
        )
        .shadow(color: theme.shadowColor.opacity(theme.isDarkMode ? 0.22 : 0.10), radius: 18, y: 10)
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(L10n.string(.searchCity))

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(theme.selectionBackground.opacity(theme.isDarkMode ? 0.68 : 0.88))
                            .frame(width: 38, height: 38)

                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(theme.accent)
                    }

                    TextField(L10n.string(.searchCity), text: $query)
                        .focused($isSearchFocused)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .foregroundStyle(theme.textPrimary)
                        .onChange(of: query) { _, newValue in
                            viewModel.scheduleCitySearch(query: newValue)
                        }

                    if viewModel.isSearching {
                        ProgressView()
                            .controlSize(.small)
                            .tint(theme.accent)
                    } else if !trimmedQuery.isEmpty {
                        Button {
                            query = ""
                            viewModel.scheduleCitySearch(query: "")
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(L10n.string(.commonClose))
                    }
                }

                if trimmedQuery.isEmpty {
                    Text(L10n.string(.chooseCityPrompt))
                        .font(.footnote)
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .padding(16)
            .background(searchCardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(theme.isDarkMode ? 0.08 : 0.38), lineWidth: 1)
            )
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                sectionTitle(L10n.string(.recentLocations))

                Spacer(minLength: 0)

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.clearRecentLocations()
                    }
                } label: {
                    Text(L10n.string(.sil2))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(theme.selectionBackground.opacity(theme.isDarkMode ? 0.52 : 0.86), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.string(.sil2))
            }

            LazyVStack(spacing: 12) {
                ForEach(viewModel.recentLocations, id: \.self) { location in
                    locationRow(
                        title: location.city,
                        subtitle: location.country.isEmpty ? nil : location.country,
                        icon: location.source == .automatic ? "location.fill" : "mappin.circle.fill",
                        badge: location.source == .automatic
                            ? L10n.string(.useCurrentLocation)
                            : L10n.string(.manualCity),
                        isSelected: isSelected(location),
                        action: {
                            clearSearchState()
                            viewModel.selectRecentLocation(location)
                            closeSheet()
                        }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                viewModel.removeRecentLocation(location)
                            }
                        } label: {
                            Label(L10n.string(.sil2), systemImage: "trash")
                        }
                    }
                    .accessibilityLabel(location.city)
                    .accessibilityHint(location.source == .automatic ? L10n.string(.useCurrentLocation) : L10n.string(.chooseCity))
                }
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(L10n.string(.searchCity))

            if viewModel.isSearching {
                loadingRow
            } else if shouldShowEmptyState {
                emptyRow
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(mergedSearchResults.prefix(8)) { result in
                        locationRow(
                            title: result.name,
                            subtitle: result.subtitle,
                            icon: "mappin.circle.fill",
                        badge: nil,
                        isSelected: isSelected(result),
                        action: {
                            clearSearchState()
                            viewModel.selectManualCity(result)
                            closeSheet()
                        }
                        )
                        .accessibilityLabel(result.name)
                        .accessibilityHint(result.subtitle ?? L10n.string(.chooseCityPrompt))
                    }
                }
            }
        }
    }

    private var loadingRow: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(theme.accent)

            Text(L10n.string(.loading))
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(theme.cardBackground.opacity(0.96), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(theme.border.opacity(0.55), lineWidth: 1)
        )
    }

    private var emptyRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.string(.noResults))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.textPrimary)

            Text(L10n.string(.chooseCityPrompt))
                .font(.footnote)
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(theme.cardBackground.opacity(0.96), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(theme.border.opacity(0.55), lineWidth: 1)
        )
    }

    private func statusRow(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(theme.accent)

            Text(message)
                .font(.footnote)
                .foregroundStyle(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(theme.selectionBackground.opacity(theme.isDarkMode ? 0.70 : 0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(.footnote, design: .rounded).weight(.semibold))
            .foregroundStyle(theme.textSecondary)
            .textCase(.uppercase)
            .tracking(0.6)
    }

    private var sheetBackground: some View {
        ZStack {
            theme.appBackground.opacity(0.98)

            LinearGradient(
                colors: [
                    theme.selectionBackground.opacity(theme.isDarkMode ? 0.28 : 0.40),
                    theme.appBackground.opacity(0)
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
    }

    private var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                theme.selectionBackground.opacity(theme.isDarkMode ? 0.92 : 0.96),
                theme.cardBackground.opacity(0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var searchCardBackground: LinearGradient {
        LinearGradient(
            colors: [
                theme.cardBackground.opacity(0.98),
                theme.selectionBackground.opacity(theme.isDarkMode ? 0.28 : 0.52)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func quickActionButton(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? theme.accentForeground : theme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(theme.accent) : AnyShapeStyle(Color.white.opacity(theme.isDarkMode ? 0.10 : 0.72)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(theme.isDarkMode ? 0.08 : 0.28), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func locationRow(
        title: String,
        subtitle: String?,
        icon: String,
        badge: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        PrayerLocationCard(
            title: title,
            subtitle: subtitle,
            icon: icon,
            badge: badge,
            isSelected: isSelected,
            action: action
        )
    }

    private func isSelected(_ location: PrayerLocation) -> Bool {
        switch viewModel.locationMode {
        case .automatic:
            return location.source == .automatic
        case .manual:
            guard let manualLocation = viewModel.manualLocation else { return false }
            return abs(location.latitude - manualLocation.latitude) < 0.0001
                && abs(location.longitude - manualLocation.longitude) < 0.0001
        }
    }

    private func isSelected(_ result: CitySearchResult) -> Bool {
        guard viewModel.locationMode == .manual, let manualLocation = viewModel.manualLocation else { return false }
        return abs(result.coordinate.latitude - manualLocation.latitude) < 0.0001
            && abs(result.coordinate.longitude - manualLocation.longitude) < 0.0001
    }

    private func closeSheet() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
            dismiss()
        }
    }

    private func clearSearchState() {
        query = ""
        isSearchFocused = false
        viewModel.scheduleCitySearch(query: "")
    }

    private var statusMessage: String? {
        let trimmed = (viewModel.errorMessage ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct PrayerLocationCard: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let title: String
    let subtitle: String?
    let icon: String
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(iconBackground)
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : theme.accent)
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(theme.textPrimary)
                            .multilineTextAlignment(.leading)

                        if let badge, !badge.isEmpty {
                            Text(badge.uppercased())
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(isSelected ? theme.accentForeground.opacity(0.86) : theme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Color.white.opacity(0.18) : theme.selectionBackground.opacity(0.9))
                                )
                        }
                    }

                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(theme.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .font(.system(size: isSelected ? 19 : 14, weight: .semibold))
                    .foregroundStyle(isSelected ? theme.accent : theme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? theme.accent.opacity(0.36) : theme.border.opacity(0.52), lineWidth: 1)
            )
            .shadow(color: isSelected ? theme.accent.opacity(theme.isDarkMode ? 0.16 : 0.10) : theme.shadowColor.opacity(0.06), radius: isSelected ? 18 : 10, y: isSelected ? 10 : 5)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private var cardBackground: LinearGradient {
        LinearGradient(
            colors: isSelected
                ? [
                    theme.selectionBackground.opacity(theme.isDarkMode ? 0.88 : 0.96),
                    theme.cardBackground.opacity(0.98)
                ]
                : [
                    theme.cardBackground.opacity(0.98),
                    theme.cardBackground.opacity(0.92)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var iconBackground: LinearGradient {
        LinearGradient(
            colors: isSelected
                ? [theme.accent.opacity(0.90), theme.accent.opacity(0.68)]
                : [
                    theme.selectionBackground.opacity(theme.isDarkMode ? 0.64 : 0.90),
                    theme.selectionBackground.opacity(theme.isDarkMode ? 0.34 : 0.70)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
