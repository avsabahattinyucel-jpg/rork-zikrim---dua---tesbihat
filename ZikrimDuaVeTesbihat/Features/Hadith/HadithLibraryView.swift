import SwiftUI

struct HadithLibraryView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme

    @ObservedObject var store: HadithStore

    @State private var searchText: String

    init(store: HadithStore, initialSearchText: String = "") {
        self.store = store
        _searchText = State(initialValue: initialSearchText)
    }

    private var theme: ActiveTheme {
        themeManager.palette(using: systemColorScheme)
    }

    private var appLanguageCode: String {
        RabiaAppLanguage.currentCode()
    }

    private var filteredHadiths: [Hadith] {
        store.filteredShortFeedHadiths(searchText: searchText, languageCode: appLanguageCode)
    }

    var body: some View {
        ZStack {
            theme.backgroundView
                .ignoresSafeArea()

            Group {
                if store.isLoading && store.hadiths.isEmpty {
                    ProgressView()
                        .controlSize(.large)
                        .tint(theme.accent)
                } else if let errorMessage = store.errorMessage, store.hadiths.isEmpty {
                    libraryStateView(
                        icon: "wifi.exclamationmark",
                        title: errorTitle,
                        message: errorMessage,
                        buttonTitle: retryTitle,
                        action: { Task { await store.reload(languageCode: appLanguageCode) } }
                    )
                } else if filteredHadiths.isEmpty {
                    libraryStateView(
                        icon: "text.page.slash",
                        title: emptyTitle,
                        message: searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? emptyLibraryMessage : emptySearchMessage,
                        buttonTitle: nil,
                        action: nil
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            libraryHero

                            ForEach(filteredHadiths) { hadith in
                                NavigationLink {
                                    HadithDetailRouteView(hadith: hadith, store: store)
                                } label: {
                                    HadithLibraryRow(hadith: hadith, theme: theme)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 32)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .navigationTitle(libraryTitle)
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text(searchPrompt)
        )
        .task {
            await store.loadIfNeeded(languageCode: appLanguageCode)
            await store.hydrateShortFeed(languageCode: appLanguageCode)
        }
    }

    private var libraryHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(libraryEyebrow)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(theme.textSecondary.opacity(0.88))
                .tracking(1.1)

            Text(libraryDescription)
                .font(.system(.title3, design: .rounded, weight: .medium))
                .foregroundStyle(theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(String.localizedStringWithFormat(resultCountFormat, filteredHadiths.count))
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .foregroundStyle(theme.textSecondary.opacity(0.82))
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var libraryTitle: String {
        String(localized: "hadith_library_title", defaultValue: "Hadisler")
    }

    private var libraryEyebrow: String {
        String(localized: "hadith_library_eyebrow", defaultValue: "GUNLUK OKUMA")
    }

    private var libraryDescription: String {
        String(localized: "hadith_library_description", defaultValue: "Secilmis hadisleri kisa ve anlasilir bicimde oku.")
    }

    private var searchPrompt: String {
        String(localized: "hadith_library_search_prompt", defaultValue: "Hadis içinde ara")
    }

    private var emptySearchMessage: String {
        String(localized: "hadith_library_empty_search_message", defaultValue: "Bu aramaya uygun bir hadis bulunamadı.")
    }

    private var resultCountFormat: String {
        String(localized: "hadith_library_result_count_format", defaultValue: "%lld hadis")
    }

    private var emptyTitle: String {
        String(localized: "hadith_library_empty_title", defaultValue: "Hadis bulunamadı")
    }

    private var emptyLibraryMessage: String {
        String(localized: "hadith_library_empty_message", defaultValue: "Gösterilecek hadis içeriği şu anda hazır değil.")
    }

    private var errorTitle: String {
        String(localized: "hadith_library_error_title", defaultValue: "Bir sorun oluştu")
    }

    private var retryTitle: String {
        String(localized: "hadith_library_retry_title", defaultValue: "Tekrar Dene")
    }

    @ViewBuilder
    private func libraryStateView(
        icon: String,
        title: String,
        message: String,
        buttonTitle: String?,
        action: (() -> Void)?
    ) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(theme.accent)

            Text(title)
                .font(.title3.bold())
                .foregroundStyle(theme.textPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let buttonTitle, let action {
                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(theme.accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

private struct HadithLibraryRow: View {
    let hadith: Hadith
    let theme: ActiveTheme

    private var previewText: String {
        hadith.shortCardText ?? hadith.title
    }

    private var referenceText: String? {
        let parts: [String] = [
            hadith.attribution?.trimmingCharacters(in: .whitespacesAndNewlines),
            hadith.grade?.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        .compactMap { value in
            guard let value, !value.isEmpty else { return nil }
            return value
        }

        if !parts.isEmpty {
            return parts.joined(separator: " • ")
        }

        return previewText == hadith.title ? nil : hadith.title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(verbatim: previewText)
                .font(.system(size: 21, weight: .regular, design: .rounded))
                .foregroundStyle(theme.textPrimary)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .bottom, spacing: 12) {
                if let referenceText {
                    Text(verbatim: referenceText)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(theme.textSecondary.opacity(0.82))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    Spacer(minLength: 0)
                }

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.textSecondary.opacity(0.6))
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(theme.elevatedCardBackground.opacity(theme.isDarkMode ? 0.96 : 0.98))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(theme.border.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: theme.shadowColor.opacity(theme.isDarkMode ? 0.18 : 0.08), radius: 18, x: 0, y: 8)
        )
    }
}

struct HadithDetailRouteView: View {
    let hadith: Hadith
    @ObservedObject var store: HadithStore

    @State private var detailState: HadithDetailState
    @State private var shareHadith: Hadith?
    @State private var lastRequestedLanguageCode: String?

    init(hadith: Hadith, store: HadithStore) {
        self.hadith = hadith
        self.store = store
        _detailState = State(initialValue: hadith.hadeeth.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .loading : .content(hadith))
    }

    private var appLanguageCode: String {
        RabiaAppLanguage.currentCode()
    }

    var body: some View {
        HadithDetailView(
            state: detailState,
            appLanguageCode: appLanguageCode,
            onShare: { hadith in
                shareHadith = hadith
            },
            onRetry: {
                Task {
                    await loadHadith(force: true)
                }
            }
        )
        .task(id: "\(hadith.id)-\(appLanguageCode)") {
            await loadHadith(force: false)
        }
        .sheet(item: $shareHadith) { hadith in
            HadithShareView(hadith: hadith)
        }
    }

    private func loadHadith(force: Bool) async {
        let normalizedLanguage = RabiaAppLanguage.normalizedCode(for: appLanguageCode)

        guard force || lastRequestedLanguageCode != normalizedLanguage else { return }

        lastRequestedLanguageCode = normalizedLanguage

        let existingBody = hadith.hadeeth.trimmingCharacters(in: .whitespacesAndNewlines)
        if !force, !existingBody.isEmpty, hadith.language == normalizedLanguage {
            detailState = .content(hadith)
            return
        }

        if existingBody.isEmpty || force {
            detailState = .loading
        }

        do {
            let resolvedHadith = try await store.hadithDetail(for: hadith, languageCode: normalizedLanguage)
            detailState = .content(resolvedHadith)
        } catch {
            detailState = .error(message: String(
                localized: "hadith_detail_error_message",
                defaultValue: "Hadis içeriği şu anda yüklenemedi."
            ))
        }
    }
}

struct HadithShareView: View {
    let hadith: Hadith

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SharePreviewScreen(
                cardType: .hadith(makeShareContent()),
                initialTheme: .night,
                showsThemePicker: true
            )
            .navigationTitle(shareNavigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.commonClose) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func makeShareContent() -> HadithShareCardContent {
        HadithShareCardContent(
            title: shareTitle,
            referenceText: hadithShareReference,
            bodyText: shareBodyText,
            fullBodyText: hadith.hadeeth,
            arabicText: nil,
            explanationText: hadith.explanation?.trimmedNilIfEmpty,
            narratorText: hadith.attribution?.trimmedNilIfEmpty,
            gradeText: hadith.grade?.trimmedNilIfEmpty,
            brandingTitle: AppName.full,
            brandingSubtitle: ShareCardBranding.storeSubtitle
        )
    }

    private var shareTitle: String {
        if let shortText = hadith.shortCardText?.trimmingCharacters(in: .whitespacesAndNewlines),
           !shortText.isEmpty {
            return shortText
        }

        return hadith.title
    }

    private var shareBodyText: String {
        if normalizedAppLanguageCode == "ar" {
            if let arabicText = hadith.hadeethArabic?.trimmingCharacters(in: .whitespacesAndNewlines),
               !arabicText.isEmpty {
                return arabicText
            }
        }

        return hadith.hadeeth
    }

    private var normalizedAppLanguageCode: String {
        RabiaAppLanguage.normalizedCode(for: RabiaAppLanguage.currentCode())
    }

    private var hadithShareReference: String? {
        let parts = [hadith.attribution?.trimmedNilIfEmpty, hadith.grade?.trimmedNilIfEmpty]
            .compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }

    private var shareNavigationTitle: String {
        String(localized: "hadith_share_navigation_title", defaultValue: "Hadis paylaş")
    }

}

private extension String {
    var trimmedNilIfEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
