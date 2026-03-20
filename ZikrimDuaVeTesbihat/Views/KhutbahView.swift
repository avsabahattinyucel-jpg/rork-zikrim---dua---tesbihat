import SwiftUI

private enum KhutbahReadingTheme: String, CaseIterable {
    case plain
    case sepia
    case dark

    var accent: Color {
        switch self {
        case .plain:
            return Color(red: 0.15, green: 0.49, blue: 0.46)
        case .sepia:
            return Color(red: 0.63, green: 0.46, blue: 0.24)
        case .dark:
            return Color(red: 0.60, green: 0.84, blue: 0.79)
        }
    }

    var cardBackground: Color {
        switch self {
        case .plain:
            return Color(.secondarySystemGroupedBackground)
        case .sepia:
            return Color(red: 0.98, green: 0.95, blue: 0.89)
        case .dark:
            return Color(red: 0.10, green: 0.11, blue: 0.13)
        }
    }

    var primaryText: Color {
        switch self {
        case .plain:
            return .primary
        case .sepia:
            return Color(red: 0.29, green: 0.21, blue: 0.12)
        case .dark:
            return Color(red: 0.93, green: 0.94, blue: 0.92)
        }
    }

    var secondaryText: Color {
        switch self {
        case .plain:
            return .secondary
        case .sepia:
            return Color(red: 0.45, green: 0.34, blue: 0.22)
        case .dark:
            return Color(red: 0.70, green: 0.73, blue: 0.72)
        }
    }

    var border: Color {
        switch self {
        case .plain:
            return Color.black.opacity(0.08)
        case .sepia:
            return accent.opacity(0.18)
        case .dark:
            return Color.white.opacity(0.08)
        }
    }
}

struct KhutbahView: View {
    @State private var service = KhutbahService()
    @State private var narrationService = KhutbahSummaryNarrationService()
    @State private var fontSize: CGFloat = 16
    @State private var showSharePreview: Bool = false
    @AppStorage("khutbah_reading_theme") private var readingThemeRawValue: String = KhutbahReadingTheme.plain.rawValue

