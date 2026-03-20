import SwiftUI

struct PrayerQadaCenterView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let storage: StorageService
    let context: PrayerQadaCenterContext

    @State private var yearsInput: String
    @State private var calculationPreview: QadaCalculationPreview?

    init(storage: StorageService, context: PrayerQadaCenterContext = .general) {
        self.storage = storage
        self.context = context
        _yearsInput = State(initialValue: storage.qadaCalculationPlan.map { String($0.yearsNotPrayed) } ?? "")
    }

    private var theme: ActiveTheme { themeManager.current }
    private var tokens: PrayerTimesThemeTokens { theme.prayerTimesTokens }
    private var trackers: [QadaTracker] {
        PrayerName.obligatoryCases.compactMap { storage.allQadaTrackers()[$0] }
    }
    private var suggestedPrayers: [PrayerName] {
        if !context.suggestedPrayers.isEmpty {
            let pending = storage.pendingQadaSuggestions(on: sourceDate ?? Date())
            return context.suggestedPrayers.filter { pending.contains($0) }
        }
        return storage.pendingQadaSuggestions()
    }
    private var totalOutstanding: Int {
        trackers.reduce(0) { $0 + $1.outstandingCount }
    }
    private var totalCompleted: Int {
        trackers.reduce(0) { $0 + $1.completedQadaCount }
    }
    private var suggestionsTitle: String {
        if let sourceDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: RabiaAppLanguage.currentCode())
            formatter.setLocalizedDateFormatFromTemplate("d MMMM")
            return "\(formatter.string(from: sourceDate)) eksikleri"
        }
        return "Bugünkü eksikler"
    }
    private var suggestionsDescription: String {
        if let sourceDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: RabiaAppLanguage.currentCode())
            formatter.setLocalizedDateFormatFromTemplate("d MMM")
            return "\(formatter.string(from: sourceDate)) günü işaretlenmeyen vakitleri dilersen tek dokunuşla kaza takibine ekleyebilirsin."
        }
        return "İstersen bugün işaretlenen eksik vakitleri tek dokunuşla kaza takibine ekleyebilirsin."
    }
    private var sourceDate: Date? {
        context.sourceDate
    }
    private var parsedYearsInput: Int? {
        let trimmed = yearsInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Int(trimmed)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                summaryCard
                if !suggestedPrayers.isEmpty {
                    suggestionsCard
                }
                calculatorCard
                countersCard
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
        }
        .background(
            PrayerScreenBackground(
                theme: theme,
                tokens: tokens
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Kaza namazları")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: yearsInput) { _, _ in
            calculationPreview = nil
        }
    }

    private var summaryCard: some View {
        PrayerSurfaceCard(theme: theme, tokens: tokens) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Kaza merkezi")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.textPrimary)

                Text("Toplam \(totalOutstanding) kaza")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.textPrimary)

                Text(totalCompleted > 0 ? "\(totalCompleted) kaza işlendi" : "Kaza namazlarının ayrı vakti yoktur; müsait olduğunda kılıp buradan kaydedebilirsin.")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let plan = storage.qadaCalculationPlan {
                    Text("Mevcut hesap: \(plan.yearsNotPrayed) yıl için her farz vakte yaklaşık \(plan.estimatedCountPerPrayer) kayıt")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var suggestionsCard: some View {
        PrayerSurfaceCard(theme: theme, tokens: tokens, padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text(suggestionsTitle)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.textPrimary)

                Text(suggestionsDescription)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(suggestedPrayers, id: \.self) { prayer in
                            Button {
                                withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                                    storage.addMissedPrayerToQada(prayer, on: sourceDate ?? Date())
                                }
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            } label: {
                                HStack(spacing: 8) {
                                    PrayerIconView(assetName: prayer.systemImage, size: 18)
                                    Text("\(prayer.qadaDisplayName) ekle")
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(theme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(theme.cardBackground.opacity(theme.isDarkMode ? 0.82 : 0.96), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var calculatorCard: some View {
        PrayerSurfaceCard(theme: theme, tokens: tokens) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Kaza hesaplama")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.textPrimary)

                Text("Kaç yıl düzenli namaz kılamadığını gir. Uygulama her farz vakit için yaklaşık bir başlangıç hesabı oluştursun.")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    TextField("Yıl", text: $yearsInput)
                        .keyboardType(.numberPad)
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(theme.textPrimary)
                        .padding(.horizontal, 14)
                        .frame(height: 46)
                        .background(theme.selectionBackground.opacity(theme.isDarkMode ? 0.54 : 0.84), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button(action: applyCalculation) {
                        Text("Hesapla")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.textPrimary)
                            .padding(.horizontal, 16)
                            .frame(height: 46)
                            .background(theme.cardBackground.opacity(theme.isDarkMode ? 0.86 : 0.98), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                if let calculationPreview {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hesap sonucu")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(theme.textSecondary)

                                Text("Toplam \(calculationPreview.totalOutstanding) kaza")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .foregroundStyle(theme.textPrimary)
                                    .contentTransition(.numericText())
                            }

                            Spacer(minLength: 0)

                            Button(action: saveCalculation) {
                                Text("Kaydet")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(theme.textPrimary)
                                    .padding(.horizontal, 14)
                                    .frame(height: 40)
                                    .background(theme.cardBackground.opacity(theme.isDarkMode ? 0.86 : 0.98), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }

                        Text(
                            calculationPreview.isReset
                            ? "Kaydedersen mevcut hesap temizlenir ve kalan kaza sayıları sıfırlanır."
                            : "\(calculationPreview.yearsNotPrayed) yıl için her farz vakte yaklaşık \(calculationPreview.estimatedCountPerPrayer) kaza kaydı hazırlanacak."
                        )
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(theme.selectionBackground.opacity(theme.isDarkMode ? 0.50 : 0.84), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else if let plan = storage.qadaCalculationPlan {
                    Text("\(plan.yearsNotPrayed) yıl için her farz vakte yaklaşık \(plan.estimatedCountPerPrayer) kaza kaydı uygulandı.")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var countersCard: some View {
        PrayerSurfaceCard(theme: theme, tokens: tokens) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Vakit bazında takip")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.textPrimary)

                VStack(spacing: 12) {
                    ForEach(trackers) { tracker in
                        PrayerQadaCenterRow(
                            tracker: tracker,
                            onIncrement: { storage.incrementQada(for: tracker.prayerType) },
                            onDecrement: { storage.decrementQada(for: tracker.prayerType) },
                            onComplete: { storage.completeQada(for: tracker.prayerType) }
                        )
                    }
                }
            }
        }
    }

    private func applyCalculation() {
        guard let years = parsedYearsInput else {
            calculationPreview = nil
            return
        }

        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
            calculationPreview = StorageService.previewQadaCalculation(
                yearsNotPrayed: years,
                existingTrackers: storage.allQadaTrackers()
            )
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func saveCalculation() {
        guard let calculationPreview else { return }

        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
            storage.applyQadaCalculation(yearsNotPrayed: calculationPreview.yearsNotPrayed)
            self.calculationPreview = nil
            yearsInput = storage.qadaCalculationPlan.map { String($0.yearsNotPrayed) } ?? ""
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}

private struct PrayerQadaCenterRow: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let tracker: QadaTracker
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onComplete: () -> Void

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(tracker.prayerType.qadaDisplayName)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.textPrimary)

                Spacer(minLength: 0)

                Text("\(tracker.outstandingCount)")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.textPrimary)
                    .contentTransition(.numericText())
            }

            HStack(spacing: 10) {
                qadaButton(icon: "minus", action: onDecrement)
                qadaButton(icon: "plus", action: onIncrement)

                Spacer(minLength: 0)

                Button(action: onComplete) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                        Text("Kılındı")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(tracker.outstandingCount > 0 ? theme.textPrimary : theme.textSecondary)
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(theme.selectionBackground.opacity(theme.isDarkMode ? 0.58 : 0.84), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(tracker.outstandingCount == 0)
            }

            if tracker.completedQadaCount > 0 {
                Text("\(tracker.completedQadaCount) kaza işlendi")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .padding(14)
        .background(theme.cardBackground.opacity(theme.isDarkMode ? 0.76 : 0.96), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(theme.border.opacity(theme.isDarkMode ? 0.26 : 0.40), lineWidth: 1)
        )
    }

    private func qadaButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.textPrimary)
                .frame(width: 40, height: 40)
                .background(theme.selectionBackground.opacity(theme.isDarkMode ? 0.58 : 0.84), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
