import SwiftUI

private enum DiyanetReadingTheme: String, CaseIterable {
    case plain
    case sepia
    case dark

    var displayName: String {
        switch self {
        case .plain:
            return "Sade"
        case .sepia:
            return "Sepya"
        case .dark:
            return "Koyu"
        }
    }

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

    var screenBackground: Color {
        switch self {
        case .plain:
            return Color(red: 0.97, green: 0.98, blue: 0.99)
        case .sepia:
            return Color(red: 0.96, green: 0.92, blue: 0.84)
        case .dark:
            return Color(red: 0.06, green: 0.07, blue: 0.08)
        }
    }

    var cardBackground: Color {
        switch self {
        case .plain:
            return .white
        case .sepia:
            return Color(red: 0.98, green: 0.95, blue: 0.89)
        case .dark:
            return Color(red: 0.10, green: 0.11, blue: 0.13)
        }
    }

    var primaryText: Color {
        switch self {
        case .plain:
            return Color(red: 0.08, green: 0.11, blue: 0.14)
        case .sepia:
            return Color(red: 0.29, green: 0.21, blue: 0.12)
        case .dark:
            return Color(red: 0.93, green: 0.94, blue: 0.92)
        }
    }

    var secondaryText: Color {
        switch self {
        case .plain:
            return Color(red: 0.30, green: 0.36, blue: 0.42)
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
            return Color(red: 0.63, green: 0.46, blue: 0.24).opacity(0.18)
        case .dark:
            return Color.white.opacity(0.08)
        }
    }
}