    private var readingTheme: KhutbahReadingTheme {
        get { KhutbahReadingTheme(rawValue: readingThemeRawValue) ?? .plain }
        nonmutating set { readingThemeRawValue = newValue.rawValue }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if service.isLoading && service.content == nil {
                loadingView
            } else if let khutbah = service.content {
                mainContent(khutbah)
            } else if let err = service.errorMessage {
                errorView(err)
            } else {
                loadingView
            }
        }
        .navigationTitle(L10n.string(.haftaninHutbesi))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    shareKhutbahSummaryCard()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .task { await service.fetch() }
        .task(id: service.content?.hutbahId ?? service.content?.date ?? "khutbah-summary") {
            guard service.content != nil else { return }
            guard service.summaryRecord == nil, !service.isSummaryLoading else { return }
            await service.loadWeeklySummary(hutbahId: service.content?.hutbahId)
        }
        .onDisappear {
            narrationService.stop()
        }
        .sheet(isPresented: $showSharePreview) {
            if let khutbah = service.content {
                NavigationStack {
                    SharePreviewScreen(
                        cardType: makeKhutbahShareCardType(from: khutbah),
                        initialTheme: .night,
                        showsThemePicker: true
                    )
                    .navigationTitle(L10n.string(.shareCardFridayKhutbah))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(.commonClose) {
                                showSharePreview = false
                            }
                        }
                    }
                }
            }
        }
    }

    private func mainContent(_ khutbah: KhutbahContent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard(khutbah)
                summaryCard

                fontSizeBar
                fullTextCard(khutbah)
                actionRow

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
    }

    private func headerCard(_ khutbah: KhutbahContent) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(khutbah.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if !khutbah.date.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(khutbah.date)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                HStack(spacing: 5) {
                    Image(systemName: "building.columns")
                        .font(.caption2)
                    Text(.diyanetIsleriBaskanligi)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color.teal.opacity(0.7), Color.blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: "text.book.closed.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    @ViewBuilder
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.subheadline.bold())
                    .foregroundStyle(.teal)
                Text(KhutbahSummaryL10n.summaryTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Spacer()
                if service.isSummaryLoading {
                    ProgressView()
                        .scaleEffect(0.75)
                        .tint(.teal)
                } else {
                    HStack(spacing: 8) {
                        if let summaryText = service.summaryText {
                            Button {
                                narrationService.togglePlayback(
                                    text: summaryText,
                                    languageCode: service.summaryRecord?.language ?? RabiaAppLanguage.currentCode()
                                )
                            } label: {
                                Image(systemName: narrationService.isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
                                    .font(.caption.bold())
                                    .foregroundStyle(.teal)
                                    .frame(width: 28, height: 28)
                                    .background(Color.teal.opacity(0.12))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                narrationService.isSpeaking
                                    ? KhutbahSummaryL10n.stopListeningTitle
                                    : KhutbahSummaryL10n.listenTitle
                            )
                        }

                        Text(KhutbahSummaryL10n.weeklyBadge)
                            .font(.caption2.bold())
                            .foregroundStyle(.teal)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.teal.opacity(0.12))
                            .clipShape(.capsule)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            if service.isSummaryLoading && service.summaryRecord == nil {
                HStack(spacing: 10) {
                    ProgressView().tint(.teal)
                    Text(KhutbahSummaryL10n.loadingText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            } else if let error = service.summaryError, service.summaryRecord == nil {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.top, 1)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(KhutbahSummaryL10n.unavailableTitle)
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Button {
                            Task { await service.loadWeeklySummary() }
                        } label: {
                            Label(.tekrarDene2, systemImage: "arrow.clockwise")
                                .font(.caption.bold())
                                .foregroundStyle(.teal)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            } else if let summaryText = service.summaryText {
                Text(summaryText)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                Text(KhutbahSummaryL10n.footerNote(for: service.summaryRecord?.model))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            } else {
                HStack(spacing: 10) {
                    ProgressView().tint(.teal)
                    Text(KhutbahSummaryL10n.loadingText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.teal.opacity(0.07), Color.blue.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.teal.opacity(0.3), lineWidth: 1)
        )
    }

    private var fontSizeBar: some View {
        HStack(spacing: 12) {
            Text(.yaziBoyutu)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 0) {
                Button {
                    withAnimation { fontSize = max(12, fontSize - 2) }
                } label: {
                    Image(systemName: "minus")
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 32)
                }

                Text(L10n.format(.numberFormat, Int64(fontSize)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 28)

                Button {
                    withAnimation { fontSize = min(22, fontSize + 2) }
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 32)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .padding(.horizontal, 4)
    }

    private func fullTextCard(_ khutbah: KhutbahContent) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(.hutbeMetni, systemImage: "doc.text")
                    .font(.caption.bold())
                    .foregroundStyle(readingTheme.secondaryText)
                    .textCase(.uppercase)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(KhutbahSummaryL10n.readingModeTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(readingTheme.secondaryText)

                HStack(spacing: 8) {
                    ForEach(KhutbahReadingTheme.allCases, id: \.rawValue) { option in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                readingTheme = option
                            }
                        } label: {
                            Text(KhutbahSummaryL10n.readingThemeName(option))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(readingTheme == option ? colorSchemeAwareChipForeground(for: option) : readingTheme.secondaryText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(colorSchemeAwareChipBackground(for: option))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(option.accent.opacity(readingTheme == option ? 0.34 : 0.16), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            Text(khutbah.content)
                .font(.system(size: fontSize, weight: .regular, design: readingTheme == .plain ? .default : .serif))
                .foregroundStyle(readingTheme.primaryText)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(readingTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(readingTheme.border, lineWidth: 1)
        )
    }

    private func colorSchemeAwareChipBackground(for option: KhutbahReadingTheme) -> some ShapeStyle {
        readingTheme == option ? option.accent.opacity(option == .dark ? 0.22 : 0.16) : option.cardBackground
    }

    private func colorSchemeAwareChipForeground(for option: KhutbahReadingTheme) -> Color {
        option == .dark ? option.primaryText : option.accent
    }

    private var actionRow: some View {
        Button {
            shareKhutbahSummaryCard()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                Text(.paylas)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .foregroundStyle(.primary)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.1))
                    .frame(width: 80, height: 80)
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(.teal)
            }
            VStack(spacing: 6) {
                Text(.hutbeYukleniyor2)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(.diyanetTenBuHaftaninHutbesiGetiriliyor)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.08))
                    .frame(width: 90, height: 90)
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 40))
                    .foregroundStyle(.red.opacity(0.7))
            }

            VStack(spacing: 10) {
                Text(.hutbeYuklenemedi)
                    .font(.title3.bold())
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 12) {
                Button {
                    Task { await service.fetch() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text(.tekrarDene2)
                            .fontWeight(.semibold)
                    }
                    .frame(width: 220, height: 50)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.teal))
                    .foregroundStyle(.white)
                }

                Link(destination: URL(string: "https://www.diyanethaber.com.tr/hutbeler")!) {
                    HStack(spacing: 8) {
                        Image(systemName: "safari")
                        Text(.diyanetSitesiniAc)
                            .fontWeight(.medium)
                    }
                    .frame(width: 220, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .foregroundStyle(.teal)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @MainActor
    private func shareKhutbahSummaryCard() {
        guard service.content != nil else { return }
        showSharePreview = true
    }

    private func makeKhutbahShareCardType(from khutbah: KhutbahContent) -> ShareCardType {
        let fallbackText = service.summaryText ?? String(khutbah.content.prefix(360))
        return .khutbah(
            KhutbahShareCardContent(
                title: khutbah.title,
                dateText: khutbah.date,
                mainTheme: "",
                lessons: [],
                weeklyTask: nil,
                fallbackText: fallbackText,
                brandingTitle: AppName.full,
                brandingSubtitle: ShareCardBranding.storeSubtitle
            )
        )
    }
}

private enum KhutbahSummaryL10n {
    private static var language: AppLanguage { AppLanguage(code: RabiaAppLanguage.currentCode()) }

    static var summaryTitle: String {
        switch language {
        case .tr: return "Hutbe Özeti"
        case .en: return "Khutbah Summary"
        case .de: return "Khutba-Zusammenfassung"
        case .ar: return "ملخص الخطبة"
        case .fr: return "Resume du khutbah"
        case .es: return "Resumen de la jutba"
        case .id: return "Ringkasan Khutbah"
        case .ur: return "خطبہ خلاصہ"
        case .ms: return "Ringkasan Khutbah"
        case .ru: return "Краткое содержание хутбы"
        case .fa: return "خلاصه خطبه"
        }
    }

    static var weeklyBadge: String {
        switch language {
        case .tr: return "Haftalık"
        case .en: return "Weekly"
        case .de: return "Wochentlich"
        case .ar: return "أسبوعي"
        case .fr: return "Hebdomadaire"
        case .es: return "Semanal"
        case .id: return "Mingguan"
        case .ur: return "ہفتہ وار"
        case .ms: return "Mingguan"
        case .ru: return "Еженедельно"
        case .fa: return "هفتگی"
        }
    }

    static var loadingText: String {
        switch language {
        case .tr: return "Haftalık hutbe özeti yükleniyor..."
        case .en: return "Loading the weekly khutbah summary..."
        case .de: return "Die wochentliche Khutba-Zusammenfassung wird geladen..."
        case .ar: return "جار تحميل ملخص الخطبة الأسبوعي..."
        case .fr: return "Chargement du resume hebdomadaire du khutbah..."
        case .es: return "Se esta cargando el resumen semanal de la jutba..."
        case .id: return "Ringkasan khutbah mingguan sedang dimuat..."
        case .ur: return "ہفتہ وار خطبہ خلاصہ لوڈ ہو رہا ہے..."
        case .ms: return "Ringkasan khutbah mingguan sedang dimuatkan..."
        case .ru: return "Загружается еженедельное краткое содержание хутбы..."
        case .fa: return "خلاصه هفتگی خطبه در حال بارگذاری است..."
        }
    }

    static var unavailableTitle: String {
        switch language {
        case .tr: return "Haftalık özet şu an kullanılamıyor"
        case .en: return "The weekly summary is unavailable right now"
        case .de: return "Die wochentliche Zusammenfassung ist momentan nicht verfugbar"
        case .ar: return "الملخص الأسبوعي غير متاح الآن"
        case .fr: return "Le resume hebdomadaire n'est pas disponible pour le moment"
        case .es: return "El resumen semanal no esta disponible en este momento"
        case .id: return "Ringkasan mingguan belum tersedia saat ini"
        case .ur: return "ہفتہ وار خلاصہ اس وقت دستیاب نہیں"
        case .ms: return "Ringkasan mingguan tidak tersedia buat masa ini"
        case .ru: return "Еженедельное краткое содержание сейчас недоступно"
        case .fa: return "خلاصه هفتگی در حال حاضر در دسترس نیست"
        }
    }

    static var footerNote: String {
        footerNote(for: nil)
    }

    static func footerNote(for model: String?) -> String {
        _ = model
        switch language {
        case .tr: return "Bu özet haftalık olarak ayrı bir sistemde hazırlanır."
        case .en: return "This summary is prepared weekly in a separate system."
        case .de: return "Diese Zusammenfassung wird wochentlich in einem separaten System erstellt."
        case .ar: return "يتم إعداد هذا الملخص أسبوعيا في نظام منفصل."
        case .fr: return "Ce resume est prepare chaque semaine dans un systeme distinct."
        case .es: return "Este resumen se prepara semanalmente en un sistema independiente."
        case .id: return "Ringkasan ini disiapkan mingguan dalam sistem terpisah."
        case .ur: return "یہ خلاصہ ہفتہ وار ایک الگ نظام میں تیار ہوتا ہے۔"
        case .ms: return "Ringkasan ini disediakan setiap minggu dalam sistem berasingan."
        case .ru: return "Это краткое содержание готовится еженедельно в отдельной системе."
        case .fa: return "این خلاصه به صورت هفتگی در یک سامانه جداگانه آماده می شود."
        }
    }

    static var listenTitle: String {
        switch language {
        case .tr: return "Özeti Dinle"
        case .en: return "Listen to Summary"
        case .de: return "Zusammenfassung anhören"
        case .ar: return "استمع إلى الملخص"
        case .fr: return "Ecouter le resume"
        case .es: return "Escuchar resumen"
        case .id: return "Dengarkan ringkasan"
        case .ur: return "خلاصہ سنیں"
        case .ms: return "Dengar ringkasan"
        case .ru: return "Слушать краткое содержание"
        case .fa: return "خلاصه را بشنو"
        }
    }

    static var stopListeningTitle: String {
        switch language {
        case .tr: return "Dinlemeyi Durdur"
        case .en: return "Stop Listening"
        case .de: return "Wiedergabe stoppen"
        case .ar: return "إيقاف الاستماع"
        case .fr: return "Arreter l'ecoute"
        case .es: return "Detener audio"
        case .id: return "Hentikan audio"
        case .ur: return "آواز بند کریں"
        case .ms: return "Hentikan audio"
        case .ru: return "Остановить озвучивание"
        case .fa: return "پخش را متوقف کن"
        }
    }

    static var readingModeTitle: String {
        switch language {
        case .tr: return "Okuma modu"
        case .en: return "Reading mode"
        case .de: return "Lesemodus"
        case .ar: return "وضع القراءة"
        case .fr: return "Mode lecture"
        case .es: return "Modo de lectura"
        case .id: return "Mode baca"
        case .ur: return "مطالعہ موڈ"
        case .ms: return "Mod bacaan"
        case .ru: return "Режим чтения"
        case .fa: return "حالت مطالعه"
        }
    }

    static func readingThemeName(_ theme: KhutbahReadingTheme) -> String {
        switch theme {
        case .plain:
            switch language {
            case .tr: return "Sade"
            case .en: return "Plain"
            case .de: return "Klar"
            case .ar: return "بسيط"
            case .fr: return "Simple"
            case .es: return "Simple"
            case .id: return "Sederhana"
            case .ur: return "سادہ"
            case .ms: return "Biasa"
            case .ru: return "Светлый"
            case .fa: return "ساده"
            }
        case .sepia:
            switch language {
            case .tr: return "Sepya"
            case .en: return "Sepia"
            case .de: return "Sepia"
            case .ar: return "سيبيا"
            case .fr: return "Sepia"
            case .es: return "Sepia"
            case .id: return "Sepia"
            case .ur: return "سیپیا"
            case .ms: return "Sepia"
            case .ru: return "Сепия"
            case .fa: return "سپیا"
            }
        case .dark:
            switch language {
            case .tr: return "Koyu"
            case .en: return "Dark"
            case .de: return "Dunkel"
            case .ar: return "داكن"
            case .fr: return "Sombre"
            case .es: return "Oscuro"
            case .id: return "Gelap"
            case .ur: return "گہرا"
            case .ms: return "Gelap"
            case .ru: return "Тёмный"
            case .fa: return "تیره"
            }
        }
    }

}
