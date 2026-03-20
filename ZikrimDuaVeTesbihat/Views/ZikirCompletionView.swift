import SwiftUI

struct ZikirCompletionView: View {
    let counter: CounterModel
    let session: ZikrSession?
    let todayCount: Int
    let streak: Int
    let onGoHome: () -> Void
    let onDismiss: () -> Void

    @State private var animateContent: Bool = false

    private var titleText: String {
        session?.zikrTitle ?? counter.name
    }

    private var completionSubtitle: String? {
        if let meaning = session?.meaning.trimmedNilIfEmpty {
            return meaning
        }
        if let transliteration = session?.transliteration.trimmedNilIfEmpty,
           transliteration != titleText {
            return transliteration
        }
        return nil
    }

    private var completionDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: RabiaAppLanguage.currentCode())
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            SharePreviewScreen(
                cardType: .dhikr(makeShareContent()),
                initialTheme: .night,
                showsThemePicker: true,
                backgroundColor: Color(.systemGroupedBackground)
            ) {
                homeButton
            }
            .opacity(animateContent ? 1 : 0)

            Button(action: onDismiss) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.26))
                        .frame(width: 38, height: 38)

                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(24)
            .opacity(animateContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.45, bounce: 0.2)) {
                animateContent = true
            }
        }
    }

    private var homeButton: some View {
        Button(action: onGoHome) {
            Label(.anaSayfayaDon, systemImage: "house.fill")
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemBackground).opacity(0.96))
                .foregroundStyle(.primary)
                .clipShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func makeShareContent() -> DhikrShareCardContent {
        DhikrShareCardContent(
            completedLabel: L10n.string(.tamamlandi),
            arabicText: session?.arabicText.trimmedNilIfEmpty,
            title: titleText,
            translationText: completionSubtitle,
            stats: [
                ShareMetric(value: "\(counter.targetCount)", label: L10n.string(.dhikrCompletionRepeatLabel), icon: "number.circle.fill"),
                ShareMetric(value: "\(todayCount)", label: L10n.string(.dhikrCompletionTodayLabel), icon: "sun.max.fill"),
                ShareMetric(value: "\(streak)", label: L10n.string(.dhikrCompletionStreakLabel), icon: "flame.fill")
            ],
            dateText: completionDateText,
            brandingTitle: AppName.full,
            brandingSubtitle: ShareCardBranding.storeSubtitle
        )
    }
}

private extension String {
    var trimmedNilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