struct DiyanetKnowledgeDetailView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    let record: DiyanetKnowledgeRecord

    @State private var showFullSourceURL: Bool = false
    @State private var showSharePreview: Bool = false
    @AppStorage("diyanet_reading_mode_enabled") private var isReadingModeEnabled: Bool = false
    @AppStorage("diyanet_reading_font_scale") private var readingFontScale: Double = 1.0
    @AppStorage("diyanet_reading_line_spacing") private var readingLineSpacing: Double = 5.0
    @AppStorage("diyanet_reading_theme") private var readingThemeRawValue: String = DiyanetReadingTheme.plain.rawValue
    @State private var isImmersiveReadingEnabled: Bool = false

    private var theme: AppTheme {
        themeManager.palette(using: systemColorScheme)
    }

    private var readingTheme: DiyanetReadingTheme {
        get { DiyanetReadingTheme(rawValue: readingThemeRawValue) ?? .plain }
        nonmutating set { readingThemeRawValue = newValue.rawValue }
    }

    private var effectiveFontScale: CGFloat {
        CGFloat(min(max(readingFontScale, 0.9), 1.45))
    }

    private var effectiveLineSpacing: CGFloat {
        CGFloat(min(max(readingLineSpacing, 4.0), 12.0))
    }

    private var effectiveBodyFont: Font {
        .system(size: 17 * effectiveFontScale, weight: .regular, design: .serif)
    }

    private var screenBackground: some View {
        Group {
            if isReadingModeEnabled {
                readingTheme.screenBackground
            } else {
                themeManager.currentTheme.backgroundView
            }
        }
    }

    private var activeAccentColor: Color {
        isReadingModeEnabled ? readingTheme.accent : theme.accent
    }

    private var activePrimaryTextColor: Color {
        isReadingModeEnabled ? readingTheme.primaryText : theme.primaryText
    }

    private var activeSecondaryTextColor: Color {
        isReadingModeEnabled ? readingTheme.secondaryText : theme.secondaryText
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            screenBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !isImmersiveReadingEnabled {
                        headerCard
                    }

                    if isReadingModeEnabled, !isImmersiveReadingEnabled {
                        readingModeControlsCard
                    } else if !isReadingModeEnabled {
                        metadataCard
                    }

                    if let question = record.questionClean, !question.isEmpty, question != record.displayTitle, !isImmersiveReadingEnabled {
                        questionCard(question)
                    }

                    officialTextCard

                    if !isReadingModeEnabled && !isImmersiveReadingEnabled {
                        sourceCard
                    }
                }
                .padding(.horizontal, isImmersiveReadingEnabled ? 14 : 18)
                .padding(.top, isImmersiveReadingEnabled ? 12 : 16)
                .padding(.bottom, isImmersiveReadingEnabled ? 112 : 32)
            }

            if isImmersiveReadingEnabled {
                immersiveControlsBar
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
            }
        }
        .themedNavigation(title: record.type.displayName, displayMode: .large)
        .toolbar(isImmersiveReadingEnabled ? .hidden : .visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                        isReadingModeEnabled.toggle()
                        if !isReadingModeEnabled {
                            isImmersiveReadingEnabled = false
                        }
                    }
                } label: {
                    Image(systemName: isReadingModeEnabled ? "text.book.closed.fill" : "text.book.closed")
                }
                .accessibilityLabel(isReadingModeEnabled ? "Okuma modunu kapat" : "Okuma modunu aç")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSharePreview = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Diyanet içeriğini paylaş")
            }
        }
        .sheet(isPresented: $showSharePreview) {
            NavigationStack {
                SharePreviewScreen(
                    cardType: makeShareCardType(),
                    initialTheme: .emerald,
                    showsThemePicker: true
                )
                .navigationTitle("Diyanet Paylaşımı")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Kapat") {
                            showSharePreview = false
                        }
                    }
                }
            }
        }
        .onAppear {
            RabiaRuntimeContextStore.shared.setDiyanetContext(for: record)
        }
        .onDisappear {
            RabiaRuntimeContextStore.shared.clearDiyanetContext()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.82), Color.teal.opacity(0.68)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: record.type.systemImage)
                        .font(.title3)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.type.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(activeAccentColor)
                        .tracking(0.8)
                    Text(record.displayTitle)
                        .font(isReadingModeEnabled ? .system(.title2, design: .serif).bold() : .title3.bold())
                        .foregroundStyle(activePrimaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .background(headerCardBackground)
    }

    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kayıt Bilgileri")
                .font(.headline)
                .foregroundStyle(activePrimaryTextColor)

            infoRow(label: "Kaynak", value: record.sourceName)
            infoRow(label: "Alan adı", value: record.sourceHostLabel)

            if !record.categoryPath.isEmpty {
                infoRow(label: "Kategori", value: record.categoryPath.joined(separator: " > "))
            }

            if let year = record.decisionYear, !year.isEmpty {
                infoRow(label: "Yıl", value: year)
            }

            if let number = record.decisionNo, !number.isEmpty {
                infoRow(label: "Karar / No", value: number)
            }

            if let subject = record.subject, !subject.isEmpty, subject != record.displayTitle {
                infoRow(label: "Konu", value: subject)
            }
        }
        .padding(16)
        .background(standardCardBackground)
    }

    private var readingModeControlsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Okuma Modu")
                    .font(.headline)
                    .foregroundStyle(activePrimaryTextColor)

                Spacer()

                dailyStyleChip("Açık", tint: activeAccentColor)
            }

            Text("Resmi metni daha rahat okumak için yazı boyutunu ve satır aralığını ayarlayabilirsin.")
                .font(.subheadline)
                .foregroundStyle(activeSecondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                Label("Okuma teması", systemImage: "paintpalette.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(activePrimaryTextColor)

                HStack(spacing: 8) {
                    ForEach(DiyanetReadingTheme.allCases, id: \.rawValue) { option in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                readingTheme = option
                            }
                        } label: {
                            Text(option.displayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(readingTheme == option ? readingThemeChipForeground(option) : activeSecondaryTextColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(readingThemeChipBackground(option))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(option.accent.opacity(readingTheme == option ? 0.36 : 0.18), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Yazı boyutu", systemImage: "textformat.size")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(activePrimaryTextColor)
                    Spacer()
                    Text("\(Int(effectiveFontScale * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(activeSecondaryTextColor)
                }

                Slider(value: $readingFontScale, in: 0.9...1.45, step: 0.05)
                    .tint(activeAccentColor)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Satır aralığı", systemImage: "text.line.first.and.arrowtriangle.forward")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(activePrimaryTextColor)
                    Spacer()
                    Text(String(format: "%.0f", effectiveLineSpacing))
                        .font(.caption.bold())
                        .foregroundStyle(activeSecondaryTextColor)
                }

                Slider(value: $readingLineSpacing, in: 4...12, step: 1)
                    .tint(activeAccentColor)
            }

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                    isImmersiveReadingEnabled = true
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                    Text("Tam ekran dikkat dağıtmayan mod")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.caption.bold())
                }
                .foregroundStyle(readingTheme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(readingTheme.accent.opacity(readingTheme == .dark ? 0.14 : 0.10))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(16)
        .background(readingCardBackground)
    }

    private func questionCard(_ question: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resmi Soru")
                .font(.caption.bold())
                .foregroundStyle(activeSecondaryTextColor)
                .tracking(0.8)
            Text(question)
                .font(.body)
                .foregroundStyle(activePrimaryTextColor)
        }
        .padding(16)
        .background(readingModeCardBackground)
    }

    private var officialTextCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isImmersiveReadingEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    Text(record.type.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(activeAccentColor)
                        .tracking(0.8)
                    Text(record.displayTitle)
                        .font(.system(size: 22 * effectiveFontScale, weight: .bold, design: .serif))
                        .foregroundStyle(activePrimaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 4)
            }

            Label("Resmi Metin", systemImage: "doc.text.fill")
                .font(.headline)
                .foregroundStyle(activePrimaryTextColor)

            Text(record.officialBodyText)
                .font(effectiveBodyFont)
                .foregroundStyle(activePrimaryTextColor)
                .lineSpacing(effectiveLineSpacing)
                .textSelection(.enabled)
        }
        .padding(isReadingModeEnabled ? 22 : 16)
        .background(
            Group {
                if isReadingModeEnabled || isImmersiveReadingEnabled {
                    RoundedRectangle(cornerRadius: isImmersiveReadingEnabled ? 28 : 24, style: .continuous)
                        .fill(readingTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: isImmersiveReadingEnabled ? 28 : 24, style: .continuous)
                                .stroke(readingTheme.border, lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(theme.elevatedBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(theme.accent.opacity(0.18), lineWidth: 1)
                        )
                }
            }
        )
        .overlay(officialTextOverlay)
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Kaynak Bağlantısı")
                .font(.headline)
                .foregroundStyle(activePrimaryTextColor)

            Text(showFullSourceURL ? record.sourceURL : record.sourceHostLabel)
                .font(.caption)
                .foregroundStyle(activeSecondaryTextColor)
                .textSelection(.enabled)

            HStack(spacing: 10) {
                Button {
                    showFullSourceURL.toggle()
                } label: {
                    Label(showFullSourceURL ? "Kısa göster" : "Tam URL göster", systemImage: "text.justify")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderless)

                Button {
                    showSharePreview = true
                } label: {
                    Label("Paylaş", systemImage: "square.and.arrow.up")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderless)

                if let url = URL(string: record.sourceURL) {
                    Link(destination: url) {
                        Label("Resmi kaynağı aç", systemImage: "link")
                            .font(.caption.bold())
                    }
                }
            }
            .foregroundStyle(activeAccentColor)
        }
        .padding(16)
        .background(standardCardBackground)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(activeSecondaryTextColor)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(activePrimaryTextColor)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var officialTextOverlay: some View {
        RoundedRectangle(cornerRadius: isImmersiveReadingEnabled ? 28 : (isReadingModeEnabled ? 24 : 18))
            .strokeBorder((isReadingModeEnabled ? readingTheme.border : theme.accent.opacity(0.18)), lineWidth: 1)
    }

    private func dailyStyleChip(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(systemColorScheme == .dark ? .white : Color(red: 0.12, green: 0.16, blue: 0.18))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tint.opacity(systemColorScheme == .dark ? 0.24 : 0.14))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(tint.opacity(systemColorScheme == .dark ? 0.30 : 0.18), lineWidth: 1)
            )
    }

    private var immersiveControlsBar: some View {
        ViewThatFits(in: .horizontal) {
            immersiveControlsRow(labelStyle: .full)
            immersiveControlsRow(labelStyle: .compact)
            immersiveControlsRow(labelStyle: .iconOnly)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            Capsule(style: .continuous)
                .fill(readingTheme.cardBackground.opacity(readingTheme == .dark ? 0.94 : 0.96))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(readingTheme.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(readingTheme == .dark ? 0.22 : 0.10), radius: 16, y: 8)
        )
    }

    private func immersiveControlsRow(labelStyle: ImmersiveButtonLabelStyle) -> some View {
        HStack(spacing: 8) {
            immersiveControlButton(systemImage: "xmark", title: "Çık", style: labelStyle) {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.88)) {
                    isImmersiveReadingEnabled = false
                }
            }

            immersiveControlButton(systemImage: "textformat.size.smaller", title: "A-", style: labelStyle) {
                readingFontScale = max(0.9, readingFontScale - 0.05)
            }

            immersiveControlButton(systemImage: "textformat.size.larger", title: "A+", style: labelStyle) {
                readingFontScale = min(1.45, readingFontScale + 0.05)
            }

            immersiveControlButton(
                systemImage: "paintpalette.fill",
                title: labelStyle == .full ? readingTheme.displayName : "Tema",
                style: labelStyle
            ) {
                cycleReadingTheme()
            }

            immersiveControlButton(systemImage: "square.and.arrow.up", title: "Paylaş", style: labelStyle) {
                showSharePreview = true
            }
        }
    }

    private func immersiveControlButton(
        systemImage: String,
        title: String,
        style: ImmersiveButtonLabelStyle,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: style == .iconOnly ? 0 : 6) {
                Image(systemName: systemImage)
                    .font(.caption.bold())
                if style != .iconOnly {
                    Text(title)
                        .font(.caption.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.86)
                }
            }
            .foregroundStyle(activePrimaryTextColor)
            .frame(minWidth: style == .iconOnly ? 36 : nil)
            .padding(.horizontal, style == .iconOnly ? 10 : 12)
            .padding(.vertical, 10)
            .background(readingTheme.accent.opacity(readingTheme == .dark ? 0.14 : 0.10))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var headerCardBackground: some View {
        Group {
            if isReadingModeEnabled {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(readingTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(readingTheme.border, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(readingTheme == .dark ? 0.14 : 0.08), radius: 14, y: 8)
            } else {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(theme.elevatedBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(theme.divider.opacity(0.7), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 16, y: 10)
            }
        }
    }

    private var standardCardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(isReadingModeEnabled ? readingTheme.cardBackground : theme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isReadingModeEnabled ? readingTheme.border : theme.divider.opacity(0.7), lineWidth: 1)
            )
    }

    private var readingCardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(readingTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(readingTheme.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(readingTheme == .dark ? 0.14 : 0.08), radius: 12, y: 6)
    }

    private var readingModeCardBackground: some View {
        Group {
            if isReadingModeEnabled {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(readingTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(readingTheme.border, lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(theme.divider.opacity(0.7), lineWidth: 1)
                    )
            }
        }
    }

    private func readingThemeChipBackground(_ option: DiyanetReadingTheme) -> Color {
        if readingTheme == option {
            return option.accent.opacity(option == .dark ? 0.22 : 0.16)
        }
        return option.cardBackground
    }

    private func readingThemeChipForeground(_ option: DiyanetReadingTheme) -> Color {
        option == .dark ? .white : option.primaryText
    }

    private func cycleReadingTheme() {
        let themes = DiyanetReadingTheme.allCases
        guard let index = themes.firstIndex(of: readingTheme) else {
            readingTheme = .plain
            return
        }

        let nextIndex = themes.index(after: index)
        readingTheme = nextIndex == themes.endIndex ? themes[0] : themes[nextIndex]
    }

    private func makeShareCardType() -> ShareCardType {
        .diyanet(
            DiyanetShareCardContent(
                title: record.displayTitle,
                typeText: record.type.displayName,
                categoryText: categoryText,
                summaryTitle: "Kısa Özet",
                summaryText: record.shareSummaryText,
                sourceTitle: "Kaynak",
                sourceSubtitle: record.sourceName,
                fullBodyText: record.officialBodyText,
                ctaText: "Devamı uygulamada",
                brandingTitle: AppName.full,
                brandingSubtitle: ShareCardBranding.storeSubtitle
            )
        )
    }

    private var categoryText: String {
        let value = record.categoryPath.joined(separator: " • ").trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "Resmi Diyanet İçeriği" : value
    }
}

private enum ImmersiveButtonLabelStyle {
    case full
    case compact
    case iconOnly
}
